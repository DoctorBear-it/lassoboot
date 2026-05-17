#' Compute stability-selection summaries for bootstrap output
#'
#' Summarises each term's selection probability trajectory across the lambda
#' path: the maximum selection probability, the lambda value at which that
#' maximum is achieved, the lambda range over which selection probability
#' exceeds 0.5, and the count of lambda values above that threshold.
#'
#' When `store_path = FALSE` was used in `lb_control()`, `path_coefs` is not
#' available and `stability_score` falls back to the point-lambda selection
#' probability (same as `selection_prob` in [tidy.lb_boot()]).
#'
#' @param boot An `lb_boot` object.
#'
#' @return A tibble with one row per non-intercept term:
#'   - `term`: predictor name.
#'   - `max_selection_prob`: maximum selection probability across all lambda
#'     values in the stored path.
#'   - `lambda_at_max`: the lambda value where `max_selection_prob` is achieved.
#'   - `lambda_range_low`: smallest lambda value at which selection probability
#'     exceeds 0.5, or `NA` if the term never reaches 0.5.
#'   - `lambda_range_high`: largest lambda value at which selection probability
#'     exceeds 0.5, or `NA` if the term never reaches 0.5.
#'   - `n_lambda_above_half`: number of lambda grid points at which selection
#'     probability exceeds 0.5.
#' @export
lb_stability <- function(boot) {
  if (!inherits(boot, "lb_boot")) {
    cli::cli_abort("{.arg boot} must be an {.cls lb_boot} object.")
  }

  B           <- boot$B
  path_coefs  <- boot$path_coefs
  lambda_path <- boot$fit$lambda_path

  if (is.null(path_coefs)) {
    # Path not stored: stability_score = selection_prob; compute from coef_tbl.
    term_names <- setdiff(
      unique(boot$coef_tbl$term),
      "(Intercept)"
    )
    # Use seq_along to avoid vapply naming the result with term_names, which
    # would bleed names into the tibble column and cause test failures.
    sel_prob <- vapply(seq_along(term_names), function(i) {
      sum(boot$coef_tbl$term == term_names[i]) / B
    }, numeric(1L))
    return(tibble::tibble(
      term                = term_names,
      max_selection_prob  = sel_prob,
      lambda_at_max       = NA_real_,
      lambda_range_low    = NA_real_,
      lambda_range_high   = NA_real_,
      n_lambda_above_half = NA_integer_
    ))
  }

  # path_coefs[[b]] is a (p+1) x n_lambda dgCMatrix, intercept row first.
  # Drop intercept row (row 1) before aggregating.
  # Accumulate a p x n_lambda selection-count matrix across all B iterations.
  first_mat  <- path_coefs[[1L]][-1L, , drop = FALSE]
  term_names <- rownames(first_mat)
  n_lambda   <- ncol(first_mat)
  sel_count  <- matrix(0L, nrow = length(term_names), ncol = n_lambda,
                       dimnames = list(term_names, NULL))

  for (b in seq_len(B)) {
    pm <- path_coefs[[b]][-1L, , drop = FALSE]   # p x n_lambda
    # A coefficient is "selected" if it is nonzero at that lambda.
    # pm is sparse; as.matrix() is needed for arithmetic but only once per iter.
    sel_count <- sel_count + (as.matrix(pm) != 0)
  }

  sel_prob_mat <- sel_count / B   # p x n_lambda, values in [0, 1]

  # Summarise per term
  tibble::tibble(
    term = term_names,
    max_selection_prob = matrixStats::rowMaxs(sel_prob_mat),
    lambda_at_max = vapply(seq_along(term_names), function(i) {
      idx <- which.max(sel_prob_mat[i, ])
      if (length(idx) == 0L || !is.finite(lambda_path[idx])) NA_real_
      else lambda_path[idx]
    }, numeric(1L)),
    lambda_range_low = vapply(seq_along(term_names), function(i) {
      above <- which(sel_prob_mat[i, ] > 0.5)
      if (length(above) == 0L) NA_real_ else lambda_path[min(above)]
    }, numeric(1L)),
    lambda_range_high = vapply(seq_along(term_names), function(i) {
      above <- which(sel_prob_mat[i, ] > 0.5)
      if (length(above) == 0L) NA_real_ else lambda_path[max(above)]
    }, numeric(1L)),
    n_lambda_above_half = as.integer(matrixStats::rowSums2(sel_prob_mat > 0.5))
  )
}

