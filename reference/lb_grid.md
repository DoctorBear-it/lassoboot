# Build a prediction grid varying a focal predictor

Constructs a grid of `n` values along the focal predictor's range,
crossed with non-focal predictors fixed at their observed combinations
(default), medians, or user-supplied values. Passes the grid to
[`predict.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/predict.lb_boot.md)
and returns `.fitted`, `.lower`, `.upper`.

## Usage

``` r
lb_grid(
  boot,
  focal,
  n = 100,
  at = "observed",
  extrapolate = FALSE,
  clip_to_observed = NULL,
  interval = "confidence",
  level = 0.95
)
```

## Arguments

- boot:

  An `lb_boot` object.

- focal:

  Name of the focal (x-axis) predictor (string). Must be a column name
  in the original data, not a formula term.

- n:

  Number of grid points along the focal axis. Default `100`.

- at:

  How to set non-focal predictors: `"observed"` (default — all unique
  observed combinations), `"median"`, or a named list of values.

- extrapolate:

  Logical. Allow grid points outside the observed focal range? User must
  opt in. Default `FALSE`.

- clip_to_observed:

  Logical or `NULL`. When `NULL` (default), resolves to `TRUE` when
  `at = "observed"` and `FALSE` otherwise. When `TRUE`, clips the focal
  predictor range **per non-focal combination** to the range observed in
  the original data for rows matching that combination. This prevents
  the grid from showing predictions in regions where no measurements of
  that type were made. Ignored (with a warning) when `at = "median"` or
  `at` is a list.

- interval:

  One of `"confidence"` (default), `"prediction"`, or `"none"`. Passed
  to
  [`predict.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/predict.lb_boot.md).
  `"confidence"` returns the quantiles of the bootstrap fitted-mean
  distribution; `"prediction"` additionally incorporates residual
  scatter.

- level:

  Confidence/prediction level. Default `0.95`.

## Value

A tibble with the grid columns plus `.fitted` and, when
`interval != "none"`, `.lower` and `.upper`.

## Details

The grid is built in **raw-data column space** (the columns of
`spec$data`). Formula transformations such as `I(x^2)`, `log(x)`, and
interaction expansion are applied at predict-time via the formula.
`focal` must be a column name present in `spec$data`, not a formula term
like `"I(clayHOH^2)"`.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
lb_grid(boot, focal = "x1", n = 10, at = "median")
#> # A tibble: 10 × 6
#>         x1     x2      x3 .fitted .lower .upper
#>      <dbl>  <dbl>   <dbl>   <dbl>  <dbl>  <dbl>
#>  1 -2.21   0.0512 -0.0465  -5.31  -5.86  -4.92 
#>  2 -1.79   0.0512 -0.0465  -4.37  -4.84  -4.06 
#>  3 -1.37   0.0512 -0.0465  -3.42  -3.82  -3.20 
#>  4 -0.945  0.0512 -0.0465  -2.48  -2.80  -2.30 
#>  5 -0.521  0.0512 -0.0465  -1.53  -1.79  -1.31 
#>  6 -0.0980 0.0512 -0.0465  -0.588 -0.770 -0.315
#>  7  0.325  0.0512 -0.0465   0.356  0.216  0.685
#>  8  0.749  0.0512 -0.0465   1.30   1.07   1.68 
#>  9  1.17   0.0512 -0.0465   2.25   1.93   2.69 
#> 10  1.60   0.0512 -0.0465   3.19   2.79   3.70 
```
