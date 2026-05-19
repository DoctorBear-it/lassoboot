# Fit an initial lasso model and select lambda

Builds the design matrix, runs (repeated) cross-validation to select
lambda, fits the final model via the spec's engine, and estimates the
residual standard error. The result is stored in an `lb_fit` object and
passed to
[`lb_bootstrap()`](https://doctorbear-it.github.io/lassoboot/reference/lb_bootstrap.md).

## Usage

``` r
lb_fit(spec)
```

## Arguments

- spec:

  An `lb_spec` object from
  [`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md).

## Value

An `lb_fit` object containing:

- `spec`: the parent `lb_spec` (stored in full; `lb_fit` is
  self-contained).

- `fit_obj`: the engine fit object at the selected lambda.

- `lambda`: selected lambda scalar.

- `lambda_path`: lambda grid from the last CV run (used in path storage
  during bootstrap; see `lb_control(store_path)`).

- `cv_results`: reduced named list from `engine$cv()` — `lambda.min`,
  `lambda.1se`, `lambda_path`, `cvm`. Not a full `cv.glmnet` object;
  [`glance()`](https://generics.r-lib.org/reference/glance.html) in
  Phase 4 uses this for fold_spec output.

- `sigma_hat`: residual SE scalar (method from `control$sigma_method`).

- `x`: original sparse design matrix (n x p). Stored here so the
  bootstrap loop can reuse it for generating y_star without rebuilding
  from spec\$data each iteration (O(n\*p) allocation saved per
  iteration).

- `y`: original response vector (length n). Companion to `x`.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
fit  <- lb_fit(spec)
fit$lambda
#> [1] 0.003794028
fit$sigma_hat
#> [1] 0.8929082
```
