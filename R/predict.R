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
#' @param interval `"none"` (default) or `"confidence"`.
#' @param level Confidence level. Default `0.95`.
#' @param B_sub Subsample this many bootstrap iterations for speed, or `NULL`
#'   to use all. Default `NULL`.
#' @param ... Unused; for S3 compatibility.
#'
#' @return A tibble with `.fitted` and, if `interval = "confidence"`, `.lower`
#'   and `.upper`.
#' @export
predict.lb_boot <- function(object, newdata = NULL,
                             type = c("response", "coef"),
                             interval = c("none", "confidence"),
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

  if (!is.null(B_sub)) {
    B_sub    <- min(as.integer(B_sub), object$B)
    idx      <- sample.int(object$B, B_sub)
    coef_mat <- coef_mat[idx, , drop = FALSE]
  }

  pred_mat <- .predict_matrix(X_new, coef_mat)   # n x B (or n x B_sub)

  if (interval == "none") {
    tibble::tibble(.fitted = matrixStats::rowMeans2(pred_mat))
  } else {
    tibble::as_tibble(.summarise_pred_matrix(pred_mat, level = level))
  }
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
#'
#' @return A tibble with the grid columns plus `.fitted`, `.lower`, `.upper`.
#' @export
lb_grid <- function(boot, focal, n = 100, at = "observed", extrapolate = FALSE) {
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
        tbl <- table(xc)
        names(tbl)[which.max(tbl)]
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
  }

  preds <- predict.lb_boot(boot, newdata = grid_data, interval = "confidence")
  dplyr::bind_cols(grid_data, preds)
}
