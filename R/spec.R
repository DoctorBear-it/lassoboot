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
#' @examples
#' spec <- suppressMessages(lb_spec(strength_MPa ~ clayHOH + alumina, data = concrete))
#' print(spec)
#' @export
lb_spec <- function(formula, data,
                    uncertainty = NULL,
                    derive = NULL,
                    constraints = NULL,
                    folds = lb_folds_kfold(10),
                    engine = lb_engine_glmnet(),
                    control = lb_control()) {

  # 1. Validate formula
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    cli::cli_abort(
      "{.arg formula} must be a two-sided formula (e.g. {.code response ~ predictors})."
    )
  }
  .check_re_terms(formula)

  # 2. Validate data
  if (!is.data.frame(data)) {
    cli::cli_abort(
      "{.arg data} must be a data frame or tibble; got {.cls {class(data)}}."
    )
  }
  if (nrow(data) < 1L) {
    cli::cli_abort("{.arg data} must have at least one row.")
  }

  # 3. Validate response: must exist in data and be numeric
  response_var <- .formula_response(formula)
  if (length(response_var) != 1L || !response_var %in% names(data)) {
    cli::cli_abort(
      "Response variable {.val {response_var[1]}} not found in {.arg data}."
    )
  }
  if (!is.numeric(data[[response_var]])) {
    cli::cli_abort(
      c("Response variable {.val {response_var}} must be numeric.",
        "x" = "Got {.cls {class(data[[response_var]])}}.")
    )
  }

  # 4. Validate uncertainty column names against data
  if (!is.null(uncertainty)) {
    .validate_uncertainty_terms(uncertainty, data)
  }

  # 5. Validate derive list; fire overwrite messages once at spec-construction
  #    time so they do not repeat on every bootstrap iteration (carry-forward #3)
  if (!is.null(derive)) {
    if (!is.list(derive)) {
      cli::cli_abort("{.arg derive} must be a list of {.fn lb_derive} objects.")
    }
    for (i in seq_along(derive)) {
      if (!inherits(derive[[i]], "lb_derive")) {
        cli::cli_abort(
          "Element {i} of {.arg derive} must be created with {.fn lb_derive}."
        )
      }
    }
    # quiet = FALSE triggers the "column will be overwritten" message once here;
    # .apply_derives is called with quiet = TRUE inside the bootstrap loop.
    invisible(.apply_derives(data, derive, existing_cols = names(data), quiet = FALSE))
  }

  # 6. Validate/infer constraints
  predictor_cols <- setdiff(.formula_predictors(formula), response_var)

  if (!is.null(constraints)) {
    if (!inherits(constraints, "lb_constraints")) {
      cli::cli_abort(
        "{.arg constraints} must be an {.cls lb_constraints} object from {.fn lb_constraints}."
      )
    }
    .validate_constraints_against_data(constraints, data)
    explicit_list      <- as.list(constraints)
    inferred           <- .infer_constraints(data, explicit_list, predictor_cols)
    merged_constraints <- .merge_constraints(explicit_list, inferred)
  } else {
    inferred           <- .infer_constraints(data, list(), predictor_cols)
    merged_constraints <- inferred
  }

  # 7. Validate folds
  if (!is.function(folds)) {
    cli::cli_abort(
      "{.arg folds} must be a fold-generator function from {.fn lb_folds_kfold} etc."
    )
  }

  # 8. Validate engine
  .validate_engine(engine)

  # 9. Validate control
  if (!inherits(control, "lb_control")) {
    cli::cli_abort(
      "{.arg control} must be an {.cls lb_control} object from {.fn lb_control}."
    )
  }

  structure(
    list(
      formula     = formula,
      data        = data,
      uncertainty = uncertainty,
      derive      = derive,
      constraints = merged_constraints,
      folds       = folds,
      engine      = engine,
      control     = control
    ),
    class = "lb_spec"
  )
}
