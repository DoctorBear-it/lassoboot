# Internal matrixStats-based prediction summary helpers.
# The prediction pipeline is always matrix-based: an n x B numeric matrix
# is the internal representation; summaries computed via
# matrixStats::rowQuantiles, rowMeans2, rowSds. No nest()/unnest() in the
# hot path.

# Expand the sparse long coef_tbl into a dense B x (p+1) coefficient matrix.
# Absent term/iteration combinations have implicit coefficient 0 (lasso
# dropped them). The matrix has one column per term in `term_names` and one
# row per bootstrap iteration 1..B.
#
# term_names: character vector of all design-matrix column names including
#   "(Intercept)" — length p+1.
# Returns a numeric matrix of shape B x (p+1), columns named by term_names.
.coef_matrix <- function(coef_tbl, B, term_names) {
  mat <- matrix(0.0, nrow = B, ncol = length(term_names),
                dimnames = list(NULL, term_names))
  if (nrow(coef_tbl) > 0L) {
    # Map term names to column indices; silently ignore terms not in term_names
    # (should not happen, but defensive)
    col_idx <- match(coef_tbl$term, term_names)
    valid   <- !is.na(col_idx)
    if (any(valid)) {
      mat[cbind(coef_tbl$iteration[valid], col_idx[valid])] <-
        coef_tbl$estimate[valid]
    }
  }
  mat
}

# Compute an n x B prediction matrix from a raw n x p design matrix and a
# B x (p+1) coefficient matrix (intercept in column 1).
#
# X_new  : n x p numeric or sparse matrix (no intercept column).
# coef_mat: B x (p+1) dense numeric matrix, first column = intercept.
#
# Internally prepends a column of 1s to X_new so that the matrix multiply
# conforms: (n x p+1) %*% t(B x p+1) = n x B.
# Callers never need to know about or add the intercept column.
.predict_matrix <- function(X_new, coef_mat) {
  X_aug  <- cbind(1, as.matrix(X_new))   # n x (p+1)
  result <- X_aug %*% t(coef_mat)       # n x B
  # Strip row names so callers receive a plain numeric matrix with no lingering
  # sparse-matrix row-index names.
  rownames(result) <- NULL
  result
}

# Summarise an n x B prediction matrix into a 3-column matrix:
# .fitted (row means), .lower (alpha/2 quantile), .upper (1-alpha/2 quantile).
# Uses matrixStats for speed; no tibble allocation.
#
# pred_mat: n x B numeric matrix.
# level   : confidence level in (0, 1), e.g. 0.95.
# Returns an n x 3 numeric matrix with column names .fitted/.lower/.upper.
.summarise_pred_matrix <- function(pred_mat, level = 0.95) {
  alpha <- 1 - level
  probs <- c(alpha / 2, 1 - alpha / 2)
  qs    <- matrixStats::rowQuantiles(pred_mat, probs = probs)
  out   <- cbind(
    matrixStats::rowMeans2(pred_mat),
    qs[, 1L],
    qs[, 2L]
  )
  colnames(out) <- c(".fitted", ".lower", ".upper")
  out
}
