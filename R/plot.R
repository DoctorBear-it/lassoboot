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

#' Plot bootstrap coefficient distribution with quantile intervals
#'
#' Produces a horizontal forest plot of bootstrap coefficient means and
#' quantile intervals, ordered by point estimate. Color encodes selection
#' probability.
#'
#' @param x An `lb_boot` object.
#' @param scale `"raw"` (default) or `"gelman"` (2-SD scaling per Gelman 2008).
#' @param filter `"all"` (default), `"quantiles_exclude_zero"` (95% quantile
#'   interval excludes zero), or `"selected"` (selection_prob > 0.5). The
#'   deprecated value `"significant"` is an alias for `"quantiles_exclude_zero"`
#'   and emits a one-time warning.
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
                                  filter = c("all", "quantiles_exclude_zero",
                                             "selected", "significant"),
                                  ...) {
  scale  <- match.arg(scale)
  filter <- match.arg(filter)

  # Deprecated alias
  if (filter == "significant") {
    .warn_once(
      "coeff_filter_significant",
      c("{.code filter = \"significant\"} is deprecated.",
        "i" = "Use {.code filter = \"quantiles_exclude_zero\"} instead.")
    )
    filter <- "quantiles_exclude_zero"
  }

  td <- tidy.lb_boot(x, scale = scale)

  # Need the default q025/q975 columns — tidy() always includes them
  q_lo <- if ("q025" %in% names(td)) "q025" else names(td)[grepl("^q0", names(td))][1L]
  q_hi <- if ("q975" %in% names(td)) "q975" else names(td)[grepl("^q9", names(td))][1L]

  td <- switch(filter,
    all                   = td,
    quantiles_exclude_zero = td[td[[q_lo]] > 0 | td[[q_hi]] < 0, ],
    selected              = td[td$selection_prob > 0.5, ]
  )

  if (nrow(td) == 0L) {
    return(ggplot2::ggplot() +
             ggplot2::theme_bw() +
             ggplot2::labs(title = paste0("No terms pass filter = '", filter, "'")))
  }

  td$term_ord <- stats::reorder(td$term, td$mean)

  ggplot2::ggplot(td) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::geom_linerange(
      ggplot2::aes(xmin = .data[[q_lo]], xmax = .data[[q_hi]], y = term_ord,
                   color = selection_prob)
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = mean, y = term_ord, color = selection_prob)
    ) +
    ggplot2::scale_color_viridis_c(limits = c(0, 1)) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "Bootstrap coefficient (mean)", y = NULL,
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
      estimate       = iact$mean[i],
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

