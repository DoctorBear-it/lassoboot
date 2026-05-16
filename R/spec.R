#' Specify a lasso bootstrap model
#'
#' The primary entry point for `lassoboot`. Declares the formula, data,
#' measurement uncertainty, derived quantities, per-column constraints,
#' cross-validation fold scheme, engine, and tuning control for the subsequent
#' bootstrap. Validates all inputs immediately and emits informative errors
#' that name domain quantities, not statistical operations.
#'
#' @param formula A model formula. The response must be numeric. Random-effect
#'   terms (e.g. `(1 | group)`) are not supported by the glmnet engine and
#'   raise an informative error.
#' @param data A data frame or tibble.
#' @param uncertainty A measurement uncertainty specification from
#'   [lb_uncertainty()], or `NULL` for no predictor perturbation.
#'   Default `NULL`.
#' @param derive A list of [lb_derive()] objects evaluated in declaration order
#'   inside the bootstrap loop after uncertainty injection and constraint
#'   clipping. Default `NULL`.
#' @param constraints A [lb_constraints()] object specifying per-column
#'   clipping bounds, or `NULL` to infer defaults (non-negative if all observed
#'   values >= 0, unconstrained otherwise). Default `NULL`. Inferred defaults
#'   are reported once at construction.
#' @param folds A fold-generator function from `lb_folds_*()`. Default
#'   [lb_folds_kfold()].
#' @param engine An engine from `lb_engine_*()`. Default [lb_engine_glmnet()].
#' @param control A [lb_control()] object. Default [lb_control()].
#'
#' @return An `lb_spec` object.
#' @export
lb_spec <- function(formula, data,
                    uncertainty = NULL,
                    derive = NULL,
                    constraints = NULL,
                    folds = lb_folds_kfold(10),
                    engine = lb_engine_glmnet(),
                    control = lb_control()) {
  stop("Not yet implemented", call. = FALSE)
}
