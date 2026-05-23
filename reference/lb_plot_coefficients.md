# Plot bootstrap coefficient distribution with quantile intervals

Produces a horizontal forest plot of bootstrap coefficient means and
quantile intervals, ordered by point estimate. Color encodes selection
probability.

## Usage

``` r
lb_plot_coefficients(
  x,
  scale = c("raw", "gelman"),
  filter = c("all", "quantiles_exclude_zero", "selected", "significant"),
  ...
)
```

## Arguments

- x:

  An `lb_boot` object.

- scale:

  `"raw"` (default) or `"gelman"` (2-SD scaling per Gelman 2008).

- filter:

  `"all"` (default), `"quantiles_exclude_zero"` (95% quantile interval
  excludes zero), or `"selected"` (selection_prob \> 0.5). The
  deprecated value `"significant"` is an alias for
  `"quantiles_exclude_zero"` and emits a one-time warning.

- ...:

  Unused.

## Value

A `ggplot` object.

## Examples

``` r
# \donttest{
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
lb_plot_coefficients(boot)

# }
```
