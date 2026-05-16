#' Compute stability-selection summaries for bootstrap output
#'
#' Summarises each term's selection probability trajectory across the lambda
#' path: the maximum selection probability, the lambda range over which
#' selection probability exceeds 0.5, and related diagnostics. This is the
#' source of the `stability_score` column in [tidy.lb_boot()].
#'
#' @param boot An `lb_boot` object with `store_path = TRUE`.
#'
#' @return A tibble with one row per term: `term`, `max_selection_prob`,
#'   `lambda_range`, and related stability diagnostics.
#' @export
lb_stability <- function(boot) {
  stop("Not yet implemented", call. = FALSE)
}

#' Identify correlated predictor pairs with split selection probabilities
#'
#' Detects the "lasso picked one of two correlated predictors at random"
#' pathology. Flags pairs where `cor > cor_threshold` in the original data and
#' the individual selection probabilities are split (neither clearly dominant)
#' while the joint either-one probability is high.
#'
#' @param boot An `lb_boot` object.
#' @param cor_threshold Correlation threshold above which pairs are examined.
#'   Default `0.7`.
#' @param prob_threshold Individual selection probability threshold below which
#'   a term is considered "split". Default `0.5`.
#'
#' @return A tibble of flagged pairs with columns `term_1`, `term_2`,
#'   `correlation`, `prob_1`, `prob_2`, `prob_either`.
#' @export
lb_correlated_pairs <- function(boot, cor_threshold = 0.7, prob_threshold = 0.5) {
  stop("Not yet implemented", call. = FALSE)
}

#' Test whether terms meet a significance criterion
#'
#' A convenience predicate for use in [dplyr::filter()]. Three complementary
#' criteria: bootstrap CI exclusion of zero (`"ci"`), selection probability
#' threshold (`"selection"`), stability score threshold (`"stability"`), or all
#' three simultaneously (`"all"`).
#'
#' @param tidy_df A tibble from [tidy.lb_boot()].
#' @param method One of `"ci"`, `"selection"`, `"stability"`, or `"all"`.
#' @param threshold Probability threshold for `"selection"` and `"stability"`
#'   methods. Default `0.5`.
#'
#' @return A logical vector the same length as `nrow(tidy_df)`.
#' @export
lb_is_significant <- function(tidy_df,
                               method = c("ci", "selection", "stability", "all"),
                               threshold = 0.5) {
  stop("Not yet implemented", call. = FALSE)
}
