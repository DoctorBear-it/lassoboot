#' Tidy bootstrap coefficients into a one-row-per-term tibble
#'
#' @param x An `lb_boot` object.
#' @param conf.level Confidence level for the bootstrap quantile interval.
#'   Default `0.95`.
#' @param scale `"raw"` (default, original units) or `"gelman"` (2-SD scaling
#'   per Gelman 2008, placing all numeric predictors on a comparable axis).
#' @param ... Unused; for S3 compatibility.
#'
#' @return A tibble with columns: `term`, `estimate` (bootstrap mean over all
#'   B iterations, zeros included), `estimate_median`, `std.error`, `conf.low`,
#'   `conf.high`, `selection_prob`, `n_selected`, `stability_score`.
#' @export
tidy.lb_boot <- function(x, conf.level = 0.95,
                          scale = c("raw", "gelman"), ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Model-level bootstrap summary
#'
#' @param x An `lb_boot` object.
#' @param ... Unused; for S3 compatibility.
#'
#' @return A one-row tibble: `n`, `B`, `lambda`, `lambda_mad`,
#'   `mean_n_selected`, `sd_n_selected`, `dev_ratio`, `elapsed_sec`,
#'   `sigma_method`, `fold_spec`.
#' @export
glance.lb_boot <- function(x, ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Augment data with bootstrap fitted values and prediction intervals
#'
#' @param x An `lb_boot` object.
#' @param newdata A data frame for out-of-sample augmentation, or `NULL` to
#'   use training data. Default `NULL`.
#' @param ... Unused; for S3 compatibility.
#'
#' @return The (new)data tibble augmented with `.fitted`, `.lower`, `.upper`.
#' @export
augment.lb_boot <- function(x, newdata = NULL, ...) {
  stop("Not yet implemented", call. = FALSE)
}
