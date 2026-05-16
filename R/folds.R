#' Standard k-fold cross-validation fold generator
#'
#' @param k Number of folds. Default `10`.
#'
#' @return A fold-generator closure `function(data) -> integer vector` of fold
#'   IDs the same length as `nrow(data)`.
#' @export
lb_folds_kfold <- function(k = 10) {
  stop("Not yet implemented", call. = FALSE)
}

#' Grouped k-fold fold generator (prevents within-group train/test leakage)
#'
#' Assigns whole groups to the same fold so that no group's observations appear
#' in both training and test sets.
#'
#' @param group Column name (string) whose levels define groups.
#' @param k Number of folds. Default `10`.
#'
#' @return A fold-generator closure `function(data) -> integer vector`.
#' @export
lb_folds_grouped <- function(group, k = 10) {
  stop("Not yet implemented", call. = FALSE)
}

#' Nested fold generator with outer grouping and optional inner stratification
#'
#' Places whole outer groups in the same fold (no leakage of group identity
#' across train/test) and stratifies within-fold composition by `inner` so
#' each fold sees a balanced distribution of the inner variable.
#'
#' @param outer Column name (string) defining the outer grouping (no leakage).
#' @param inner Column name (string) for inner stratification within each fold,
#'   or `NULL`. Default `NULL`.
#' @param k_outer Number of outer folds. Default `5`.
#' @param k_inner Reserved for future sub-folding; ignored in v0.1.
#'
#' @return A fold-generator closure `function(data) -> integer vector`.
#' @export
lb_folds_nested <- function(outer, inner = NULL, k_outer = 5, k_inner = NULL) {
  stop("Not yet implemented", call. = FALSE)
}

#' Block fold generator
#'
#' @param block Column name (string) defining contiguous blocks assigned as
#'   complete units to folds.
#' @param k Number of folds. Default `5`.
#'
#' @return A fold-generator closure `function(data) -> integer vector`.
#' @export
lb_folds_blocked <- function(block, k = 5) {
  stop("Not yet implemented", call. = FALSE)
}

#' Custom fold generator
#'
#' @param fn A function with signature `function(data) -> integer vector` of
#'   fold IDs the same length as `nrow(data)`. The function is responsible for
#'   any re-randomization across CV repetitions.
#'
#' @return A fold-generator closure (the input `fn`, validated and classed).
#' @export
lb_folds_custom <- function(fn) {
  stop("Not yet implemented", call. = FALSE)
}
