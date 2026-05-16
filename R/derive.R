#' Capture a derived-variable expression for re-evaluation in the bootstrap loop
#'
#' Derived quantities (e.g. `volume = mass / density`) must be recomputed
#' *after* uncertainty injection and constraint clipping so that measurement
#' error propagates correctly through the derived value.
#'
#' @param ... A single named expression `lhs = rhs`. `lhs` is the column name
#'   to create or overwrite; `rhs` is an expression evaluated in the perturbed
#'   data frame via `rlang::eval_tidy()`. Derives run in declaration order, so
#'   they may chain (`volume_total = volume_A + volume_B`).
#'
#' @return An `lb_derive` object (a named quosure).
#' @export
lb_derive <- function(...) {
  stop("Not yet implemented", call. = FALSE)
}

# Internal: evaluate a list of lb_derive objects in order on a data frame.
# Called inside the bootstrap loop after .apply_constraints().
.apply_derives <- function(data, derive_list) {
  stop("Not yet implemented", call. = FALSE)
}
