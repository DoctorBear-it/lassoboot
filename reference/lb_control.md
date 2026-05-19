# Set tuning parameters for the bootstrap

Set tuning parameters for the bootstrap

## Usage

``` r
lb_control(
  lambda = "repeated_cv",
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
  standardize = TRUE
)
```

## Arguments

- lambda:

  Lambda selection method: `"repeated_cv"` (default), `"min"`, `"1se"`,
  or a single positive numeric value.

- cv_folds:

  Number of CV folds. Default `10L`.

- cv_reps:

  Number of repeated-CV repetitions (used when
  `lambda = "repeated_cv"`). Default `5L`.

- fix_lambda:

  Logical. Reuse the initial lambda in every bootstrap iteration?
  Default `TRUE`.

- store_path:

  Logical. Store the full coefficient path per iteration, enabling
  stability diagnostics? Default `TRUE`.

- n_lambda:

  Number of lambda values in the stored path. Passed as `nlambda` to the
  engine's `cv()` method. Default `50L`.

- keep_models:

  Logical. Store the engine fit object for every iteration? Off by
  default; only needed for per-model diagnostics. Default `FALSE`.

- sigma_method:

  Residual SE estimation method: `"refit"` (default — OLS on selected
  variables, closes the under-coverage gap from regularisation-shrunk
  residuals), `"naive"` (matches prototype, biased low under
  regularisation), or `"cv"` (out-of-fold, slow but most honest).

- parallel:

  Logical. Use `future`/`furrr` for parallelism? Errors helpfully if
  those packages are absent. Default `FALSE`.

- progress:

  Logical. Show a `cli`-style progress bar? Default
  [`interactive()`](https://rdrr.io/r/base/interactive.html).

- seed:

  Integer seed for reproducibility, or `NULL`. When `NULL`,
  [`lb_bootstrap()`](https://doctorbear-it.github.io/lassoboot/reference/lb_bootstrap.md)
  generates a random integer seed at invocation time via
  `sample.int(.Machine$integer.max, 1)` and stores it on the returned
  `lb_boot` object's `$seed` field. This makes every run reproducible
  after the fact even when no seed was explicitly set. When an integer
  is supplied, that exact seed is used and stored. The bootstrap runs
  under
  [`withr::with_seed()`](https://withr.r-lib.org/reference/with_seed.html).
  Default `NULL`.

- intercept:

  Logical. Fit intercept? Passed to the engine. Default `TRUE`.

- standardize:

  Logical. Standardize predictors? Passed to the engine. Default `TRUE`.

## Value

An `lb_control` object (a validated, classed list). The print method
shows only non-default values; prints `<lb_control: all defaults>` when
every argument is at its default.

## Examples

``` r
# All defaults
lb_control()
#> <lb_control: all defaults> 

# Non-default: 3 folds, naive sigma, fixed seed
lb_control(cv_folds = 3L, sigma_method = "naive", seed = 42L)
#> <lb_control>
#>   cv_folds = 3L
#>   sigma_method = "naive"
#>   seed = 42L 
```
