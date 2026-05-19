#' Create a glmnet engine for lassoboot
#'
#' The default engine. Wraps `glmnet::glmnet` and `glmnet::cv.glmnet` behind
#' the `lb_engine` interface. The bootstrap loop calls engine methods by name
#' and never calls `glmnet::glmnet` directly, keeping future engine additions
#' (e.g. `lb_engine_glmmlasso()`) non-breaking.
#'
#' @return An object of class `c("lb_engine_glmnet", "lb_engine")`: a named
#'   list with five methods: `fit`, `predict`, `coef`, `cv`, and `sigma`.
#' @examples
#' eng <- lb_engine_glmnet()
#' class(eng)
#' names(eng)
#' @export
lb_engine_glmnet <- function() {
  structure(
    list(
      # ------------------------------------------------------------------ fit
      # Fit a lasso model at a fixed lambda value (or path).
      # x       : sparse or dense predictor matrix (n x p)
      # y       : numeric response vector (length n)
      # lambda  : numeric scalar or vector; passed to glmnet's `lambda` arg
      # weights : optional numeric vector of observation weights
      # ...     : forwarded to glmnet::glmnet (e.g. intercept, standardize)
      fit = function(x, y, lambda, weights = NULL, ...) {
        glmnet::glmnet(
          x       = x,
          y       = y,
          alpha   = 1,          # lasso; alpha != 1 reserved for v0.2
          lambda  = lambda,
          weights = weights,
          ...
        )
      },

      # --------------------------------------------------------------- predict
      # Generate predictions from a fitted glmnet object.
      # fit  : object returned by engine$fit()
      # newx : predictor matrix for new observations
      # s    : lambda value(s) at which to predict; defaults to fit$lambda[1]
      predict = function(fit, newx, s = NULL, ...) {
        s <- s %||% fit$lambda[1L]
        as.numeric(
          stats::predict(fit, newx = newx, s = s, type = "response", ...)
        )
      },

      # ----------------------------------------------------------------- coef
      # Extract coefficients at one or more lambda values.
      #
      # scalar s (length 1): returns a named numeric vector of length p+1
      #   (intercept first). Preserving names is required: coef_tbl term
      #   labels and sigma refit both rely on coefficient names matching
      #   design-matrix column names plus "(Intercept)".
      #
      # vector s (length > 1): returns the raw dgCMatrix from
      #   stats::coef(fit, s = s), shape (p+1) x length(s), rownames =
      #   design-matrix columns + "(Intercept)". Used by .boot_iter() for
      #   path storage so that stability diagnostics see a consistent grid.
      #   No numeric coercion — callers consume it as a sparse matrix.
      coef = function(fit, s = NULL, ...) {
        s  <- s %||% fit$lambda[1L]
        cf <- stats::coef(fit, s = s, ...)
        if (length(s) == 1L) {
          # Scalar path: coerce (p+1) x 1 dgCMatrix to named numeric vector
          nms  <- rownames(cf)
          vals <- as.numeric(cf)
          if (!is.null(nms)) stats::setNames(vals, nms) else vals
        } else {
          # Vector path: return (p+1) x length(s) dgCMatrix as-is
          cf
        }
      },

      # ------------------------------------------------------------------ cv
      # Cross-validated lambda selection.
      # x       : predictor matrix
      # y       : response vector
      # foldid  : integer vector of fold IDs (same length as nrow(x))
      # nlambda : number of lambda values in the path (passed to glmnet);
      #           defaults to 100 if not supplied by the caller
      # lambda  : optional numeric vector to fix the lambda path explicitly;
      #           when NULL, glmnet selects its own path of length nlambda
      # ...     : forwarded to glmnet::cv.glmnet
      #
      # Returns a named list with:
      #   lambda.min  — lambda minimising CV MSE
      #   lambda.1se  — largest lambda within 1 SE of the minimum
      #   lambda_path — the full lambda grid evaluated
      #   cvm         — mean CV error at each lambda in lambda_path
      cv = function(x, y, foldid, nlambda = 100L, lambda = NULL, ...) {
        if (!is.numeric(nlambda) || length(nlambda) != 1L ||
              !is.finite(nlambda) || nlambda < 1L) {
          cli::cli_abort(
            "{.arg nlambda} must be a single positive integer; got {.val {nlambda}}."
          )
        }
        if (!is.null(lambda) &&
              (!is.numeric(lambda) || any(!is.finite(lambda)) ||
               any(lambda <= 0))) {
          cli::cli_abort(
            "{.arg lambda} must be a numeric vector of positive finite values, or NULL."
          )
        }
        fit_cv <- glmnet::cv.glmnet(
          x       = x,
          y       = y,
          alpha   = 1,
          foldid  = foldid,
          nlambda = as.integer(nlambda),
          lambda  = lambda,
          ...
        )
        list(
          lambda.min  = fit_cv$lambda.min,
          lambda.1se  = fit_cv$lambda.1se,
          lambda_path = fit_cv$lambda,
          cvm         = fit_cv$cvm
        )
      },

      # --------------------------------------------------------------- sigma
      # Residual standard error estimation. Delegates to sigma.R.
      # method: one of "refit", "naive", "cv"
      # foldid: integer fold-ID vector used by method = "cv"; passed via ...
      sigma = function(fit, x, y, method = "refit", ...) {
        .estimate_sigma(fit, x, y, method = method, ...)
      }
    ),
    class = c("lb_engine_glmnet", "lb_engine")
  )
}
