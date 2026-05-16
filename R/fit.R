#' Fit an initial lasso model and select lambda
#'
#' Builds the design matrix, runs (repeated) cross-validation to select lambda,
#' fits the final model via the spec's engine, and estimates the residual
#' standard error. The result is stored in an `lb_fit` object and passed to
#' [lb_bootstrap()].
#'
#' @param spec An `lb_spec` object from [lb_spec()].
#'
#' @return An `lb_fit` object containing the parent `lb_spec`, engine fit
#'   object, selected lambda scalar, lambda path vector, CV results, and
#'   residual sigma estimate(s).
#' @export
lb_fit <- function(spec) {
  stop("Not yet implemented", call. = FALSE)
}
