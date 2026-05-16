#' Run the parametric bootstrap
#'
#' For each of `B` iterations: perturbs predictors using the declared
#' measurement uncertainty, applies constraints, re-evaluates derived
#' quantities, generates a parametric response from the original fit, refits
#' via the engine, and stores coefficients (and optionally the full path and
#' fit objects). Returns an `lb_boot` object.
#'
#' @param spec_or_fit An `lb_spec` or `lb_fit` object. When an `lb_spec` is
#'   supplied, [lb_fit()] is called first. Supplying an `lb_fit` skips that
#'   step and is useful for inspecting the initial fit before committing to a
#'   large bootstrap run.
#' @param B Number of bootstrap iterations. Default `1000`.
#' @param ... Additional arguments passed to the engine.
#'
#' @return An `lb_boot` object containing the parent `lb_fit`, a tidy
#'   coefficient tibble (B x p_selected rows), optional full-path coefficient
#'   matrix, optional stored fit objects, the effective seed, and timings.
#' @export
lb_bootstrap <- function(spec_or_fit, B = 1000, ...) {
  stop("Not yet implemented", call. = FALSE)
}

# Internal worker called once per bootstrap iteration.
.boot_iter <- function(b, fit, engine, control) {
  stop("Not yet implemented", call. = FALSE)
}

# Internal: perturb predictors according to the uncertainty specification.
.apply_uncertainty <- function(data, uncertainty) {
  stop("Not yet implemented", call. = FALSE)
}
