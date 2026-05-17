#' Construct a measurement uncertainty specification
#'
#' Builds a tidy tibble declaring the measurement uncertainty on predictor
#' columns. Use the helper constructors `std()`, `cov()`, and `rel()` as values
#' inside the call.
#'
#' ## Helper constructors
#'
#' Inside `lb_uncertainty(...)` calls, three short helpers are available:
#'
#' - `std(value, source)` — absolute standard deviation in the units of the
#'   column.
#' - `cov(value, source)` — coefficient of variation as a **percentage**
#'   (`cov(4.0, ...)` means 4%, not 400%).
#' - `rel(value, source)` — relative standard deviation as a **fraction**
#'   (`rel(0.04, ...)` is equivalent to `cov(4.0, ...)`).
#'
#' These helpers are **only available inside `lb_uncertainty()`** — they do not
#' appear in the package namespace and do not shadow `stats::cov()` or any
#' other function globally. Internally, `lb_uncertainty()` evaluates its
#' arguments in a child environment that defines `std`, `cov`, and `rel`;
#' outside that call, the names resolve normally.
#'
#' ## Example
#'
#' ```r
#' lb_uncertainty(
#'   alumina  = std(0.071, "ASTM C114"),
#'   SSA      = cov(0.56,  "Mfr certificate of analysis"),
#'   strength = cov(4.0,   "ASTM C109 §10.3 single-operator")
#' )
#' ```
#'
#' @param ... Named arguments `column = std(value)`, `column = cov(value)`, or
#'   `column = rel(value)`. Alternatively, a single pre-built tibble with
#'   columns `term`, `type`, `value`, and optionally `source`.
#'
#' @return A tibble with columns `term` (chr), `type` (chr: `"std"/"cov"/"rel"`),
#'   `value` (dbl, >= 0), `source` (chr).
#' @export
lb_uncertainty <- function(...) {
  # Build the evaluation environment BEFORE accessing `...` so that the
  # tibble fast-path and the helper path use the same helper_env.
  # NOTE: do NOT call list(...) here — it would force all argument promises
  # and try to evaluate std/cov/rel in the caller's env (where they don't
  # exist). Instead we use ...length() and ...elt() which force only what
  # we need.
  helper_env <- rlang::new_environment(
    data = list(
      std = .unc_std,
      cov = .unc_cov,
      rel = .unc_rel
    ),
    parent = rlang::caller_env()
  )

  # Fast path: single UNNAMED argument that is already a data frame/tibble.
  # ...names() and ...length() inspect the dots without forcing promises.
  # We only call ...elt(1L) (which forces evaluation) when the single arg is
  # unnamed — in that case it cannot be std/cov/rel, so forcing is safe.
  if (...length() == 1L) {
    arg_name <- ...names()[[1L]]
    if (is.null(arg_name) || arg_name == "") {
      # Force the single unnamed argument — but wrap in tryCatch so that if
      # the user wrote `lb_uncertainty(std(1))` (forgot the name), the
      # force attempt fails silently and we fall through to the named-arg
      # check below, which issues a clear "must be named" error.
      val <- tryCatch(...elt(1L), error = function(e) NULL)
      if (is.data.frame(val)) return(.validate_uncertainty_tbl(val))
      # Not a data frame — fall through; rlang::exprs() captures the
      # unnamed expression and the name check below raises a clear error.
    }
  }

  # Capture the named expressions WITHOUT forcing them, then evaluate each
  # in helper_env (where std/cov/rel are defined).
  all_exprs <- rlang::exprs(...)
  if (length(all_exprs) == 0L) {
    cli::cli_abort("{.fn lb_uncertainty} requires at least one named argument.")
  }
  nms <- names(all_exprs)
  if (is.null(nms) || any(nms == "")) {
    cli::cli_abort("All arguments to {.fn lb_uncertainty} must be named.")
  }

  rows <- vector("list", length(all_exprs))
  for (i in seq_along(all_exprs)) {
    result <- eval(all_exprs[[i]], envir = helper_env)
    if (!inherits(result, ".lb_unc_entry")) {
      cli::cli_abort(
        c("Argument {.val {nms[i]}} did not return a valid uncertainty entry.",
          "i" = "Use {.code std()}, {.code cov()}, or {.code rel()} as values.")
      )
    }
    rows[[i]] <- tibble::tibble(
      term   = nms[i],
      type   = result$type,
      value  = result$value,
      source = result$source
    )
  }

  dplyr::bind_rows(rows)
}

