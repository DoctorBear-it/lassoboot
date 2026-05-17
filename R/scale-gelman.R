# Internal: apply Gelman 2-SD scaling to a named coefficient vector.
#
# Each numeric predictor's coefficient is multiplied by 2 * sd(predictor),
# placing all predictors on a "2-standard-deviation change" scale so that
# continuous and binary predictors are comparable (Gelman 2008).
#
# Rules:
#   - Numeric columns: scale factor = 2 * sd(x_j).
#   - Interaction terms (column names containing ":"): scale factor = product
#     of the two parent predictors' individual 2-SD factors. If a parent is
#     categorical its factor is 1.
#   - Categorical contrasts (columns not found in data as numeric, i.e. factor
#     indicator columns like "gradeB"): scale factor = 1 (unscaled).
#   - "(Intercept)": scale factor = 1 (never scaled).
#
# coefs     : named numeric vector of coefficients (including intercept).
# data      : the original data frame (spec$data) used to compute predictor SDs.
# term_names: character vector of all design-matrix column names (the row names
#             of coefs). Passed separately so callers can subset freely.
#
# Returns a numeric vector of the same length as coefs with scale factors applied.
.scale_gelman <- function(coefs, data) {
  nms    <- names(coefs)
  if (is.null(nms)) return(coefs)

  # Build a lookup: predictor name -> 2*sd, for numeric columns in data only.
  # Factors and characters get sd = NA (treated as categorical, factor = 1).
  sd_lookup <- vapply(names(data), function(nm) {
    x <- data[[nm]]
    if (is.numeric(x)) 2 * stats::sd(x, na.rm = TRUE) else NA_real_
  }, numeric(1L))

  scale_factor <- vapply(nms, function(term) {
    if (term == "(Intercept)") return(1.0)

    if (grepl(":", term, fixed = TRUE)) {
      # Interaction: decompose by ":" and multiply parent factors.
      parts <- strsplit(term, ":", fixed = TRUE)[[1L]]
      prod(vapply(parts, function(p) {
        # Strip any leading/trailing spaces (shouldn't occur but defensive)
        p <- trimws(p)
        f <- sd_lookup[p]
        if (is.na(f)) 1.0 else f   # categorical parent -> factor 1
      }, numeric(1L)))
    } else {
      f <- sd_lookup[term]
      if (is.na(f)) 1.0 else f     # categorical contrast -> factor 1
    }
  }, numeric(1L))

  coefs * scale_factor
}
