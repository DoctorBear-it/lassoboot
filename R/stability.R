# Internal helper: build a (p x n_lambda) selection-probability matrix.
# Called only from lb_plot_stability() — lb_stability() has its own inline loop.
# Precondition: path_coefs is a non-NULL list of B dgCMatrix objects, each
# (p+1) x n_lambda with the intercept in row 1.
# Returns: named numeric matrix, rows = predictors (intercept stripped),
# cols = lambda grid points, values in [0, 1].
.path_sel_mat <- function(path_coefs, B) {
  first_mat  <- path_coefs[[1L]][-1L, , drop = FALSE]
  term_names <- rownames(first_mat)
  n_lambda   <- ncol(first_mat)
  sel_count  <- matrix(0L, nrow = length(term_names), ncol = n_lambda,
                       dimnames = list(term_names, NULL))
  for (b in seq_len(B)) {
    pm        <- path_coefs[[b]][-1L, , drop = FALSE]
    sel_count <- sel_count + (as.matrix(pm) != 0)
  }
  sel_count / B
}

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
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_stability(boot)
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
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_correlated_pairs(boot)
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

#' Filter tidy bootstrap output on stability criteria
#'
#' A convenience predicate for use inside [dplyr::filter()]. Applies one or
#' more stability criteria to a tibble from [tidy.lb_boot()]. Unlike the
#' deprecated [lb_is_significant()], each criterion is an independent named
#' argument that can be combined in any combination.
#'
#' @param tidy_df A tibble from [tidy.lb_boot()].
#' @param min_selection_prob Minimum selection probability threshold. Rows with
#'   `selection_prob < min_selection_prob` are excluded. Default `NULL` (no
#'   filter on this criterion).
#' @param min_stability_score Minimum stability score threshold. Rows with
#'   `stability_score < min_stability_score` are excluded. Default `NULL` (no
#'   filter on this criterion).
#' @param quantiles_exclude_zero Logical. If `TRUE`, exclude rows where the
#'   default 95 % quantile interval (`q025` to `q975`) does not exclude zero
#'   (i.e. rows where `q025 <= 0` AND `q975 >= 0`). Default `FALSE`.
#'
#' @return A logical vector the same length as `nrow(tidy_df)`.
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 20)
#' td <- tidy(boot)
#' # Keep only terms selected in the majority of replicates
#' td[lb_filter_stable(td, min_selection_prob = 0.5), ]
#' # Combine criteria
#' td[lb_filter_stable(td, min_selection_prob = 0.5, min_stability_score = 0.4), ]
#' @export
lb_filter_stable <- function(tidy_df,
                              min_selection_prob   = NULL,
                              min_stability_score  = NULL,
                              quantiles_exclude_zero = FALSE) {
  keep <- rep(TRUE, nrow(tidy_df))

  if (!is.null(min_selection_prob)) {
    keep <- keep & (tidy_df$selection_prob >= min_selection_prob)
  }
  if (!is.null(min_stability_score)) {
    keep <- keep & (tidy_df$stability_score >= min_stability_score)
  }
  if (isTRUE(quantiles_exclude_zero)) {
    # Look for q025/q975 columns; fall back to first q* columns found
    lo_col <- if ("q025" %in% names(tidy_df)) "q025" else
      names(tidy_df)[grepl("^q0", names(tidy_df))][1L]
    hi_col <- if ("q975" %in% names(tidy_df)) "q975" else
      names(tidy_df)[grepl("^q9", names(tidy_df))][1L]
    if (!is.na(lo_col) && !is.na(hi_col)) {
      keep <- keep & (tidy_df[[lo_col]] > 0 | tidy_df[[hi_col]] < 0)
    }
  }

  keep
}

#' Test whether terms meet a significance criterion (deprecated)
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' Deprecated in favour of [lb_filter_stable()], which uses more precise
#' language and a more flexible argument structure. `lb_is_significant()` still
#' works but emits a one-time warning per session.
#'
#' @param tidy_df A tibble from [tidy.lb_boot()].
#' @param method One of `"ci"`, `"selection"`, `"stability"`, or `"all"`.
#' @param threshold Probability threshold for `"selection"` and `"stability"`
#'   methods. Default `0.5`.
#'
#' @return A logical vector the same length as `nrow(tidy_df)`.
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 20)
#' td <- tidy(boot)
#' suppressWarnings(lb_is_significant(td, method = "selection", threshold = 0.5))
#' @export
lb_is_significant <- function(tidy_df,
                               method = c("ci", "selection", "stability", "all"),
                               threshold = 0.5) {
  .warn_once(
    "lb_is_significant_deprecated",
    c("{.fn lb_is_significant} is deprecated.",
      "i" = "Use {.fn lb_filter_stable} with named arguments instead:",
      "i" = "{.code lb_filter_stable(td, min_selection_prob = 0.5)}",
      "i" = "{.code lb_filter_stable(td, min_stability_score = 0.8)}",
      "i" = "{.code lb_filter_stable(td, quantiles_exclude_zero = TRUE)}")
  )
  method <- match.arg(method)

  # Map old-style column names: support both v0.1 (conf.low/conf.high) and
  # v0.2.0 (q025/q975) column names.
  q_excludes_zero <- function() {
    if ("q025" %in% names(tidy_df) && "q975" %in% names(tidy_df)) {
      tidy_df$q025 > 0 | tidy_df$q975 < 0
    } else if ("conf.low" %in% names(tidy_df) && "conf.high" %in% names(tidy_df)) {
      tidy_df$conf.low > 0 | tidy_df$conf.high < 0
    } else {
      cli::cli_abort(
        "Cannot apply {.code method = \"ci\"}: no quantile columns found in
         {.arg tidy_df}. Run {.fn tidy} with default {.arg probs}."
      )
    }
  }

  switch(method,
    ci        = q_excludes_zero(),
    selection = tidy_df$selection_prob >= threshold,
    stability = tidy_df$stability_score >= threshold,
    all       = q_excludes_zero() &
                  tidy_df$selection_prob >= threshold &
                  tidy_df$stability_score >= threshold
  )
}
