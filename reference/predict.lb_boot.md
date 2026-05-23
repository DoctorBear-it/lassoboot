# Predict from a bootstrap lasso fit

Reconstructs predictions from the stored coefficient matrix via direct
matrix multiplication (exact for Gaussian linear glmnet; the default
fast path). Does not require `keep_models = TRUE` for standard
prediction. The internal pipeline is matrix-based: no
`nest()`/`unnest()` in the hot path; summaries computed via
[`matrixStats::rowQuantiles`](https://rdrr.io/pkg/matrixStats/man/rowQuantiles.html).

## Usage

``` r
# S3 method for class 'lb_boot'
predict(
  object,
  newdata = NULL,
  type = c("response", "coef"),
  interval = c("none", "confidence", "prediction"),
  level = 0.95,
  B_sub = NULL,
  ...
)
```

## Arguments

- object:

  An `lb_boot` object.

- newdata:

  A data frame for out-of-sample prediction, or `NULL` to predict on
  training data. Default `NULL`.

- type:

  `"response"` (default) or `"coef"`.

- interval:

  One of `"none"` (default), `"confidence"`, or `"prediction"`.

  - `"confidence"`: quantiles of the bootstrap **fitted-mean**
    distribution — where the model's mean function lives given
    measurement-uncertainty perturbation. This is the headline
    scientific output for inferring relationships.

  - `"prediction"`: confidence band **plus** residual draws ε ~ N(0, σ̂²)
    — describes where a single new observation at X would land. Uses
    per-iteration σ̂ when available (stored in `boot$sigma_hats`); falls
    back to `boot$fit$sigma_hat` with a one-time informative message.

  - `"none"`: `.fitted` only.

- level:

  Confidence/prediction level. Default `0.95`.

- B_sub:

  Subsample this many bootstrap iterations for speed, or `NULL` to use
  all. Default `NULL`.

- ...:

  Unused; for S3 compatibility.

## Value

A tibble with `.fitted` and, when `interval != "none"`, `.lower` and
`.upper`.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
predict(boot, interval = "confidence")
#> # A tibble: 40 × 3
#>    .fitted  .lower .upper
#>      <dbl>   <dbl>  <dbl>
#>  1  -1.76  -2.03   -1.46 
#>  2   0.195  0.0564  0.501
#>  3  -2.33  -2.70   -1.88 
#>  4   2.57   1.81    3.43 
#>  5   0.931  0.643   1.10 
#>  6  -1.68  -2.01   -1.50 
#>  7   0.783  0.513   1.09 
#>  8   0.810  0.565   1.31 
#>  9   1.10   0.851   1.37 
#> 10  -1.46  -1.70   -1.19 
#> # ℹ 30 more rows
```
