# Tidy bootstrap coefficients into a one-row-per-term tibble

Summarises the bootstrap distribution of the fitted-model coefficient
for each predictor. **These are not estimates of underlying parameters**
and the quantile columns are not confidence intervals in the frequentist
coverage sense. The bootstrap distribution describes how each
coefficient varies across data realizations consistent with the declared
measurement uncertainty.

## Usage

``` r
# S3 method for class 'lb_boot'
tidy(x, probs = c(0.025, 0.975), scale = c("raw", "gelman"), ...)
```

## Arguments

- x:

  An `lb_boot` object.

- probs:

  Numeric vector of quantile probabilities to report. Column names are
  `q` followed by `round(p * 1000)`, zero-padded to 3 digits (e.g.
  `probs = c(0.025, 0.975)` → columns `q025` and `q975`). Default
  `c(0.025, 0.975)`.

- scale:

  `"raw"` (default, original units) or `"gelman"` (2-SD scaling per
  Gelman 2008, placing all numeric predictors on a comparable axis).

- ...:

  Unused; for S3 compatibility.

## Value

A tibble with columns `term`, `mean`, `median`, `sd`, one column per
element of `probs` (`q025`, `q975`, etc.), `selection_prob`,
`n_selected`, `stability_score`. `(Intercept)` is dropped.

## Note

The quantile columns (`q025`, `q975`) are **not** classical confidence
intervals on the true parameter value. They are empirical quantiles of
the bootstrap coefficient distribution, zeros padded for unselected
iterations. Use `selection_prob` and `stability_score` as the primary
inferential outputs; treat these quantile columns as supplementary
indicators of effect-size stability across data realizations.

## Column descriptions

- `mean`, `median`, `sd`: central tendency and spread of the bootstrap
  coefficient distribution. Iterations where the predictor was not
  selected contribute a coefficient of zero to these summaries.

- `q025`, `q975` (and other user-specified quantile columns): empirical
  quantiles of the bootstrap coefficient distribution, named `q`
  followed by the probability × 1000 zero-padded to 3 digits.

- `selection_prob`: the fraction of bootstrap replicates in which this
  predictor was retained by the LASSO under measurement-uncertainty
  perturbation. **This is the primary inferential output.**

- `n_selected`: count of replicates in which the predictor was selected.

- `stability_score`: maximum selection probability along the LASSO
  regularization path.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
tidy(boot)
#> # A tibble: 3 × 9
#>   term    mean median    sd     q025   q975 selection_prob n_selected
#>   <chr>  <dbl>  <dbl> <dbl>    <dbl>  <dbl>          <dbl>      <int>
#> 1 x1     2.23   2.22  0.173  2.02     2.42             1            5
#> 2 x2    -0.573 -0.567 0.124 -0.753   -0.467            1            5
#> 3 x3     0.221  0.173 0.237  0.00942  0.578            0.8          4
#> # ℹ 1 more variable: stability_score <dbl>
tidy(boot, probs = c(0.05, 0.95))
#> # A tibble: 3 × 9
#>   term    mean median    sd    q050   q950 selection_prob n_selected
#>   <chr>  <dbl>  <dbl> <dbl>   <dbl>  <dbl>          <dbl>      <int>
#> 1 x1     2.23   2.22  0.173  2.03    2.42             1            5
#> 2 x2    -0.573 -0.567 0.124 -0.735  -0.467            1            5
#> 3 x3     0.221  0.173 0.237  0.0188  0.538            0.8          4
#> # ℹ 1 more variable: stability_score <dbl>
```
