#' Tidy bootstrap coefficients into a one-row-per-term tibble
#'
#' @description
#' Summarises the bootstrap distribution of the fitted-model coefficient for
#' each predictor. **These are not estimates of underlying parameters** and the
#' quantile columns are not confidence intervals in the frequentist coverage
#' sense. The bootstrap distribution describes how each coefficient varies across
#' data realizations consistent with the declared measurement uncertainty.
#'
#' @section Column descriptions:
#' - `mean`, `median`, `sd`: central tendency and spread of the bootstrap
#'   coefficient distribution. Iterations where the predictor was not selected
#'   contribute a coefficient of zero to these summaries.
#' - `q025`, `q975` (and other user-specified quantile columns): empirical
#'   quantiles of the bootstrap coefficient distribution, named `q` followed by
#'   the probability × 1000 zero-padded to 3 digits.
#' - `selection_prob`: the fraction of bootstrap replicates in which this
#'   predictor was retained by the LASSO under measurement-uncertainty
#'   perturbation. **This is the primary inferential output.**
#' - `n_selected`: count of replicates in which the predictor was selected.
#' - `stability_score`: maximum selection probability along the LASSO
#'   regularization path.
#'
#' @param x An `lb_boot` object.
#' @param probs Numeric vector of quantile probabilities to report. Column names
#'   are `q` followed by `round(p * 1000)`, zero-padded to 3 digits
#'   (e.g. `probs = c(0.025, 0.975)` → columns `q025` and `q975`).
#'   Default `c(0.025, 0.975)`.
#' @param scale `"raw"` (default, original units) or `"gelman"` (2-SD scaling
#'   per Gelman 2008, placing all numeric predictors on a comparable axis).
#' @param ... Unused; for S3 compatibility.
#'
#' @return A tibble with columns `term`, `mean`, `median`, `sd`,
#'   one column per element of `probs` (`q025`, `q975`, etc.),
#'   `selection_prob`, `n_selected`, `stability_score`.
#'   `(Intercept)` is dropped.
#'
#' @note
#' The quantile columns (`q025`, `q975`) are **not** classical confidence
#' intervals on the true parameter value. They are empirical quantiles of the
#' bootstrap coefficient distribution, zeros padded for unselected iterations.
#' Use `selection_prob` and `stability_score` as the primary inferential
#' outputs; treat these quantile columns as supplementary indicators of
#' effect-size stability across data realizations.
#'
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' tidy(boot)
#' tidy(boot, probs = c(0.05, 0.95))
#' @export
tidy.lb_boot <- function(x,
                          probs = c(0.025, 0.975),
                          scale = c("raw", "gelman"),
                          ...) {
  scale <- match.arg(scale)

  if (!is.numeric(probs) || length(probs) == 0L ||
        any(probs <= 0) || any(probs >= 1)) {
    cli::cli_abort("{.arg probs} must be a numeric vector of values in (0, 1).")
  }

  B         <- x$B
  coef_tbl  <- x$coef_tbl
  all_terms <- colnames(x$fit$x)   # design-matrix columns, no intercept

  # Quantile column names: "q" + probability × 1000 zero-padded to 3 digits
  q_names <- paste0("q", formatC(round(probs * 1000), width = 3L,
                                   flag = "0", format = "d"))

  result <- dplyr::bind_rows(lapply(all_terms, function(tm) {
    vals  <- coef_tbl$estimate[coef_tbl$term == tm]
    n_sel <- length(vals)
    # Full B-length vector: fill zeros for iterations where term was not selected
    full_vals <- c(vals, rep(0.0, B - n_sel))
    qs        <- as.list(stats::quantile(full_vals, probs = probs))
    names(qs) <- q_names

    row <- tibble::tibble(
      term           = tm,
      mean           = mean(full_vals),
      median         = stats::median(full_vals),
      sd             = stats::sd(full_vals),
      selection_prob = n_sel / B,
      n_selected     = n_sel
    )
    # Bind quantile columns
    dplyr::bind_cols(row, tibble::as_tibble(qs))
  }))

  # Stability scores: join max_selection_prob from lb_stability()
  stab        <- lb_stability(x)
  stab_sub    <- dplyr::select(stab, "term", "max_selection_prob")
  result      <- dplyr::left_join(result, stab_sub, by = "term")
  names(result)[names(result) == "max_selection_prob"] <- "stability_score"

  # Terms not in stab (e.g. never selected when store_path = FALSE) fall back
  # to selection_prob; for those terms selection_prob is already 0.
  na_stab <- is.na(result$stability_score)
  if (any(na_stab)) {
    result$stability_score[na_stab] <- result$selection_prob[na_stab]
  }

  # Reorder columns: term, mean, median, sd, q*, selection_prob, n_selected, stability_score
  col_order <- c("term", "mean", "median", "sd", q_names,
                 "selection_prob", "n_selected", "stability_score")
  result <- result[, col_order, drop = FALSE]

  if (scale == "gelman") {
    data <- x$fit$spec$data
    # Build a dummy coefficient vector of 1s, one per term, to extract scale
    # factors — .scale_gelman multiplies each entry by its 2*sd factor, so a
    # vector of 1s returns the bare factors.
    dummy_coefs   <- stats::setNames(rep(1.0, nrow(result)), result$term)
    scale_factors <- .scale_gelman(dummy_coefs, data)
    sf            <- unname(scale_factors[result$term])

    result$mean   <- result$mean   * sf
    result$median <- result$median * sf
    result$sd     <- result$sd     * sf
    for (qn in q_names) {
      result[[qn]] <- result[[qn]] * sf
    }
  }

  result
}

