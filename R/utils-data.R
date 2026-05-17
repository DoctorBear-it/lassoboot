# Internal data-wrangling helpers.
# Functions here are not exported; place any bare column name references used
# via NSE in aaa_globals.R to silence R CMD CHECK "no visible binding" notes.

# Build a sparse predictor matrix and extract the response vector from a
# formula and data frame. Called by both lb_fit() and .boot_iter() so the
# formula-to-sparse-matrix logic is never duplicated.
#
# model.frame() is used first so that formula transformations on the response
# (e.g. log(y)) and on predictors (e.g. I(x^2)) are evaluated correctly.
# sparse.model.matrix() is then called on the model frame with the intercept
# suppressed (glmnet handles its own intercept and must not receive one in x).
.build_design_matrix <- function(formula, data) {
  mf <- stats::model.frame(formula, data = data)
  y  <- as.numeric(stats::model.response(mf))

  # Build a no-intercept formula from the term labels already resolved by
  # model.frame — avoids stats::update() failing when the formula uses `.`
  # shorthand (terms.formula() cannot expand `.` without data).
  term_labels <- attr(attr(mf, "terms"), "term.labels")
  rhs_no_int  <- stats::reformulate(term_labels, intercept = FALSE)
  x           <- Matrix::sparse.model.matrix(rhs_no_int, data = mf)

  list(x = x, y = y)
}
