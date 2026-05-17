#' Specify per-column clipping constraints for bootstrap perturbation
#'
#' Each named argument is a length-2 numeric vector `c(lower, upper)` giving
#' the allowable range for that column after uncertainty injection. A column not
#' listed receives an inferred default at [lb_spec()] time: `c(0, Inf)` if all
#' observed values are `>= 0`, otherwise `c(-Inf, Inf)`.
#'
#' @param ... Named arguments of the form `column = c(lower, upper)`.
#'   Use `c(0, Inf)` for non-negative, `c(0, 100)` for weight percent,
#'   `c(-Inf, Inf)` to disable clipping for signed quantities.
#'
#' @return An `lb_constraints` object (a named list of numeric length-2
#'   vectors).
#' @export
lb_constraints <- function(...) {
  entries <- list(...)
  if (length(entries) == 0L) {
    cli::cli_abort("{.fn lb_constraints} requires at least one named argument.")
  }
  nms <- names(entries)
  if (is.null(nms) || any(nms == "")) {
    cli::cli_abort("All arguments to {.fn lb_constraints} must be named.")
  }
  for (nm in nms) {
    v <- entries[[nm]]
    if (!is.numeric(v) || length(v) != 2L) {
      cli::cli_abort(
        "{.arg {nm}} must be a numeric vector of length 2 (lower, upper);
         got {.cls {class(v)}} of length {length(v)}."
      )
    }
    if (v[1L] > v[2L]) {
      cli::cli_abort(
        "Lower bound must be <= upper bound for {.arg {nm}};
         got c({v[1]}, {v[2]})."
      )
    }
  }
  structure(entries, class = "lb_constraints")
}

# Internal: infer default constraints from observed data.
# Returns a named list of c(lower, upper) for columns not covered by explicit
# constraints. Emits a single cli message listing the inferred defaults.
.infer_constraints <- function(data, explicit, predictor_cols) {
  inferred      <- list()
  nonneg_cols   <- character(0L)
  signed_cols   <- character(0L)

  for (nm in predictor_cols) {
    if (nm %in% names(explicit)) next
    col <- data[[nm]]
    if (!is.numeric(col)) next
    if (all(col >= 0, na.rm = TRUE)) {
      inferred[[nm]]  <- c(0, Inf)
      nonneg_cols     <- c(nonneg_cols, nm)
    } else {
      inferred[[nm]]  <- c(-Inf, Inf)
      signed_cols     <- c(signed_cols, nm)
    }
  }

  if (length(inferred) > 0L) {
    msgs <- character(0L)
    if (length(nonneg_cols) > 0L) {
      msgs <- c(msgs, paste0(
        "  c(0, Inf) [non-negative]: ",
        paste(nonneg_cols, collapse = ", ")
      ))
    }
    if (length(signed_cols) > 0L) {
      msgs <- c(msgs, paste0(
        "  c(-Inf, Inf) [mixed-sign]: ",
        paste(signed_cols, collapse = ", ")
      ))
    }
    cli::cli_inform(
      c(
        "i" = "Inferred default constraints for {length(inferred)} predictor{?s}:",
        msgs,
        "i" = "Override with {.fn lb_constraints} to change any of these."
      )
    )
  }

  inferred
}

# Internal: merge explicit and inferred constraints into one list.
.merge_constraints <- function(explicit, inferred) {
  c(as.list(explicit), inferred)
}

# Internal: apply constraint clipping to a data frame, column by column.
# `constraints` is the merged named list from .merge_constraints().
# Order of operations: perturb -> .apply_constraints() -> .apply_derives().
.apply_constraints <- function(data, constraints) {
  for (nm in names(constraints)) {
    if (!nm %in% names(data)) next
    bounds <- constraints[[nm]]
    lower  <- bounds[1L]
    upper  <- bounds[2L]
    if (is.finite(lower) || is.finite(upper)) {
      data[[nm]] <- pmax(pmin(data[[nm]], upper), lower)
    }
  }
  data
}
