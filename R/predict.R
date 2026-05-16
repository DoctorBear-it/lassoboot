#' Predict from a bootstrap lasso fit
#'
#' Reconstructs predictions from the stored coefficient matrix via direct
#' matrix multiplication (exact for Gaussian linear glmnet; the default fast
#' path). Does not require `keep_models = TRUE` for standard prediction.
#' The internal pipeline is matrix-based: no `nest()`/`unnest()` in the hot
#' path; summaries computed via `matrixStats::rowQuantiles`.
#'
#' @param object An `lb_boot` object.
#' @param newdata A data frame for out-of-sample prediction, or `NULL` to
#'   predict on training data. Default `NULL`.
#' @param type `"response"` (default) or `"coef"`.
#' @param interval `"none"` (default) or `"confidence"`.
#' @param level Confidence level. Default `0.95`.
#' @param B_sub Subsample this many bootstrap iterations for speed, or `NULL`
#'   to use all. Default `NULL`.
#' @param ... Unused; for S3 compatibility.
#'
#' @return A tibble with `.fitted` and, if `interval = "confidence"`, `.lower`
#'   and `.upper`.
#' @export
predict.lb_boot <- function(object, newdata = NULL,
                             type = c("response", "coef"),
                             interval = c("none", "confidence"),
                             level = 0.95,
                             B_sub = NULL, ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Build a prediction grid varying a focal predictor
#'
#' Constructs a grid of `n` values along the focal predictor's range, crossed
#' with non-focal predictors fixed at their observed combinations (default),
#' medians, or user-supplied values. Passes the grid to [predict.lb_boot()] and
#' returns `.fitted`, `.lower`, `.upper`.
#'
#' @param boot An `lb_boot` object.
#' @param focal Name of the focal (x-axis) predictor (string).
#' @param n Number of grid points along the focal axis. Default `100`.
#' @param at How to set non-focal predictors: `"observed"` (default — all
#'   unique observed combinations), `"median"`, or a named list of values.
#' @param extrapolate Logical. Allow grid points outside the observed focal
#'   range for each non-focal combination? User must opt in. Default `FALSE`.
#'
#' @return A tibble with the grid columns plus `.fitted`, `.lower`, `.upper`.
#' @export
lb_grid <- function(boot, focal, n = 100, at = "observed", extrapolate = FALSE) {
  stop("Not yet implemented", call. = FALSE)
}
