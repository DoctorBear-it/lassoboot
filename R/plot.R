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
#' @param ... Passed to the underlying `lb_plot_*()` function. For
#'   `type = "prediction"`, `focal` (a column name string) must be supplied
#'   here.
#'
#' @return A `ggplot` object.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' autoplot(boot)
#' autoplot(boot, type = "selection")
#' }
#' @export
autoplot.lb_boot <- function(object,
                              type = c("coefficients", "selection", "stability",
                                       "interactions", "complexity", "prediction"),
                              ...) {
  type <- match.arg(type)
  switch(type,
    coefficients = lb_plot_coefficients(object, ...),
    selection    = lb_plot_selection(object, ...),
    stability    = lb_plot_stability(object, ...),
    interactions = lb_plot_interactions(object, ...),
    complexity   = lb_plot_complexity(object, ...),
    prediction   = lb_plot_prediction(object, ...)
  )
}

#' Plot bootstrap coefficient estimates with confidence intervals
#'
#' Produces a horizontal forest plot of bootstrap coefficient estimates and
#' quantile intervals, ordered by point estimate. Color encodes selection
#' probability.
#'
#' @param x An `lb_boot` object.
#' @param scale `"raw"` (default) or `"gelman"` (2-SD scaling per Gelman 2008).
#' @param filter `"all"` (default), `"significant"` (CI excludes zero), or
#'   `"selected"` (selection_prob > 0.5).
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_plot_coefficients(boot)
#' }
#' @export
lb_plot_coefficients <- function(x, scale = c("raw", "gelman"),
                                  filter = c("all", "significant", "selected"),
                                  ...) {
  scale  <- match.arg(scale)
  filter <- match.arg(filter)

  td <- tidy.lb_boot(x, scale = scale)

  td <- switch(filter,
    all         = td,
    significant = td[td$conf.low > 0 | td$conf.high < 0, ],
    selected    = td[td$selection_prob > 0.5, ]
  )

  if (nrow(td) == 0L) {
    return(ggplot2::ggplot() +
             ggplot2::theme_bw() +
             ggplot2::labs(title = paste0("No terms pass filter = '", filter, "'")))
  }

  td$term_ord <- stats::reorder(td$term, td$estimate)

  ggplot2::ggplot(td) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::geom_linerange(
      ggplot2::aes(xmin = conf.low, xmax = conf.high, y = term_ord,
                   color = selection_prob)
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = estimate, y = term_ord, color = selection_prob)
    ) +
    ggplot2::scale_color_viridis_c(limits = c(0, 1)) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Bootstrap coefficient estimate", y = NULL,
                  color = "Selection\nprobability")
}

#' Plot selection probabilities
#'
#' Produces a horizontal bar chart of selection probabilities for all
#' model terms, ordered by probability. A reference line marks the threshold.
#'
#' @param x An `lb_boot` object.
#' @param threshold Reference line at this selection probability. Default `0.5`.
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_plot_selection(boot)
#' }
#' @export
lb_plot_selection <- function(x, threshold = 0.5, ...) {
  td       <- tidy.lb_boot(x)
  td$above <- td$selection_prob >= threshold

  ggplot2::ggplot(td,
    ggplot2::aes(x = selection_prob,
                 y = stats::reorder(term, selection_prob),
                 fill = above)) +
    ggplot2::geom_col() +
    ggplot2::geom_vline(xintercept = threshold, linetype = "dashed") +
    ggplot2::scale_x_continuous(limits = c(0, 1)) +
    ggplot2::scale_fill_manual(values = c("FALSE" = "grey60", "TRUE" = "#21908C"),
                               guide = "none") +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Selection probability", y = NULL)
}

#' Plot stability trajectories (selection probability vs. lambda)
#'
#' Shows how each term's selection probability varies across the regularization
#' path. Requires `store_path = TRUE` in [lb_control()].
#'
#' @param x An `lb_boot` object. Requires `store_path = TRUE`.
#' @param top_n Number of terms to show ranked by max selection probability.
#'   Default `20`.
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_plot_stability(boot)
#' }
#' @export
lb_plot_stability <- function(x, top_n = 20, ...) {
  if (!inherits(x, "lb_boot")) {
    cli::cli_abort("{.arg x} must be an {.cls lb_boot} object.")
  }
  if (is.null(x$path_coefs)) {
    cli::cli_abort(c(
      "Stability trajectory plot requires the full coefficient path.",
      "i" = "Re-run {.fn lb_bootstrap} with {.code lb_control(store_path = TRUE)}."
    ))
  }

  sel_mat    <- .path_sel_mat(x$path_coefs, x$B)
  lambda_seq <- x$fit$lambda_path

  row_maxes  <- matrixStats::rowMaxs(sel_mat)
  n_show     <- min(as.integer(top_n), nrow(sel_mat))
  top_terms  <- names(sort(row_maxes, decreasing = TRUE))[seq_len(n_show)]

  long_df <- do.call(rbind, lapply(top_terms, function(tm) {
    tibble::tibble(
      term     = tm,
      lambda   = lambda_seq,
      sel_prob = sel_mat[tm, ]
    )
  }))

  ggplot2::ggplot(long_df,
    ggplot2::aes(x = log(lambda), y = sel_prob,
                 color = term, group = term)) +
    ggplot2::geom_line() +
    ggplot2::geom_hline(yintercept = 0.5, linetype = "dashed", color = "grey40") +
    ggplot2::scale_color_viridis_d(option = "turbo") +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "log(lambda)", y = "Selection probability", color = NULL)
}

