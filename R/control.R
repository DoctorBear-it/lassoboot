#' Set tuning parameters for the bootstrap
#'
#' @param lambda Lambda selection method: `"repeated_cv"` (default), `"min"`,
#'   `"1se"`, or a positive numeric value.
#' @param cv_folds Number of CV folds. Default `10L`.
#' @param cv_reps Number of repeated-CV repetitions (used when
#'   `lambda = "repeated_cv"`). Default `5L`.
#' @param fix_lambda Logical. Reuse the initial lambda in every bootstrap
#'   iteration? Default `TRUE`.
#' @param store_path Logical. Store the full coefficient path per iteration,
#'   enabling stability diagnostics? Default `TRUE`.
#' @param n_lambda Number of lambda values in the stored path. Default `50L`.
#' @param keep_models Logical. Store the engine fit object for every iteration?
#'   Off by default; only needed for per-model diagnostics. Default `FALSE`.
#' @param sigma_method Residual SE estimation method: `"refit"` (default —
#'   OLS on selected variables, closes the under-coverage gap), `"naive"`
#'   (matches prototype, biased low), or `"cv"` (out-of-fold, slow but honest).
#' @param parallel Logical. Use `future`/`furrr` for parallelism? Errors
#'   helpfully if those packages are absent. Default `FALSE`.
#' @param progress Logical. Show a `cli`-style progress bar? Default
#'   `interactive()`.
#' @param seed Integer seed for reproducibility, or `NULL` for random. Applied
#'   via `withr::with_seed()`. Default `NULL`.
#' @param intercept Logical. Fit intercept? Passed to the engine. Default `TRUE`.
#' @param standardize Logical. Standardize predictors? Passed to the engine.
#'   Default `TRUE`.
#'
#' @return An `lb_control` object (a validated, classed list). The print method
#'   shows only non-default values.
#' @export
lb_control <- function(lambda = "repeated_cv",
                       cv_folds = 10L,
                       cv_reps = 5L,
                       fix_lambda = TRUE,
                       store_path = TRUE,
                       n_lambda = 50L,
                       keep_models = FALSE,
                       sigma_method = "refit",
                       parallel = FALSE,
                       progress = interactive(),
                       seed = NULL,
                       intercept = TRUE,
                       standardize = TRUE) {
  stop("Not yet implemented", call. = FALSE)
}

#' @export
print.lb_control <- function(x, ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' @export
format.lb_control <- function(x, ...) {
  stop("Not yet implemented", call. = FALSE)
}
