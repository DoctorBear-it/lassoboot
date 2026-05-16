#' Construct a measurement uncertainty specification
#'
#' Builds a tidy tibble declaring the measurement uncertainty on predictor
#' columns. Each column's uncertainty is expressed as an absolute standard
#' deviation (`std`), a coefficient of variation in percent (`cov`), or a
#' relative standard deviation as a fraction (`rel`).
#'
#' @param ... Named arguments of the form `column = std(value, source)`,
#'   `column = cov(value, source)`, or `column = rel(value, source)`.
#'   Alternatively, supply a pre-built tibble with columns `term`, `type`,
#'   `value`, and optionally `source`.
#'
#' @return A tibble with columns `term` (chr), `type` (chr: "std"/"cov"/"rel"),
#'   `value` (dbl, >= 0), `source` (chr, optional documentation).
#' @export
lb_uncertainty <- function(...) {
  stop("Not yet implemented", call. = FALSE)
}

# Internal helpers used inside lb_uncertainty() calls.
# Note: `cov` and `std` shadow base::cov / base::sd within the package
# namespace; they are not exported and are only evaluated inside lb_uncertainty().

std <- function(value, source = NA_character_) {
  stop("Not yet implemented", call. = FALSE)
}

cov <- function(value, source = NA_character_) { # nolint: object_name_linter
  stop("Not yet implemented", call. = FALSE)
}

rel <- function(value, source = NA_character_) {
  stop("Not yet implemented", call. = FALSE)
}
