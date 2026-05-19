# Compute stability-selection summaries for bootstrap output

Summarises each term's selection probability trajectory across the
lambda path: the maximum selection probability, the lambda value at
which that maximum is achieved, the lambda range over which selection
probability exceeds 0.5, and the count of lambda values above that
threshold.

## Usage

``` r
lb_stability(boot)
```

## Arguments

- boot:

  An `lb_boot` object.

## Value

A tibble with one row per non-intercept term:

- `term`: predictor name.

- `max_selection_prob`: maximum selection probability across all lambda
  values in the stored path.

- `lambda_at_max`: the lambda value where `max_selection_prob` is
  achieved.

- `lambda_range_low`: smallest lambda value at which selection
  probability exceeds 0.5, or `NA` if the term never reaches 0.5.

- `lambda_range_high`: largest lambda value at which selection
  probability exceeds 0.5, or `NA` if the term never reaches 0.5.

- `n_lambda_above_half`: number of lambda grid points at which selection
  probability exceeds 0.5.

## Details

When `store_path = FALSE` was used in
[`lb_control()`](https://doctorbear-it.github.io/lassoboot/reference/lb_control.md),
`path_coefs` is not available and `stability_score` falls back to the
point-lambda selection probability (same as `selection_prob` in
[`tidy.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/tidy.lb_boot.md)).

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
lb_stability(boot)
#> # A tibble: 3 × 6
#>   term  max_selection_prob lambda_at_max lambda_range_low lambda_range_high
#>   <chr>              <dbl>         <dbl>            <dbl>             <dbl>
#> 1 x1                   1          1.55             1.55             0.00379
#> 2 x2                   1          0.286            0.286            0.00379
#> 3 x3                   0.8        0.0437           0.0768           0.00379
#> # ℹ 1 more variable: n_lambda_above_half <int>
```
