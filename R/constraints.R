#' Specify per-column clipping constraints for bootstrap perturbation
#'
#' @param ... Named arguments of the form `column = c(lower, upper)`.
#'   Use `c(0, Inf)` for non-negative, `c(0, 100)` for weight percent,
#'   `c(-Inf, Inf)` to disable clipping for signed quantities.
#'
#' @return An `lb_constraints` object (a named list of numeric length-2 vectors).
#' @export
lb_constraints <- function(...) {
  stop("Not yet implemented", call. = FALSE)
}

# Internal: apply constraint clipping to a data frame, column by column.
# Order: perturb -> clip (.apply_constraints) -> derive (.apply_derives).
.apply_constraints <- function(data, constraints) {
  stop("Not yet implemented", call. = FALSE)
}
