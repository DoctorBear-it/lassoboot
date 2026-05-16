#' Normalize a response by a reference strength
#'
#' A convenience wrapper around [lb_derive()] for the pattern
#' `response = measured / reference`, where both `measured` and `reference`
#' carry their own measurement uncertainty and are perturbed independently in
#' each bootstrap iteration. The user is responsible for declaring uncertainty
#' on both columns and for ensuring the declared uncertainties are consistent
#' with any pre-aggregation (e.g., if `reference` is a mean of triplicates,
#' declare the standard error of that mean, not the single-measurement SD).
#'
#' @param spec An `lb_spec` object.
#' @param response The column to create/overwrite as the normalized response
#'   (unquoted symbol). This column overwrites the LHS of the spec's formula.
#' @param measured The measured response column (unquoted symbol).
#' @param reference The reference response column (unquoted symbol).
#'
#' @return An updated `lb_spec` object with the normalization registered as a
#'   derived column.
#' @export
lb_normalize <- function(spec, response, measured, reference) {
  stop("Not yet implemented", call. = FALSE)
}
