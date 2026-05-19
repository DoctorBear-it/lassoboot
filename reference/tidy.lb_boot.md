# Tidy bootstrap coefficients into a one-row-per-term tibble

Tidy bootstrap coefficients into a one-row-per-term tibble

## Usage

``` r
# S3 method for class 'lb_boot'
tidy(x, conf.level = 0.95, scale = c("raw", "gelman"), ...)
```

## Arguments

- x:

  An `lb_boot` object.

- conf.level:

  Confidence level for the bootstrap quantile interval. Default `0.95`.

- scale:

  `"raw"` (default, original units) or `"gelman"` (2-SD scaling per
  Gelman 2008, placing all numeric predictors on a comparable axis).

- ...:

  Unused; for S3 compatibility.

## Value

A tibble with columns: `term`, `estimate` (bootstrap mean over all B
iterations, zeros included), `estimate_median`, `std.error`, `conf.low`,
`conf.high`, `selection_prob`, `n_selected`, `stability_score`.
`(Intercept)` is dropped.

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
#>   term  estimate estimate_median std.error conf.low conf.high selection_prob
#>   <chr>    <dbl>           <dbl>     <dbl>    <dbl>     <dbl>          <dbl>
#> 1 x1       2.23            2.22      0.173  2.02        2.42             1  
#> 2 x2      -0.573          -0.567     0.124 -0.753      -0.467            1  
#> 3 x3       0.221           0.173     0.237  0.00942     0.578            0.8
#> # ℹ 2 more variables: n_selected <int>, stability_score <dbl>
```
