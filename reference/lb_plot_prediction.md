# Plot a prediction ribbon for a focal predictor

Wraps
[`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md)
(with `at = "median"` by default) and
[`predict.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/predict.lb_boot.md)
to produce a ribbon plot of `.fitted` +/- interval vs. the focal
predictor. Non-focal predictors are held at their median.

## Usage

``` r
lb_plot_prediction(x, focal, by = NULL, raw_data = NULL, ...)
```

## Arguments

- x:

  An `lb_boot` object.

- focal:

  Name of the focal predictor (string). Must be a column in the original
  data.

- by:

  A `vars()` expression for faceting (e.g. `vars(clay)`), or `NULL`.
  Default `NULL`.

- raw_data:

  A data frame to overlay as points, or `NULL`. Default `NULL`. Must
  contain both `focal` and the response variable.

- ...:

  Passed to
  [`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md).

## Value

A `ggplot` object.

## Details

Users wanting per-combination ribbons (e.g. one ribbon per observed
mixture) should call
[`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md)
directly with `at = "observed"` and build the ggplot manually.

## Examples

``` r
# \donttest{
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
lb_plot_prediction(boot, focal = "x1")

# }
```
