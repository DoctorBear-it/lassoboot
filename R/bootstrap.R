#' Run the parametric bootstrap
#'
#' For each of `B` iterations: perturbs predictors using the declared
#' measurement uncertainty, applies constraints, re-evaluates derived
#' quantities, generates a parametric response from the original fit, refits
#' via the engine, and stores coefficients (and optionally the full path and
#' fit objects). Returns an `lb_boot` object.
#'
#' @param spec_or_fit An `lb_spec` or `lb_fit` object. When an `lb_spec` is
#'   supplied, [lb_fit()] is called first. Supplying an `lb_fit` skips that
#'   step and is useful for inspecting the initial fit before committing to a
#'   large bootstrap run.
#' @param B Number of bootstrap iterations. Default `1000`.
#' @param ... Additional arguments passed to the engine.
#'
#' @return An `lb_boot` object containing:
#'   - `fit`: the parent `lb_fit` (stored in full; `lb_boot` is self-contained).
#'   - `coef_tbl`: tibble of nonzero coefficients — columns `iteration` (int),
#'     `term` (chr), `estimate` (dbl). Zeros are dropped to save memory; a term
#'     absent from iteration `b` has an implicit coefficient of 0 in that
#'     iteration. `B` is stored separately for correct selection-probability
#'     computation in `tidy()`.
#'   - `B`: total number of iterations (not `max(coef_tbl$iteration)`, which
#'     would undercount if the last iteration selects no variables).
#'   - `path_coefs`: list of length `B` of sparse coefficient matrices
#'     `(p+1) x n_lambda`, or `NULL` when `control$store_path = FALSE`.
#'   - `models`: list of length `B` of engine fit objects, or `NULL` when
#'     `control$keep_models = FALSE`.
#'   - `seed_used`: integer seed used for this run (always set, even when
#'     `control$seed` was `NULL` — generated randomly then stored).
#'   - `elapsed_sec`: wall-clock seconds for the bootstrap loop.
#' @examples
#' set.seed(1)
#' n  <- 40
#' df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
#' df$y <- 2 * df$x1 + rnorm(n)
#' spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
#' boot <- lb_bootstrap(spec, B = 5)
#' print(boot)
#' @export
lb_bootstrap <- function(spec_or_fit, B = 1000, ...) {
  if (inherits(spec_or_fit, "lb_fit")) {
    fit <- spec_or_fit
  } else if (inherits(spec_or_fit, "lb_spec")) {
    fit <- lb_fit(spec_or_fit)
  } else {
    cli::cli_abort(
      c("{.arg spec_or_fit} must be an {.cls lb_spec} or {.cls lb_fit}.",
        "x" = "Got {.cls {class(spec_or_fit)}}.")
    )
  }

  if (!is.numeric(B) || length(B) != 1L || !is.finite(B) || B < 1L) {
    cli::cli_abort("{.arg B} must be a single positive integer; got {.val {B}}.")
  }
  B <- as.integer(B)

  control <- fit$spec$control
  engine  <- fit$spec$engine

  # Determine seed: use control$seed if set; otherwise generate a random one
  # and store it so every run is reproducible after the fact.
  seed_used <- control$seed %||% sample.int(.Machine$integer.max, 1L)

  # cli progress bar is not safe across furrr workers; disable under parallel.
  use_progress <- control$progress && !control$parallel
  if (control$parallel && control$progress) {
    cli::cli_inform(
      "i" = "Progress bar disabled under {.code parallel = TRUE} in this version."
    )
  }

  run_bootstrap <- function() {
    if (control$parallel) {
      if (!requireNamespace("furrr", quietly = TRUE)) {
        cli::cli_abort(c(
          "{.code parallel = TRUE} requires the {.pkg furrr} package.",
          "i" = 'Install with {.code install.packages("furrr")}.'
        ))
      }
      furrr::future_map(
        seq_len(B),
        function(b) .boot_iter(b, fit, engine, control),
        .options = furrr::furrr_options(seed = TRUE)
      )
    } else {
      if (use_progress) {
        cli::cli_progress_bar("Bootstrap", total = B)
      }
      results <- vector("list", B)
      for (b in seq_len(B)) {
        results[[b]] <- .boot_iter(b, fit, engine, control)
        if (use_progress) cli::cli_progress_update()
      }
      if (use_progress) cli::cli_progress_done()
      results
    }
  }

  t_start <- proc.time()[["elapsed"]]
  results  <- withr::with_seed(seed_used, run_bootstrap())
  elapsed_sec <- proc.time()[["elapsed"]] - t_start

  # Assemble tidy coef tibble: nonzero entries only, one row per (b, term)
  coef_tbl <- dplyr::bind_rows(
    lapply(seq_len(B), function(b) {
      coefs <- results[[b]]$coefs
      nz    <- coefs != 0
      if (!any(nz)) return(NULL)
      tibble::tibble(
        iteration = b,
        term      = names(coefs)[nz],
        estimate  = coefs[nz]
      )
    })
  )

  path_coefs <- if (control$store_path) lapply(results, `[[`, "path_coefs") else NULL
  models     <- if (control$keep_models) lapply(results, `[[`, "model") else NULL

  structure(
    list(
      fit         = fit,
      coef_tbl    = coef_tbl,
      B           = B,
      path_coefs  = path_coefs,
      models      = models,
      seed_used   = seed_used,
      elapsed_sec = elapsed_sec
    ),
    class = c("lb_boot", "lb_fit", "lb_spec")
  )
}

