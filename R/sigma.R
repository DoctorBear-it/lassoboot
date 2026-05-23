# Internal: estimate residual standard error using the specified method.
#
# "refit" (default): refit OLS on lasso-selected variables; use that model's
#   residual SE. More conservative than naive. Appropriate for prediction-band
#   work and adds only one lm() call per fit.
# "naive": sd(y - fitted_lasso). Measures scatter around the actual predictive
#   model — the correct choice if your primary output is prediction envelopes
#   rather than coefficient distributions.
# "cv": out-of-fold CV residuals accumulated via cv.glmnet(keep = TRUE).
#   Most honest but slow.
#
# The `lambda` argument is the scalar lambda at which coefficients/predictions
# should be evaluated. When NULL, falls back to fit_obj$lambda[1L].
.estimate_sigma <- function(fit_obj, x, y,
                             method      = c("refit", "naive", "cv"),
                             lambda      = NULL,
                             engine      = NULL,
                             foldid      = NULL,
                             intercept   = TRUE,
                             standardize = TRUE,
                             ...) {
  method <- match.arg(method)
  lam    <- lambda %||% fit_obj$lambda[1L]
  switch(method,
    refit = .sigma_refit(fit_obj, x, y, lam),
    naive = .sigma_naive(fit_obj, x, y, lam),
    cv    = .sigma_cv(fit_obj, x, y, foldid = foldid)
  )
}

.sigma_refit <- function(fit_obj, x, y, lambda) {
  cf     <- glmnet::coef.glmnet(fit_obj, s = lambda)
  cf_vec <- as.numeric(cf)
  # Skip intercept (index 1) when identifying selected predictors
  nonzero_idx <- which(cf_vec[-1L] != 0)

  if (length(nonzero_idx) == 0L) {
    cli::cli_warn(
      "No predictors selected; sigma estimated from null model (sd around mean)."
    )
    return(stats::sd(y - mean(y)))
  }

  X_sel <- as.matrix(x[, nonzero_idx, drop = FALSE])
  n     <- length(y)
  p_sel <- ncol(X_sel)
  df    <- n - p_sel - 1L

  if (df < 1L) {
    cli::cli_warn(
      c("OLS refit has {df} degree{?s} of freedom ({p_sel} predictors, {n} obs).",
        "i" = "Falling back to naive sigma.")
    )
    return(.sigma_naive(fit_obj, x, y, lambda))
  }

  lm_fit <- stats::lm.fit(cbind(1, X_sel), y)
  sqrt(sum(lm_fit$residuals^2) / df)
}

.sigma_naive <- function(fit_obj, x, y, lambda) {
  fitted_vals <- as.numeric(
    stats::predict(fit_obj, newx = x, s = lambda, type = "response")
  )
  stats::sd(y - fitted_vals)
}

.sigma_cv <- function(fit_obj, x, y, foldid = NULL) {
  if (is.null(foldid)) {
    n      <- length(y)
    foldid <- sample(rep_len(seq_len(10L), n))
  }
  lambda_target <- fit_obj$lambda[1L]
  # Run cv.glmnet with keep = TRUE to obtain per-fold (OOF) predictions
  cv_fit <- glmnet::cv.glmnet(
    x      = x,
    y      = y,
    alpha  = 1,
    foldid = foldid,
    keep   = TRUE
  )
  idx  <- which.min(abs(cv_fit$lambda - lambda_target))
  oofp <- as.numeric(cv_fit$fit.preval[, idx])
  stats::sd(y - oofp)
}