#' Model-level bootstrap summary
#'
#' @param x An `lb_boot` object.
#' @param ... Unused; for S3 compatibility.
#'
#' @return A one-row tibble: `n`, `B`, `lambda`, `lambda_mad`,
#'   `mean_n_selected`, `sd_n_selected`, `dev_ratio`, `elapsed_sec`,
#'   `sigma_method`, `fold_spec`.
#'   `lambda_mad` is `NA` when `fix_lambda = TRUE` (all iterations share the
#'   same lambda; the MAD would be zero and is uninformative).
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' glance(boot)
#' @export
glance.lb_boot <- function(x, ...) {
  B       <- x$B
  fit     <- x$fit
  control <- fit$spec$control

  # coef_tbl has one row per (iteration, term); tabulate gives count of
  # selected terms per iteration (n_selected count for each b = 1..B).
  n_sel_per_iter <- tabulate(x$coef_tbl$iteration, nbins = B)

  tibble::tibble(
    n               = length(fit$y),
    B               = B,
    lambda          = fit$lambda,
    lambda_mad      = NA_real_,   # reserved: only meaningful for fix_lambda=FALSE
    mean_n_selected = mean(n_sel_per_iter),
    sd_n_selected   = stats::sd(n_sel_per_iter),
    dev_ratio       = fit$fit_obj$dev.ratio[1L],
    elapsed_sec     = x$elapsed_sec,
    sigma_method    = control$sigma_method,
    fold_spec       = class(fit$spec$folds)[1L]
  )
}

#' Augment data with bootstrap fitted values and prediction intervals
#'
#' Returns the data (training or new) augmented with `.fitted`, `.lower`, and
#' `.upper` columns from the bootstrap coefficient distribution at `level`
#' confidence.
#'
#' @param x An `lb_boot` object.
#' @param newdata A data frame for out-of-sample augmentation, or `NULL` to
#'   use training data. Default `NULL`.
#' @param level Confidence level for the prediction interval. Default `0.95`.
#' @param ... Unused; for S3 compatibility.
#'
#' @return The (new)data tibble augmented with `.fitted`, `.lower`, `.upper`.
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' augment(boot)
#' @export
augment.lb_boot <- function(x, newdata = NULL, level = 0.95, ...) {
  preds <- predict.lb_boot(x,
    newdata  = newdata,
    type     = "response",
    interval = "confidence",
    level    = level
  )

  base_data <- if (is.null(newdata)) x$fit$spec$data else newdata
  dplyr::bind_cols(tibble::as_tibble(base_data), preds)
}
