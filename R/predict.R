#' Predict from a bootstrap lasso fit
#'
#' Reconstructs predictions from the stored coefficient matrix via direct
#' matrix multiplication (exact for Gaussian linear glmnet; the default fast
#' path). Does not require `keep_models = TRUE` for standard prediction.
#' The internal pipeline is matrix-based: no `nest()`/`unnest()` in the hot
#' path; summaries computed via `matrixStats::rowQuantiles`.
#'
#' @param object An `lb_boot` object.
#' @param newdata A data frame for out-of-sample prediction, or `NULL` to
#'   predict on training data. Default `NULL`.
#' @param type `"response"` (default) or `"coef"`.
#' @param interval One of `"none"` (default), `"confidence"`, or `"prediction"`.
#'   - `"confidence"`: quantiles of the bootstrap **fitted-mean** distribution
#'     — where the model's mean function lives given measurement-uncertainty
#'     perturbation. This is the headline scientific output for inferring
#'     relationships.
#'   - `"prediction"`: confidence band **plus** residual draws
#'     ε ~ N(0, σ̂²) — describes where a single new observation at X would land.
#'     Uses per-iteration σ̂ when available (stored in `boot$sigma_hats`);
#'     falls back to `boot$fit$sigma_hat` with a one-time informative message.
#'   - `"none"`: `.fitted` only.
#' @param level Confidence/prediction level. Default `0.95`.
#' @param B_sub Subsample this many bootstrap iterations for speed, or `NULL`
#'   to use all. Default `NULL`.
#' @param ... Unused; for S3 compatibility.
#'
#' @return A tibble with `.fitted` and, when `interval != "none"`, `.lower`
#'   and `.upper`.
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' predict(boot, interval = "confidence")
#' @export
predict.lb_boot <- function(object, newdata = NULL,
                             type = c("response", "coef"),
                             interval = c("none", "confidence", "prediction"),
                             level = 0.95,
                             B_sub = NULL, ...) {
  type     <- match.arg(type)
  interval <- match.arg(interval)

  if (type == "coef") {
    ct <- object$coef_tbl
    if (!is.null(B_sub)) {
      keep <- sample.int(object$B, min(as.integer(B_sub), object$B))
      ct   <- ct[ct$iteration %in% keep, , drop = FALSE]
    }
    return(ct)
  }

  # Build design matrix: reuse stored training matrix or derive from newdata.
  # For newdata, strip the response from the formula so model.frame() does not
  # require a response column that prediction grids won't have.
  if (is.null(newdata)) {
    X_new <- object$fit$x   # n x p sparse; .predict_matrix prepends intercept
  } else {
    pred_terms <- stats::delete.response(
      stats::terms(object$fit$spec$formula, data = object$fit$spec$data)
    )
    X_new <- .build_predictor_matrix(pred_terms, newdata)
  }

  # Coefficient matrix: B x (p+1), intercept in first column.
  # term_names must match the order engine$coef returns: intercept then predictors.
  term_names <- c("(Intercept)", colnames(object$fit$x))
  coef_mat   <- .coef_matrix(object$coef_tbl, object$B, term_names)   # B x (p+1)

  # Handle B_sub subsampling
  B_eff <- object$B
  if (!is.null(B_sub)) {
    B_sub    <- min(as.integer(B_sub), object$B)
    idx      <- sample.int(object$B, B_sub)
    coef_mat <- coef_mat[idx, , drop = FALSE]
    B_eff    <- B_sub
  }

  pred_mat <- .predict_matrix(X_new, coef_mat)   # n x B_eff

  if (interval == "none") {
    return(tibble::tibble(.fitted = matrixStats::rowMeans2(pred_mat)))
  }

  if (interval == "confidence") {
    return(tibble::as_tibble(.summarise_pred_matrix(pred_mat, level = level)))
  }

  # interval == "prediction": add per-iteration residual draws
  # Retrieve sigma_hats; fall back to the initial-fit sigma with a message.
  sigma_hats <- object$sigma_hats
  if (is.null(sigma_hats)) {
    cli::cli_inform(
      c("i" = "Per-iteration {.field sigma_hat} not found (older {.cls lb_boot}
               object). Using initial-fit {.field sigma_hat} for prediction bands.",
        "i" = "Re-run {.fn lb_bootstrap} to get per-iteration sigma values.")
    )
    sigma_hats <- rep(object$fit$sigma_hat, B_eff)
  } else if (!is.null(B_sub)) {
    sigma_hats <- sigma_hats[idx]
  }

  n_obs <- nrow(pred_mat)
  # Add ε_b ~ N(0, sigma_hat_b^2) to each column of pred_mat
  eps_mat <- matrix(
    stats::rnorm(n_obs * B_eff, mean = 0, sd = rep(sigma_hats, each = n_obs)),
    nrow = n_obs, ncol = B_eff
  )
  pred_mat_pi <- pred_mat + eps_mat

  tibble::as_tibble(.summarise_pred_matrix(pred_mat_pi, level = level))
}

