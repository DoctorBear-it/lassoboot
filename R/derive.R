#' Capture a derived-variable expression for re-evaluation in the bootstrap loop
#'
#' Derived quantities (e.g. `volume = mass / density`) must be recomputed
#' *after* uncertainty injection and constraint clipping so that measurement
#' error propagates correctly through the derived value.
#'
#' Derives run in declaration order and may chain: a second derive may reference
#' a column produced by the first.
#'
#' @param ... A single named expression `lhs = rhs`. `lhs` is the column name
#'   to create or overwrite in the perturbed data frame; `rhs` is an expression
#'   evaluated via [rlang::eval_tidy()] in the context of that data frame.
#'
#' @return An `lb_derive` object (a classed list with `$name` and `$expr`).
#' @examples
#' # Derive volume from mass and density
#' lb_derive(volume = mass / density)
#'
#' # Second derive can reference a column from the first
#' lb_derive(volume_total = volume_Alite + volume_Belite)
#' @export
lb_derive <- function(...) {
  quos <- rlang::enquos(...)
  if (length(quos) != 1L) {
    cli::cli_abort(
      "{.fn lb_derive} takes exactly one named expression; got {length(quos)}."
    )
  }
  nm <- names(quos)
  if (is.null(nm) || nm == "") {
    cli::cli_abort(
      "The argument to {.fn lb_derive} must be named (e.g. {.code lb_derive(volume = mass / density)})."
    )
  }
  structure(
    list(name = nm, expr = quos[[1L]]),
    class = "lb_derive"
  )
}

# Internal: evaluate a list of lb_derive objects in declaration order.
# Each derive may reference columns created by earlier derives.
# Emits a one-time message (per lb_spec construction) if a derive overwrites
# an existing column; per-iteration messages are suppressed via `quiet`.
.apply_derives <- function(data, derive_list, existing_cols = NULL, quiet = TRUE) {
  if (is.null(derive_list) || length(derive_list) == 0L) return(data)

  for (drv in derive_list) {
    if (!inherits(drv, "lb_derive")) {
      cli::cli_abort(
        "Each element of {.arg derive} must be created with {.fn lb_derive}."
      )
    }
    if (!quiet && !is.null(existing_cols) && drv$name %in% existing_cols) {
      cli::cli_inform(
        c("i" = "{.fn lb_derive}: column {.val {drv$name}} already exists in
               data and will be overwritten by the derive.")
      )
    }
    result <- tryCatch(
      rlang::eval_tidy(drv$expr, data = data),
      error = function(e) {
        cli::cli_abort(
          c("Error evaluating derive for column {.val {drv$name}}.",
            "x" = conditionMessage(e)),
          call = NULL
        )
      }
    )
    n <- nrow(data)
    if (length(result) != n) {
      cli::cli_abort(
        c(
          "Derive for column {.val {drv$name}} returned {length(result)} value{?s},
           but data has {n} row{?s}.",
          "i" = "The RHS expression must return one value per row.
                 If you intended a scalar constant, add the column to your data
                 before calling {.fn lb_spec}."
        )
      )
    }
    data[[drv$name]] <- result
  }
  data
}