# ---------------------------------------------------------------------------
# Internal helper constructors — evaluated inside lb_uncertainty() only.
# NOTE: Within all other package code, always use stats::cov() with the
# explicit prefix to avoid any ambiguity with this internal .unc_cov helper.
# ---------------------------------------------------------------------------

.unc_entry <- function(type, value, source) {
  if (!is.numeric(value) || length(value) != 1L) {
    cli::cli_abort("{.arg value} must be a single number; got {.cls {class(value)}}.")
  }
  if (is.na(value)) {
    cli::cli_abort("{.arg value} must not be NA. Omit the column from the spec instead.")
  }
  if (value < 0) {
    cli::cli_abort("{.arg value} must be >= 0; got {value}.")
  }
  if (!is.character(source) || length(source) != 1L) {
    cli::cli_abort("{.arg source} must be a single string or NA_character_.")
  }
  structure(list(type = type, value = value, source = source),
            class = ".lb_unc_entry")
}

.unc_std <- function(value, source = NA_character_) {
  .unc_entry("std", value, source)
}

.unc_cov <- function(value, source = NA_character_) {
  .unc_entry("cov", value, source)
}

.unc_rel <- function(value, source = NA_character_) {
  .unc_entry("rel", value, source)
}

# ---------------------------------------------------------------------------
# Internal: validate a pre-built uncertainty tibble.
# ---------------------------------------------------------------------------
.validate_uncertainty_tbl <- function(tbl) {
  required <- c("term", "type", "value")
  missing_cols <- setdiff(required, names(tbl))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Uncertainty tibble is missing column{?s}: {.val {missing_cols}}."
    )
  }
  valid_types <- c("std", "cov", "rel")
  bad_types <- setdiff(unique(tbl$type), valid_types)
  if (length(bad_types) > 0L) {
    cli::cli_abort(
      c("Column {.col type} contains invalid value{?s}: {.val {bad_types}}.",
        "i" = "Must be one of {.val {valid_types}}.")
    )
  }
  if (any(is.na(tbl$value))) {
    cli::cli_abort("Column {.col value} must not contain NA.")
  }
  if (any(tbl$value < 0, na.rm = TRUE)) {
    cli::cli_abort("Column {.col value} must be >= 0 for all rows.")
  }
  if (!"source" %in% names(tbl)) {
    tbl$source <- NA_character_
  }
  tibble::as_tibble(tbl)
}

# Internal: validate uncertainty column names against data.
# Called by lb_spec() after data is known.
.validate_uncertainty_terms <- function(uncertainty, data) {
  if (is.null(uncertainty)) return(invisible(NULL))
  missing_terms <- setdiff(uncertainty$term, names(data))
  if (length(missing_terms) > 0L) {
    cli::cli_abort(
      c(
        "Column{?s} declared in uncertainty not found in {.arg data}:
         {.val {missing_terms}}.",
        "i" = "Every {.col term} must match a column name in the data."
      )
    )
  }
  non_numeric <- uncertainty$term[
    !vapply(data[uncertainty$term], is.numeric, logical(1L))
  ]
  if (length(non_numeric) > 0L) {
    cli::cli_abort(
      c(
        "Uncertainty declared for non-numeric column{?s}: {.val {non_numeric}}.",
        "i" = "Measurement uncertainty can only be applied to numeric columns."
      )
    )
  }
  invisible(NULL)
}
