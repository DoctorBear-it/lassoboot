#' Set tuning parameters for the bootstrap
#'
#' @param lambda Lambda selection method: `"repeated_cv"` (default), `"min"`,
#'   `"1se"`, or a single positive numeric value.
#' @param cv_folds Number of CV folds. Default `10L`.
#' @param cv_reps Number of repeated-CV repetitions (used when
#'   `lambda = "repeated_cv"`). Default `5L`.
#' @param fix_lambda Logical. Reuse the initial lambda in every bootstrap
#'   iteration? Default `TRUE`.
#' @param store_path Logical. Store the full coefficient path per iteration,
#'   enabling stability diagnostics? Default `TRUE`.
#' @param n_lambda Number of lambda values in the stored path. Passed as
#'   `nlambda` to the engine's `cv()` method. Default `50L`.
#' @param keep_models Logical. Store the engine fit object for every iteration?
#'   Off by default; only needed for per-model diagnostics. Default `FALSE`.
#' @param sigma_method Residual SE estimation method: `"refit"` (default —
#'   OLS on selected variables, closes the under-coverage gap from
#'   regularisation-shrunk residuals), `"naive"` (matches prototype, biased
#'   low under regularisation), or `"cv"` (out-of-fold, slow but most honest).
#' @param parallel Logical. Use `future`/`furrr` for parallelism? Errors
#'   helpfully if those packages are absent. Default `FALSE`.
#' @param progress Logical. Show a `cli`-style progress bar? Default
#'   `interactive()`.
#' @param seed Integer seed for reproducibility, or `NULL`. When `NULL`,
#'   [lb_bootstrap()] generates a random integer seed at invocation time via
#'   `sample.int(.Machine$integer.max, 1)` and stores it on the returned
#'   `lb_boot` object's `$seed` field. This makes every run reproducible after
#'   the fact even when no seed was explicitly set. When an integer is supplied,
#'   that exact seed is used and stored. The bootstrap runs under
#'   `withr::with_seed()`. Default `NULL`.
#' @param intercept Logical. Fit intercept? Passed to the engine. Default `TRUE`.
#' @param standardize Logical. Standardize predictors? Passed to the engine.
#'   Default `TRUE`.
#'
#' @return An `lb_control` object (a validated, classed list). The print method
#'   shows only non-default values; prints `<lb_control: all defaults>` when
#'   every argument is at its default.
#' @examples
#' # All defaults
#' lb_control()
#'
#' # Non-default: 3 folds, naive sigma, fixed seed
#' lb_control(cv_folds = 3L, sigma_method = "naive", seed = 42L)
#' @export
lb_control <- function(lambda = "repeated_cv",
                       cv_folds = 10L,
                       cv_reps = 5L,
                       fix_lambda = TRUE,
                       store_path = TRUE,
                       n_lambda = 50L,
                       keep_models = FALSE,
                       sigma_method = "refit",
                       parallel = FALSE,
                       progress = interactive(),
                       seed = NULL,
                       intercept = TRUE,
                       standardize = TRUE) {
  # --- validate lambda ---
  valid_lambda_chr <- c("repeated_cv", "min", "1se")
  if (is.character(lambda)) {
    if (length(lambda) != 1L || !lambda %in% valid_lambda_chr) {
      cli::cli_abort(
        c("{.arg lambda} must be one of {.val {valid_lambda_chr}} or a single
           positive numeric.",
          "x" = "Got {.val {lambda}}.")
      )
    }
  } else if (is.numeric(lambda)) {
    if (length(lambda) != 1L || !is.finite(lambda) || lambda <= 0) {
      cli::cli_abort(
        "{.arg lambda} must be a single positive finite number when numeric."
      )
    }
  } else {
    cli::cli_abort(
      "{.arg lambda} must be a string or a positive numeric; got {.cls {class(lambda)}}."
    )
  }

  # --- validate integer-ish scalars ---
  .check_count <- function(x, arg, min = 1L) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < min) {
      cli::cli_abort(
        "{.arg {arg}} must be a single integer >= {min}; got {.val {x}}."
      )
    }
  }
  .check_count(cv_folds, "cv_folds", min = 2L)  # 1-fold CV is undefined
  .check_count(cv_reps,  "cv_reps",  min = 1L)
  .check_count(n_lambda, "n_lambda", min = 1L)

  # --- validate logicals ---
  .check_lgl <- function(x, arg) {
    if (!is.logical(x) || length(x) != 1L || is.na(x)) {
      cli::cli_abort("{.arg {arg}} must be TRUE or FALSE; got {.val {x}}.")
    }
  }
  .check_lgl(fix_lambda,   "fix_lambda")
  .check_lgl(store_path,   "store_path")
  .check_lgl(keep_models,  "keep_models")
  .check_lgl(parallel,     "parallel")
  .check_lgl(progress,     "progress")
  .check_lgl(intercept,    "intercept")
  .check_lgl(standardize,  "standardize")

  # --- validate sigma_method ---
  valid_sigma <- c("refit", "naive", "cv")
  if (!is.character(sigma_method) || length(sigma_method) != 1L ||
        !sigma_method %in% valid_sigma) {
    cli::cli_abort(
      c("{.arg sigma_method} must be one of {.val {valid_sigma}}.",
        "x" = "Got {.val {sigma_method}}.")
    )
  }

  # --- validate seed ---
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed) ||
          seed != as.integer(seed)) {
      cli::cli_abort(
        "{.arg seed} must be a single integer or NULL; got {.val {seed}}."
      )
    }
    seed <- as.integer(seed)
  }

  structure(
    list(
      lambda      = lambda,
      cv_folds    = as.integer(cv_folds),
      cv_reps     = as.integer(cv_reps),
      fix_lambda  = fix_lambda,
      store_path  = store_path,
      n_lambda    = as.integer(n_lambda),
      keep_models = keep_models,
      sigma_method = sigma_method,
      parallel    = parallel,
      progress    = progress,
      seed        = seed,
      intercept   = intercept,
      standardize = standardize
    ),
    class = "lb_control"
  )
}

# Canonical defaults for comparison in print.lb_control().
.lb_control_defaults <- list(
  lambda       = "repeated_cv",
  cv_folds     = 10L,
  cv_reps      = 5L,
  fix_lambda   = TRUE,
  store_path   = TRUE,
  n_lambda     = 50L,
  keep_models  = FALSE,
  sigma_method = "refit",
  parallel     = FALSE,
  # progress omitted: it depends on interactive() at call time, not a fixed default
  seed         = NULL,
  intercept    = TRUE,
  standardize  = TRUE
)

#' @export
format.lb_control <- function(x, ...) {
  non_def <- Filter(
    function(nm) {
      if (!nm %in% names(.lb_control_defaults)) return(FALSE)
      def <- .lb_control_defaults[[nm]]
      val <- x[[nm]]
      # Use identical() so integer vs double doesn't create false positives
      !identical(val, def)
    },
    names(x)
  )
  # Exclude 'progress' from the non-default check (session-dependent)
  non_def <- setdiff(non_def, "progress")

  if (length(non_def) == 0L) {
    return("<lb_control: all defaults>")
  }
  lines <- vapply(non_def, function(nm) {
    paste0("  ", nm, " = ", deparse(x[[nm]], width.cutoff = 60L))
  }, character(1L))
  paste0("<lb_control>\n", paste(lines, collapse = "\n"))
}

#' @export
print.lb_control <- function(x, ...) {
  cat(format(x, ...), "\n")
  invisible(x)
}
