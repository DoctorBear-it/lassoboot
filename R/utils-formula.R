# Internal formula manipulation helpers.

# Check for random-effect terms. Errors if a bars-finder is available and
# detects them; warns via a proxy "|" string check if neither package is found.
.check_re_terms <- function(formula) {
  if (requireNamespace("reformulas", quietly = TRUE)) {
    bars <- reformulas::findbars(formula)
  } else if (requireNamespace("lme4", quietly = TRUE)) {
    bars <- suppressWarnings(lme4::findbars(formula))
  } else {
    bars <- NULL
    fstr <- paste(deparse(formula), collapse = "")
    if (grepl("|", fstr, fixed = TRUE)) {
      cli::cli_warn(c(
        "Formula may contain random-effect terms, but neither {.pkg reformulas} \\
         nor {.pkg lme4} is installed.",
        "i" = "Install {.pkg lme4} for accurate detection."
      ))
    }
  }
  if (!is.null(bars) && length(bars) > 0L) {
    cli::cli_abort(c(
      "Random-effect terms found in formula.",
      "i" = "The glmnet engine does not support mixed effects.",
      "i" = "Future versions will provide {.fn lb_engine_glmmlasso} for this case.",
      "i" = "Remove the {.code (... | ...)} terms from your formula."
    ))
  }
  invisible(NULL)
}

# Extract the response variable name(s) from the LHS of a two-sided formula.
.formula_response <- function(formula) {
  all.vars(formula[[2L]])
}

# Extract predictor variable names from the RHS of a formula.
# Returns the bare variable names (no transformations, no interactions expanded).
.formula_predictors <- function(formula) {
  all.vars(formula[[3L]])
}