#' Plot interaction effects as a heatmap
#'
#' Displays second-order interaction term estimates from the bootstrap as a
#' symmetric tile heatmap. Returns a blank plot with an informative title if
#' the model contains no interaction terms.
#'
#' @param x An `lb_boot` object.
#' @param order Interaction order to display. Default `2L` (pairwise).
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_plot_interactions(boot)
#' }
#' @export
lb_plot_interactions <- function(x, order = 2L, ...) {
  td   <- tidy.lb_boot(x)
  iact <- td[grepl(":", td$term, fixed = TRUE), ]

  if (nrow(iact) == 0L) {
    return(
      ggplot2::ggplot() +
        ggplot2::theme_bw() +
        ggplot2::labs(title = "No interaction terms found")
    )
  }

  heatmap_data <- do.call(rbind, lapply(seq_len(nrow(iact)), function(i) {
    parts <- strsplit(iact$term[i], ":", fixed = TRUE)[[1L]]
    if (length(parts) != 2L) return(NULL)
    tibble::tibble(
      var1           = c(parts[1L], parts[2L]),
      var2           = c(parts[2L], parts[1L]),
      estimate       = iact$estimate[i],
      selection_prob = iact$selection_prob[i]
    )
  }))

  lim <- max(abs(c(min(heatmap_data$estimate, na.rm = TRUE),
                   max(heatmap_data$estimate, na.rm = TRUE))),
             na.rm = TRUE)

  ggplot2::ggplot(heatmap_data,
    ggplot2::aes(x = var1, y = var2, fill = estimate)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_distiller(palette = "BrBG",
                                   limits = c(-lim, lim),
                                   oob    = scales::squish) +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(x = NULL, y = NULL, fill = "Coefficient\nestimate")
}

#' Plot a prediction ribbon for a focal predictor
#'
#' Wraps [lb_grid()] (with `at = "median"` by default) and
#' [predict.lb_boot()] to produce a ribbon plot of `.fitted` +/- interval
#' vs. the focal predictor. Non-focal predictors are held at their median.
#'
#' Users wanting per-combination ribbons (e.g. one ribbon per observed mixture)
#' should call [lb_grid()] directly with `at = "observed"` and build the
#' ggplot manually.
#'
#' @param x An `lb_boot` object.
#' @param focal Name of the focal predictor (string). Must be a column in the
#'   original data.
#' @param by A `vars()` expression for faceting (e.g. `vars(clay)`), or
#'   `NULL`. Default `NULL`.
#' @param raw_data A data frame to overlay as points, or `NULL`. Default
#'   `NULL`. Must contain both `focal` and the response variable.
#' @param ... Passed to [lb_grid()].
#'
#' @return A `ggplot` object.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_plot_prediction(boot, focal = "x1")
#' }
#' @export
lb_plot_prediction <- function(x, focal, by = NULL, raw_data = NULL, ...) {
  if (!inherits(x, "lb_boot")) {
    cli::cli_abort("{.arg x} must be an {.cls lb_boot} object.")
  }

  dots <- list(...)
  if (!"at" %in% names(dots)) {
    dots[["at"]] <- "median"
  }
  grid_data <- do.call(lb_grid, c(list(boot = x, focal = focal), dots))

  response_var <- all.vars(x$fit$spec$formula[[2L]])

  p <- ggplot2::ggplot(grid_data, ggplot2::aes(x = .data[[focal]])) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .lower, ymax = .upper), alpha = 0.3
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .fitted)) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = focal, y = response_var)

  if (!is.null(by)) {
    p <- p + ggplot2::facet_wrap(by)
  }

  if (!is.null(raw_data)) {
    p <- p + ggplot2::geom_point(
      data    = raw_data,
      mapping = ggplot2::aes(x = .data[[focal]], y = .data[[response_var]]),
      alpha   = 0.6
    )
  }

  p
}

#' Plot model complexity (number of selected terms) across bootstrap iterations
#'
#' Displays the distribution of how many predictors were selected in each
#' bootstrap iteration. A dashed vertical line marks the mean.
#'
#' @param x An `lb_boot` object.
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_plot_complexity(boot)
#' }
#' @export
lb_plot_complexity <- function(x, ...) {
  n_sel_per_iter <- tabulate(x$coef_tbl$iteration, nbins = x$B)
  df             <- tibble::tibble(n_selected = as.integer(n_sel_per_iter))
  mean_sel       <- mean(n_sel_per_iter)

  ggplot2::ggplot(df, ggplot2::aes(x = n_selected)) +
    ggplot2::geom_histogram(binwidth = 1, fill = "steelblue", color = "white") +
    ggplot2::geom_vline(xintercept = mean_sel, linetype = "dashed") +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Number of selected predictors", y = "Count")
}
