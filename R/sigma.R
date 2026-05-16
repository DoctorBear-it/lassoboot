# Internal: estimate residual standard error using the specified method.
#
# "refit" (default): refit OLS on lasso-selected variables; use that model's
#   residual SE. Largely closes the under-coverage gap caused by lasso's
#   residual shrinkage. Adds one lm() call per fit.
# "naive": sd(y - fitted_lasso). Matches the prototype; biased low under
#   regularization because lasso shrinks residuals along with coefficients.
# "cv": accumulated out-of-fold CV residuals. Most honest but slow.
.estimate_sigma <- function(fit, x, y, method = c("refit", "naive", "cv"), ...) {
  stop("Not yet implemented", call. = FALSE)
}