#' Flagship measurement-uncertainty-propagated prediction envelope plot
#'
#' Produces per-combination prediction ribbons over a focal predictor, with
#' optional faceting, raw data overlay, and horizontal reference lines. This is
#' the recommended visualization for communicating bootstrap results to an
#' applied audience.
#'
#' The user adds domain-specific binning columns to the prediction grid (returned
#' by [lb_grid()]) and to the raw data before calling this function; the function
#' does not guess what binning makes sense. Aesthetic overrides and additional
#' ggplot2 layers can be added to the returned object with `+`.
#'
#' @param boot An `lb_boot` object.
#' @param focal Name of the focal (x-axis) predictor (string). Passed to
#'   [lb_grid()].
#' @param group String column name to map to color, fill, and linetype
#'   aesthetics, or `NULL`. Typically a grouping variable such as a replacement
#'   level.
#' @param facet A `vars()` expression for faceting (e.g. `vars(Fineness,
#'   Alumina_Grade)`), or `NULL` for no faceting.
#' @param data A data frame to overlay as raw data points, or `NULL`. Must
#'   contain the `focal` column and the response variable.
#' @param hlines Numeric vector of y-values for horizontal reference lines, or
#'   `NULL`. The first value is drawn solid; subsequent values are dashed.
#'   Override with `hline_types`.
#' @param hline_types Character vector of ggplot2 linetype values, one per
#'   element of `hlines`. Default: first is `"solid"`, rest are `"dashed"`.
#' @param xlim Length-2 numeric or `NULL`. Passed to
#'   `ggplot2::coord_cartesian()`.
#' @param ylim Length-2 numeric or `NULL`. Passed to
#'   `ggplot2::coord_cartesian()`.
#' @param n Number of grid points along the focal axis. Passed to [lb_grid()].
#'   Default `100`.
#' @param alpha_ribbon Alpha for ribbon fill. Default `0.25`.
#' @param label_x X-axis label string, or `NULL` to use the focal column name.
#' @param label_y Y-axis label string, or `NULL` to use the response variable
#'   name from the formula.
#' @param interval One of `"confidence"` (default), `"prediction"`, or `"both"`.
#'   `"confidence"` shows where the model's mean function lives under
#'   measurement-uncertainty perturbation. `"prediction"` shows where a single
#'   new observation would land (confidence + residual scatter). `"both"` draws
#'   an outer prediction ribbon (low alpha) and an inner confidence ribbon
#'   (higher alpha) with the line on top.
#' @param ... Additional arguments passed to [lb_grid()] (e.g.
#'   `clip_to_observed`, `at`, `extrapolate`).
#'
#' @return A `ggplot` object. No side effects; add layers with `+`.
#' @examples
#' \donttest{
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_plot_envelopes(boot, focal = "x1")
#' }
#' @export
lb_plot_envelopes <- function(boot,
                               focal,
                               group        = NULL,
                               facet        = NULL,
                               data         = NULL,
                               hlines       = NULL,
                               hline_types  = NULL,
                               xlim         = NULL,
                               ylim         = NULL,
                               n            = 100L,
                               alpha_ribbon = 0.25,
                               label_x      = NULL,
                               label_y      = NULL,
                               interval     = c("confidence", "prediction", "both"),
                               ...) {
  if (!inherits(boot, "lb_boot")) {
    cli::cli_abort("{.arg boot} must be an {.cls lb_boot} object.")
  }
  interval <- match.arg(interval)

  # Axis labels
  response_var <- all.vars(boot$fit$spec$formula[[2L]])
  lx <- label_x %||% focal
  ly <- label_y %||% response_var

  # Build confidence grid (always needed for the line and as base grid)
  grid_conf <- lb_grid(boot, focal = focal, n = n,
                       interval = "confidence", ...)

  # Build prediction grid if needed
  if (interval %in% c("prediction", "both")) {
    grid_pred <- lb_grid(boot, focal = focal, n = n,
                         interval = "prediction", ...)
  }

  # Non-focal columns drive the group-interaction aesthetic (Amendment E).
  # These are every column in the grid except the focal, the response
  # statistics, and the group variable itself.
  non_focal_cols <- if (!is.null(group)) {
    setdiff(names(grid_conf), c(focal, ".fitted", ".lower", ".upper", group))
  } else {
    character(0L)
  }

  # Pre-compute an interaction factor so each unique (group × non-focal)
  # combination gets its own ribbon/line, while color/fill/linetype are
  # controlled by the group variable alone (for a legible legend).
  if (!is.null(group)) {
    make_grp_int <- function(df) {
      if (length(non_focal_cols) == 0L) {
        df[[group]]
      } else {
        do.call(interaction,
                c(list(df[[group]]),
                  lapply(non_focal_cols, function(nm) df[[nm]])))
      }
    }
    grid_conf[[".grp_int"]] <- make_grp_int(grid_conf)
    if (interval %in% c("prediction", "both")) {
      grid_pred[[".grp_int"]] <- make_grp_int(grid_pred)
    }
  }

  # Base ggplot: use confidence grid for structure
  p <- ggplot2::ggplot(
    grid_conf,
    ggplot2::aes(x = .data[[focal]])
  )

  # --- Group aesthetic helper ---
  make_group_aes <- function(extra = list()) {
    if (is.null(group)) {
      do.call(ggplot2::aes, extra)
    } else {
      do.call(ggplot2::aes, c(
        list(color    = rlang::sym(group),
             fill     = rlang::sym(group),
             linetype = rlang::sym(group),
             group    = rlang::sym(".grp_int")),
        extra
      ))
    }
  }

  # --- Ribbons ---
  if (interval == "both") {
    # Outer prediction ribbon (low alpha)
    p <- p + ggplot2::geom_ribbon(
      data    = grid_pred,
      mapping = make_group_aes(list(ymin = rlang::sym(".lower"),
                                    ymax = rlang::sym(".upper"))),
      alpha   = alpha_ribbon * 0.5,
      color   = NA
    )
    # Inner confidence ribbon (higher alpha)
    p <- p + ggplot2::geom_ribbon(
      mapping = make_group_aes(list(ymin = rlang::sym(".lower"),
                                    ymax = rlang::sym(".upper"))),
      alpha   = alpha_ribbon,
      color   = NA
    )
  } else if (interval == "prediction") {
    p <- p + ggplot2::geom_ribbon(
      data    = grid_pred,
      mapping = make_group_aes(list(ymin = rlang::sym(".lower"),
                                    ymax = rlang::sym(".upper"))),
      alpha   = alpha_ribbon,
      color   = NA
    )
  } else {
    # "confidence"
    p <- p + ggplot2::geom_ribbon(
      mapping = make_group_aes(list(ymin = rlang::sym(".lower"),
                                    ymax = rlang::sym(".upper"))),
      alpha   = alpha_ribbon,
      color   = NA
    )
  }

  # Mean prediction line (from confidence grid — same mean either way)
  p <- p + ggplot2::geom_line(
    mapping = make_group_aes(list(y = rlang::sym(".fitted"))),
    linewidth = 0.7
  )

  # --- Raw data overlay ---
  if (!is.null(data)) {
    raw_aes <- if (is.null(group)) {
      ggplot2::aes(x = .data[[focal]], y = .data[[response_var]])
    } else {
      ggplot2::aes(x = .data[[focal]], y = .data[[response_var]],
                   color = .data[[group]], shape = .data[[group]])
    }
    p <- p + ggplot2::geom_point(
      data         = data,
      mapping      = raw_aes,
      inherit.aes  = FALSE,
      alpha        = 0.7,
      size         = 1.5
    )
  }

  # --- Horizontal reference lines ---
  if (!is.null(hlines)) {
    n_hlines <- length(hlines)
    if (is.null(hline_types)) {
      hline_types <- c("solid", rep("dashed", max(0L, n_hlines - 1L)))
    }
    for (i in seq_len(n_hlines)) {
      p <- p + ggplot2::geom_hline(
        yintercept = hlines[i],
        linetype   = hline_types[i],
        color      = "grey30"
      )
    }
  }

  # --- Faceting ---
  if (!is.null(facet)) {
    p <- p + ggplot2::facet_grid(facet)
  }

  # --- Axis limits ---
  if (!is.null(xlim) || !is.null(ylim)) {
    p <- p + ggplot2::coord_cartesian(xlim = xlim, ylim = ylim)
  }

  p + ggplot2::theme_bw() +
    ggplot2::labs(x = lx, y = ly, color = group, fill = group, shape = group)
}
