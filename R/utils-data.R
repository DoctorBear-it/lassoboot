# Internal data-wrangling helpers.
# Functions here are not exported; place any bare column name references used
# via NSE in aaa_globals.R to silence R CMD CHECK "no visible binding" notes.

# Build a sparse predictor matrix for prediction from a response-stripped
# `terms` object. Used by predict.lb_boot() so that newdata (which has no
# response column) can be passed without model.frame() erroring.
#
# pred_terms: a `terms` object with the response already removed via
#   stats::delete.response(). Must carry the same predictor terms as the
#   original fit formula.
# data      : the newdata frame; need not contain the response column.
# Returns   : a dgCMatrix of shape n x p (no intercept, same as .build_design_matrix).
.build_predictor_matrix <- function(pred_terms, data) {
  mf <- stats::model.frame(pred_terms, data = data,
                            na.action = stats::na.pass)
  term_labels <- attr(pred_terms, "term.labels")
  rhs_no_int  <- stats::reformulate(term_labels, intercept = FALSE)
  Matrix::sparse.model.matrix(rhs_no_int, data = mf)
}

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
