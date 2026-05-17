#' Fit an initial lasso model and select lambda
#'
#' Builds the design matrix, runs (repeated) cross-validation to select lambda,
#' fits the final model via the spec's engine, and estimates the residual
#' standard error. The result is stored in an `lb_fit` object and passed to
#' [lb_bootstrap()].
#'
#' @param spec An `lb_spec` object from [lb_spec()].
#'
#' @return An `lb_fit` object containing:
#'   - `spec`: the parent `lb_spec` (stored in full; `lb_fit` is self-contained).
#'   - `fit_obj`: the engine fit object at the selected lambda.
#'   - `lambda`: selected lambda scalar.
#'   - `lambda_path`: lambda grid from the last CV run (used in path storage
#'     during bootstrap; see `lb_control(store_path)`).
#'   - `cv_results`: reduced named list from `engine$cv()` —
#'     `lambda.min`, `lambda.1se`, `lambda_path`, `cvm`. Not a full
#'     `cv.glmnet` object; `glance()` in Phase 4 uses this for fold_spec output.
#'   - `sigma_hat`: residual SE scalar (method from `control$sigma_method`).
#'   - `x`: original sparse design matrix (n x p). Stored here so the bootstrap
#'     loop can reuse it for generating y_star without rebuilding from spec$data
#'     each iteration (O(n*p) allocation saved per iteration).
#'   - `y`: original response vector (length n). Companion to `x`.
#' @export
lb_fit <- function(spec) {
  if (!inherits(spec, "lb_spec")) {
    cli::cli_abort("{.arg spec} must be an {.cls lb_spec} from {.fn lb_spec}.")
  }

  control <- spec$control
  engine  <- spec$engine

  # Build design matrix and response vector
  dm <- .build_design_matrix(spec$formula, spec$data)
  x  <- dm$x
  y  <- dm$y

  # Generate fold IDs; warn if any fold is degenerate (carry-forward #2).
  # Warning fires once here, not once per CV repetition.
  foldid     <- spec$folds(spec$data)
  fold_sizes <- table(foldid)
  if (any(fold_sizes < 2L)) {
    cli::cli_warn(c(
      "{sum(fold_sizes < 2L)} fold{?s} contain{?s/} fewer than 2 observation{?s}.",
      "i" = "CV error estimates will be unstable. Consider reducing {.arg cv_folds}."
    ))
  }

  # Lambda selection
  lambda_method <- control$lambda
  if (is.numeric(lambda_method)) {
    lambda_scalar <- lambda_method
    # Run one CV to populate lambda_path for diagnostics (result not used for lambda)
    cv_result <- engine$cv(x, y, foldid = foldid,
                           nlambda     = control$n_lambda,
                           intercept   = control$intercept,
                           standardize = control$standardize)
  } else if (lambda_method == "repeated_cv") {
    lambdas <- numeric(control$cv_reps)
    for (i in seq_len(control$cv_reps)) {
      fid_i      <- spec$folds(spec$data)
      cv_i       <- engine$cv(x, y, foldid = fid_i,
                               nlambda     = control$n_lambda,
                               intercept   = control$intercept,
                               standardize = control$standardize)
      lambdas[i] <- cv_i$lambda.min
    }
    lambda_scalar <- stats::median(lambdas)
    cv_result     <- cv_i  # keep last CV run for lambda_path / cvm
  } else if (lambda_method == "min") {
    cv_result     <- engine$cv(x, y, foldid = foldid,
                               nlambda     = control$n_lambda,
                               intercept   = control$intercept,
                               standardize = control$standardize)
    lambda_scalar <- cv_result$lambda.min
  } else {  # "1se"
    cv_result     <- engine$cv(x, y, foldid = foldid,
                               nlambda     = control$n_lambda,
                               intercept   = control$intercept,
                               standardize = control$standardize)
    lambda_scalar <- cv_result$lambda.1se
  }

  # Final fit at the selected scalar lambda
  fit_obj <- engine$fit(x, y,
                        lambda      = lambda_scalar,
                        intercept   = control$intercept,
                        standardize = control$standardize)

  # Sigma estimation; foldid is threaded through for method = "cv"
  sigma_hat <- engine$sigma(fit_obj, x, y,
                             method = control$sigma_method,
                             foldid = foldid)

  structure(
    list(
      spec        = spec,
      fit_obj     = fit_obj,
      lambda      = lambda_scalar,
      lambda_path = cv_result$lambda_path,
      cv_results  = cv_result,
      sigma_hat   = sigma_hat,
      x           = x,
      y           = y
    ),
    class = c("lb_fit", "lb_spec")
  )
}
