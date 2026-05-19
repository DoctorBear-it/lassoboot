# Run the parametric bootstrap

For each of `B` iterations: perturbs predictors using the declared
measurement uncertainty, applies constraints, re-evaluates derived
quantities, generates a parametric response from the original fit,
refits via the engine, and stores coefficients (and optionally the full
path and fit objects). Returns an `lb_boot` object.

## Usage

``` r
lb_bootstrap(spec_or_fit, B = 1000, ...)
```

## Arguments

- spec_or_fit:

  An `lb_spec` or `lb_fit` object. When an `lb_spec` is supplied,
  [`lb_fit()`](https://doctorbear-it.github.io/lassoboot/reference/lb_fit.md)
  is called first. Supplying an `lb_fit` skips that step and is useful
  for inspecting the initial fit before committing to a large bootstrap
  run.

- B:

  Number of bootstrap iterations. Default `1000`.

- ...:

  Additional arguments passed to the engine.

## Value

An `lb_boot` object containing:

- `fit`: the parent `lb_fit` (stored in full; `lb_boot` is
  self-contained).

- `coef_tbl`: tibble of nonzero coefficients — columns `iteration`
  (int), `term` (chr), `estimate` (dbl). Zeros are dropped to save
  memory; a term absent from iteration `b` has an implicit coefficient
  of 0 in that iteration. `B` is stored separately for correct
  selection-probability computation in
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html).

- `B`: total number of iterations (not `max(coef_tbl$iteration)`, which
  would undercount if the last iteration selects no variables).

- `path_coefs`: list of length `B` of sparse coefficient matrices
  `(p+1) x n_lambda`, or `NULL` when `control$store_path = FALSE`.

- `models`: list of length `B` of engine fit objects, or `NULL` when
  `control$keep_models = FALSE`.

- `seed_used`: integer seed used for this run (always set, even when
  `control$seed` was `NULL` — generated randomly then stored).

- `elapsed_sec`: wall-clock seconds for the bootstrap loop.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
print(boot)
#> <lb_spec>
#>   formula:     y ~ x1 + x2 + x3
#>   data:        40 rows x 4 columns
#>   uncertainty: none
#>   derive:      none
#>   constraints: 3 column(s)
#>   engine:      lb_engine_glmnet
#>   control:     <lb_control: all defaults>
#> <lb_fit>
#>   lambda:      0.003794
#>   sigma_hat:   0.8929  (method: refit)
#> <lb_boot>
#>   B:           5 iterations
#>   elapsed:     0s
#>   path stored: TRUE
#>   models kept: FALSE 
```