#' Build a prediction grid varying a focal predictor
#'
#' Constructs a grid of `n` values along the focal predictor's range, crossed
#' with non-focal predictors fixed at their observed combinations (default),
#' medians, or user-supplied values. Passes the grid to [predict.lb_boot()] and
#' returns `.fitted`, `.lower`, `.upper`.
#'
#' The grid is built in **raw-data column space** (the columns of `spec$data`).
#' Formula transformations such as `I(x^2)`, `log(x)`, and interaction
#' expansion are applied at predict-time via the formula. `focal` must be a
#' column name present in `spec$data`, not a formula term like `"I(clayHOH^2)"`.
#'
#' @param boot An `lb_boot` object.
#' @param focal Name of the focal (x-axis) predictor (string). Must be a column
#'   name in the original data, not a formula term.
#' @param n Number of grid points along the focal axis. Default `100`.
#' @param at How to set non-focal predictors: `"observed"` (default — all
#'   unique observed combinations), `"median"`, or a named list of values.
#' @param extrapolate Logical. Allow grid points outside the observed focal
#'   range? User must opt in. Default `FALSE`.
#' @param clip_to_observed Logical or `NULL`. When `NULL` (default), resolves to
#'   `TRUE` when `at = "observed"` and `FALSE` otherwise. When `TRUE`, clips the
#'   focal predictor range **per non-focal combination** to the range observed in
#'   the original data for rows matching that combination. This prevents the grid
#'   from showing predictions in regions where no measurements of that type were
#'   made. Ignored (with a warning) when `at = "median"` or `at` is a list.
#' @param interval One of `"confidence"` (default), `"prediction"`, or `"none"`.
#'   Passed to [predict.lb_boot()]. `"confidence"` returns the quantiles of the
#'   bootstrap fitted-mean distribution; `"prediction"` additionally incorporates
#'   residual scatter.
#' @param level Confidence/prediction level. Default `0.95`.
#'
#' @return A tibble with the grid columns plus `.fitted` and, when
#'   `interval != "none"`, `.lower` and `.upper`.
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' lb_grid(boot, focal = "x1", n = 10, at = "median")
#' @export
lb_grid <- function(boot, focal, n = 100, at = "observed", extrapolate = FALSE,
                    clip_to_observed = NULL,
                    interval = "confidence", level = 0.95) {
  if (!inherits(boot, "lb_boot")) {
    cli::cli_abort("{.arg boot} must be an {.cls lb_boot} object.")
  }
  if (!is.character(focal) || length(focal) != 1L) {
    cli::cli_abort("{.arg focal} must be a single character string.")
  }

  data <- boot$fit$spec$data

  if (!focal %in% names(data)) {
    cli::cli_abort(c(
      "{.arg focal} {.val {focal}} not found in the original data.",
      "i" = "{.arg focal} must be a raw data column name, not a formula term.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }

  # Resolve clip_to_observed sentinel
  at_is_observed <- identical(at, "observed")
  if (is.null(clip_to_observed)) {
    clip_to_observed <- at_is_observed
  } else if (isTRUE(clip_to_observed) && !at_is_observed) {
    cli::cli_warn(
      c("{.arg clip_to_observed = TRUE} is ignored when {.arg at} is not
         {.val \"observed\"}.",
        "i" = "{.arg clip_to_observed} applies per-combination range clipping
               only when {.arg at = \"observed\"}.")
    )
    clip_to_observed <- FALSE
  }

  focal_vals <- data[[focal]]
  focal_min  <- min(focal_vals, na.rm = TRUE)
  focal_max  <- max(focal_vals, na.rm = TRUE)
  focal_seq  <- seq(focal_min, focal_max, length.out = as.integer(n))

  # Focal column as a 1-column tibble (avoids rlang injection)
  focal_df   <- tibble::as_tibble(stats::setNames(list(focal_seq), focal))

  # Exclude focal and the response variable from non-focal columns.
  # The response is in spec$data but is not a predictor grid dimension.
  formula      <- boot$fit$spec$formula
  response_var <- all.vars(formula[[2L]])   # handles log(y), I(y^2), etc.
  other_cols   <- setdiff(names(data), c(focal, response_var))

  if (is.list(at) && !is.character(at)) {
    missing_cols <- setdiff(other_cols, names(at))
    if (length(missing_cols) > 0L) {
      cli::cli_abort(c(
        "When {.arg at} is a named list, all non-focal columns must be supplied.",
        "x" = "Missing: {.val {missing_cols}}."
      ))
    }
    non_focal_df <- tibble::as_tibble(at[other_cols])
    grid_data    <- tidyr::crossing(focal_df, non_focal_df)

  } else if (identical(at, "median")) {
    non_focal_vals <- lapply(other_cols, function(nm) {
      xc <- data[[nm]]
      if (is.numeric(xc)) stats::median(xc, na.rm = TRUE)
      else {
        tbl      <- table(xc)
        modal_nm <- names(tbl)[which.max(tbl)]
        # Preserve factor class so model.frame() sees the right type.
        if (is.factor(xc)) factor(modal_nm, levels = levels(xc)) else modal_nm
      }
    })
    names(non_focal_vals) <- other_cols
    non_focal_df <- tibble::as_tibble(non_focal_vals)
    grid_data    <- tidyr::crossing(focal_df, non_focal_df)

  } else {
    # "observed": cross focal grid with all unique observed non-focal combinations
    unique_others <- unique(data[other_cols])
    grid_data     <- tidyr::crossing(focal_df, unique_others)

    if (!extrapolate) {
      grid_data <- grid_data[
        grid_data[[focal]] >= focal_min & grid_data[[focal]] <= focal_max, ,
        drop = FALSE
      ]
    }

    # Per-combination focal range clipping
    if (clip_to_observed && length(other_cols) > 0L) {
      # For each unique non-focal combination, find the observed focal range.
      # Use only factor/character/integer non-focal cols for the join key —
      # numeric non-focal cols from "at = observed" came directly from the data
      # so a direct match is exact.
      combo_limits <- dplyr::summarise(
        dplyr::group_by(data[, c(focal, other_cols), drop = FALSE],
                        dplyr::across(dplyr::all_of(other_cols))),
        .focal_min = min(.data[[focal]], na.rm = TRUE),
        .focal_max = max(.data[[focal]], na.rm = TRUE),
        .groups = "drop"
      )
      grid_data <- dplyr::left_join(grid_data, combo_limits, by = other_cols)
      grid_data <- grid_data[
        grid_data[[focal]] >= grid_data$.focal_min &
          grid_data[[focal]] <= grid_data$.focal_max, ,
        drop = FALSE
      ]
      grid_data$.focal_min <- NULL
      grid_data$.focal_max <- NULL
    }
  }

  preds <- predict.lb_boot(boot, newdata = grid_data,
                           interval = interval, level = level)
  dplyr::bind_cols(grid_data, preds)
}