#' Identify correlated predictor pairs with split selection probabilities
#'
#' Detects the "lasso picked one of two correlated predictors at random"
#' pathology. Flags pairs where `cor > cor_threshold` in the original data and
#' the individual selection probabilities are split (neither clearly dominant)
#' while the joint either-one probability is high.
#'
#' @param boot An `lb_boot` object.
#' @param cor_threshold Correlation threshold above which pairs are examined.
#'   Default `0.7`.
#' @param prob_threshold Individual selection probability threshold below which
#'   a term is considered "split". Default `0.5`.
#'
#' @return A tibble of flagged pairs with columns `term_1`, `term_2`,
#'   `correlation`, `prob_1`, `prob_2`, `prob_either`.
#' @export
lb_correlated_pairs <- function(boot, cor_threshold = 0.7, prob_threshold = 0.5) {
  if (!inherits(boot, "lb_boot")) {
    cli::cli_abort("{.arg boot} must be an {.cls lb_boot} object.")
  }

  B  <- boot$B
  x  <- as.matrix(boot$fit$x)   # n x p — no intercept column in fit$x
  p  <- ncol(x)

  if (p < 2L) {
    return(tibble::tibble(
      term_1      = character(0),
      term_2      = character(0),
      correlation = numeric(0),
      prob_1      = numeric(0),
      prob_2      = numeric(0),
      prob_either = numeric(0)
    ))
  }

  term_names <- colnames(x)
  cor_mat    <- stats::cor(x)

  # Individual selection probabilities from coef_tbl
  tidy_df  <- tidy.lb_boot(boot)
  prob_map <- stats::setNames(tidy_df$selection_prob, tidy_df$term)

  # Find all pairs with |cor| > cor_threshold
  rows <- list()
  for (i in seq_len(p - 1L)) {
    for (j in seq(i + 1L, p)) {
      cr <- cor_mat[i, j]
      if (abs(cr) <= cor_threshold) next

      t1 <- term_names[i]
      t2 <- term_names[j]
      p1 <- prob_map[t1] %||% 0
      p2 <- prob_map[t2] %||% 0

      if (max(p1, p2) >= prob_threshold) next  # at least one clearly dominant

      # Compute joint "either selected" probability across iterations
      sel_1 <- boot$coef_tbl$iteration[boot$coef_tbl$term == t1]
      sel_2 <- boot$coef_tbl$iteration[boot$coef_tbl$term == t2]
      p_either <- length(union(sel_1, sel_2)) / B

      if (p_either <= prob_threshold) next  # joint probability also low

      rows[[length(rows) + 1L]] <- list(
        term_1      = t1,
        term_2      = t2,
        correlation = cr,
        prob_1      = as.numeric(p1),
        prob_2      = as.numeric(p2),
        prob_either = p_either
      )
    }
  }

  if (length(rows) == 0L) {
    return(tibble::tibble(
      term_1      = character(0),
      term_2      = character(0),
      correlation = numeric(0),
      prob_1      = numeric(0),
      prob_2      = numeric(0),
      prob_either = numeric(0)
    ))
  }

  dplyr::bind_rows(rows)
}

#' Test whether terms meet a significance criterion
#'
#' A convenience predicate for use in [dplyr::filter()]. Three complementary
#' criteria: bootstrap CI exclusion of zero (`"ci"`), selection probability
#' threshold (`"selection"`), stability score threshold (`"stability"`), or all
#' three simultaneously (`"all"`).
#'
#' @param tidy_df A tibble from [tidy.lb_boot()].
#' @param method One of `"ci"`, `"selection"`, `"stability"`, or `"all"`.
#' @param threshold Probability threshold for `"selection"` and `"stability"`
#'   methods. Default `0.5`.
#'
#' @return A logical vector the same length as `nrow(tidy_df)`.
#' @export
lb_is_significant <- function(tidy_df,
                               method = c("ci", "selection", "stability", "all"),
                               threshold = 0.5) {
  method <- match.arg(method)

  ci_sig <- function() tidy_df$conf.low > 0 | tidy_df$conf.high < 0

  switch(method,
    ci        = ci_sig(),
    selection = tidy_df$selection_prob >= threshold,
    stability = tidy_df$stability_score >= threshold,
    all       = ci_sig() &
                  tidy_df$selection_prob >= threshold &
                  tidy_df$stability_score >= threshold
  )
}
