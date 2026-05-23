#' Normalize a response by a reference strength
#'
#' A convenience wrapper for the pattern `response = measured / reference`,
#' where both `measured` and `reference` carry their own measurement uncertainty
#' and are perturbed independently in each bootstrap iteration.
#'
#' `lb_normalize()` operates on an already-constructed `lb_spec`. It
#' materializes the response column from `measured / reference` on `spec$data`
#' so the spec's formula is valid for the initial fit, then registers an
#' [lb_derive()] that recomputes the same expression inside the bootstrap loop
#' on the perturbed inputs.
#'
#' **Important — response column must pre-exist in `data`.**
#' [lb_spec()] validates that the formula's left-hand side column exists in
#' `data` before `lb_normalize()` can run. If `response` does not exist in the
#' data passed to [lb_spec()], the spec call will abort. The recommended pattern
#' is to initialise the response column with placeholder values (`NA_real_` is
#' fine) in the data frame before calling [lb_spec()]:
#'
#' ```r
#' df$strength_ratio <- NA_real_          # placeholder; lb_normalize() overwrites
#' spec <- lb_spec(strength_ratio ~ ...,  # formula LHS matches the placeholder
#'                 data = df, ...) |>
#'   lb_normalize(response = strength_ratio,
#'                measured  = meas_strength,
#'                reference = ref_strength)
#' ```
#'
#' `lb_normalize()` overwrites the column with `measured / reference` on
#' `spec$data` immediately, so the initial [lb_fit()] inside [lb_bootstrap()]
#' uses the correct ratio values.
#'
#' The user is responsible for declaring uncertainty on **both** `measured` and
#' `reference` (via [lb_uncertainty()]). Forgetting to declare uncertainty on a
#' normalization component is the kind of silent mistake that would invalidate
#' the analysis; `lb_normalize()` treats it as a hard error.
#'
#' **Pre-aggregation note:** If `reference` is the mean of triplicate
#' measurements, the declared uncertainty should be the standard error of that
#' mean (`single-measurement SD / sqrt(n_replicates)`), not the
#' single-measurement SD. The package propagates whatever you declare; it does
#' not know about pre-aggregation.
#'
#' @param spec An `lb_spec` object.
#' @param response The column to create/overwrite as the normalized response
#'   (unquoted symbol). This column name replaces the LHS of the spec's formula.
#' @param measured The measured response column (unquoted symbol). Must exist in
#'   `spec$data` and be declared in `spec$uncertainty`.
#' @param reference The reference response column (unquoted symbol). Must exist
#'   in `spec$data` and be declared in `spec$uncertainty`.
#'
#' @return An updated `lb_spec` object with the normalization registered as a
#'   derived column and the response column materialized.
#' @examples
#' \dontrun{
#' # lb_spec() requires the response column to exist in `data` when the spec
#' # is built. Initialise a placeholder; lb_normalize() overwrites it with the
#' # correct ratio before the first lasso fit.
#' concrete_with_ref$strength_ratio <- NA_real_   # placeholder
#'
#' spec <- lb_spec(
#'   strength_ratio ~ clayHOH + alumina,
#'   data        = concrete_with_ref,
#'   uncertainty = lb_uncertainty(
#'     meas_strength = cov(3.0, "ASTM C109"),
#'     ref_strength  = cov(2.2, "ASTM C109, mean of 3")
#'   )
#' ) |>
#'   lb_normalize(
#'     response  = strength_ratio,
#'     measured  = meas_strength,
#'     reference = ref_strength
#'   )
#' # spec$data$strength_ratio now holds meas_strength / ref_strength for every
#' # row; each bootstrap iteration recomputes the ratio from perturbed inputs.
#' }
#' @export
lb_normalize <- function(spec, response, measured, reference) {
  if (!inherits(spec, "lb_spec")) {
    cli::cli_abort("{.arg spec} must be an {.cls lb_spec}.")
  }

  response_nm  <- rlang::as_name(rlang::ensym(response))
  measured_nm  <- rlang::as_name(rlang::ensym(measured))
  reference_nm <- rlang::as_name(rlang::ensym(reference))

  data <- spec$data

  # Both components must exist in data
  missing_cols <- setdiff(c(measured_nm, reference_nm), names(data))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      c("Column{?s} {.val {missing_cols}} not found in {.arg spec$data}.",
        "i" = "{.fn lb_normalize} requires both {.arg measured} and
               {.arg reference} to be columns in the data.")
    )
  }

  # Both must be declared in the uncertainty spec
  if (!is.null(spec$uncertainty)) {
    missing_unc <- setdiff(
      c(measured_nm, reference_nm),
      spec$uncertainty$term
    )
    if (length(missing_unc) > 0L) {
      cli::cli_abort(
        c(
          "Column{?s} {.val {missing_unc}} used in normalization but not
           declared in {.fn lb_uncertainty}.",
          "i" = "Declare uncertainty on both {.arg measured} and
                 {.arg reference} so that measurement error propagates
                 correctly through the ratio.",
          "i" = "If the reference is a mean of replicates, declare the
                 standard error of that mean, not the single-measurement
                 uncertainty."
        )
      )
    }
  }

  # Materialize the response column on spec$data so the formula is valid for
  # the initial fit (lb_spec() validates that the response column exists).
  spec$data[[response_nm]] <-
    spec$data[[measured_nm]] / spec$data[[reference_nm]]

  # Register the ratio as a derived column (re-evaluated in each bootstrap iter)
  derive_expr <- rlang::expr(
    !!rlang::sym(measured_nm) / !!rlang::sym(reference_nm)
  )
  new_derive     <- structure(
    list(name = response_nm, expr = rlang::new_quosure(derive_expr)),
    class = "lb_derive"
  )
  spec$derive    <- c(spec$derive, list(new_derive))

  # Update the formula LHS to use response_nm
  old_formula  <- spec$formula
  new_formula  <- stats::reformulate(
    deparse(old_formula[[3L]]),
    response = response_nm
  )
  spec$formula <- new_formula

  spec
}
