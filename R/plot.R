#' Plot bootstrap lasso output
#'
#' Dispatcher for all `lb_plot_*()` functions. Each type delegates to the
#' corresponding named function and returns a plain `ggplot` object (no
#' `print()`, no side effects). All inherit data through [tidy.lb_boot()] so
#' user-supplied filtering works identically.
#'
#' @param object An `lb_boot` object.
#' @param type Plot type: `"coefficients"` (default), `"selection"`,
#'   `"stability"`, `"interactions"`, `"complexity"`, or `"prediction"`.
#' @param ... Passed to the underlying `lb_plot_*()` function.
#'
#' @return A `ggplot` object.
#' @export
autoplot.lb_boot <- function(object,
                              type = c("coefficients", "selection", "stability",
                                       "interactions", "complexity", "prediction"),
                              ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Plot bootstrap coefficient estimates with confidence intervals
#'
#' @param x An `lb_boot` object.
#' @param scale `"raw"` (default) or `"gelman"` (2-SD scaling).
#' @param filter `"all"` (default), `"significant"` (CI excludes zero), or
#'   `"selected"` (selection_prob > 0.5).
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @export
lb_plot_coefficients <- function(x, scale = c("raw", "gelman"),
                                  filter = c("all", "significant", "selected"),
                                  ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Plot selection probabilities
#'
#' @param x An `lb_boot` object.
#' @param threshold Reference line at this selection probability. Default `0.5`.
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @export
lb_plot_selection <- function(x, threshold = 0.5, ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Plot stability trajectories (selection probability vs. lambda)
#'
#' @param x An `lb_boot` object. Requires `store_path = TRUE`.
#' @param top_n Number of terms to show ranked by max selection probability.
#'   Default `20`.
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @export
lb_plot_stability <- function(x, top_n = 20, ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Plot interaction effects
#'
#' @param x An `lb_boot` object.
#' @param order Interaction order to display. Default `2L`.
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @export
lb_plot_interactions <- function(x, order = 2L, ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Plot a prediction ribbon for a focal predictor
#'
#' Wraps [lb_grid()] and [predict.lb_boot()] to produce a ribbon plot of
#' `.fitted +/- interval` vs. the focal predictor.
#'
#' @param x An `lb_boot` object.
#' @param focal Name of the focal predictor (string).
#' @param by A `vars()` expression for faceting, or `NULL`. Default `NULL`.
#' @param raw_data A data frame to overlay as points, or `NULL`. Default `NULL`.
#' @param ... Passed to [lb_grid()].
#'
#' @return A `ggplot` object.
#' @export
lb_plot_prediction <- function(x, focal, by = NULL, raw_data = NULL, ...) {
  stop("Not yet implemented", call. = FALSE)
}

#' Plot model complexity (number of selected terms) across bootstrap iterations
#'
#' @param x An `lb_boot` object.
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @export
lb_plot_complexity <- function(x, ...) {
  stop("Not yet implemented", call. = FALSE)
}