# Internal worker: one bootstrap iteration.
.boot_iter <- function(b, fit, engine, control) {
  spec <- fit$spec
  data <- spec$data

  # 1. Perturb predictors with declared measurement uncertainty
  data_b <- .apply_uncertainty(data, spec$uncertainty)

  # 2. Clip perturbed values to declared (or inferred) bounds
  data_b <- .apply_constraints(data_b, spec$constraints)

  # 3. Re-derive computed columns on perturbed-and-clipped data
  data_b <- .apply_derives(data_b, spec$derive, quiet = TRUE)

  # 4. Build perturbed design matrix
  dm_b <- .build_design_matrix(spec$formula, data_b)
  x_b  <- dm_b$x

  # 5. Generate parametric response from the *original* fit.
  # engine$predict defaults to fit$fit_obj$lambda[1L] — the scalar lambda
  # from lb_fit() — which is the correct reference point for the bootstrap.
  fitted_orig <- engine$predict(fit$fit_obj, newx = fit$x)
  y_star      <- fitted_orig + stats::rnorm(length(fit$y), 0, fit$sigma_hat)

  # 6. Select lambda for this iteration
  if (control$fix_lambda) {
    lambda_b <- fit$lambda
  } else {
    foldid_b <- spec$folds(data_b)
    cv_b     <- engine$cv(x_b, y_star,
                          foldid      = foldid_b,
                          nlambda     = control$n_lambda,
                          intercept   = control$intercept,
                          standardize = control$standardize)
    lambda_b <- cv_b$lambda.min
  }

  # 7. Refit on perturbed predictors with parametric response
  if (control$store_path) {
    # Fit the full initial-fit lambda path so stability diagnostics see a
    # consistent grid across all iterations.
    fit_b <- engine$fit(x_b, y_star,
                        lambda      = fit$lambda_path,
                        intercept   = control$intercept,
                        standardize = control$standardize)
    coefs_b      <- engine$coef(fit_b, s = lambda_b)
    # Full path: (p+1) x n_lambda sparse matrix; rows named by predictor.
    # engine$coef with vector s returns a raw dgCMatrix (CF#2).
    path_coefs_b <- engine$coef(fit_b, s = fit$lambda_path)
  } else {
    fit_b <- engine$fit(x_b, y_star,
                        lambda      = lambda_b,
                        intercept   = control$intercept,
                        standardize = control$standardize)
    coefs_b      <- engine$coef(fit_b, s = lambda_b)
    path_coefs_b <- NULL
  }

  model_b <- if (control$keep_models) fit_b else NULL

  list(coefs = coefs_b, path_coefs = path_coefs_b, model = model_b)
}

# Internal: perturb numeric predictor columns according to the uncertainty spec.
# Scale is computed from the *original* column value, not from the accumulating
# data, so repeated uncertainty rows targeting the same column do not drift.
.apply_uncertainty <- function(data, uncertainty) {
  if (is.null(uncertainty) || nrow(uncertainty) == 0L) return(data)

  n <- nrow(data)
  for (i in seq_len(nrow(uncertainty))) {
    term         <- uncertainty$term[i]
    type         <- uncertainty$type[i]
    value        <- uncertainty$value[i]
    original_col <- data[[term]]

    noise <- switch(type,
      std = stats::rnorm(n, 0, value),
      cov = stats::rnorm(n, 0, abs(original_col) * value / 100),
      rel = stats::rnorm(n, 0, abs(original_col) * value),
      cli::cli_abort("Unknown uncertainty type {.val {type}}.")
    )
    data[[term]] <- original_col + noise
  }
  data
}
