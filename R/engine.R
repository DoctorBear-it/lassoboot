# Internal: validate that an object conforms to the lb_engine interface.
# An engine must be a named list with class "lb_engine" and exactly five
# function-valued slots: fit, predict, coef, cv, sigma.
# Called by lb_spec() at construction time.
.validate_engine <- function(engine) {
  if (!inherits(engine, "lb_engine")) {
    cli::cli_abort(
      c("Engine must have class {.cls lb_engine}.",
        "i" = "Use {.fn lb_engine_glmnet} to create an engine.")
    )
  }
  required <- c("fit", "predict", "coef", "cv", "sigma")
  missing_methods <- setdiff(required, names(engine))
  if (length(missing_methods) > 0L) {
    cli::cli_abort(
      "Engine is missing required method{?s}: {.val {missing_methods}}."
    )
  }
  not_functions <- required[!vapply(engine[required], is.function, logical(1L))]
  if (length(not_functions) > 0L) {
    cli::cli_abort(
      "Engine slot{?s} {.val {not_functions}} must be function{?s}."
    )
  }
  invisible(engine)
}
