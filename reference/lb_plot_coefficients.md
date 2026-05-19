# Plot bootstrap coefficient estimates with confidence intervals

Produces a horizontal forest plot of bootstrap coefficient estimates and
quantile intervals, ordered by point estimate. Color encodes selection
probability.

## Usage

``` r
lb_plot_coefficients(
  x,
  scale = c("raw", "gelman"),
  filter = c("all", "significant", "selected"),
  ...
)
```

## Arguments

- x:

  An `lb_boot` object.

- scale:

  `"raw"` (default) or `"gelman"` (2-SD scaling per Gelman 2008).

- filter:

  `"all"` (default), `"significant"` (CI excludes zero), or `"selected"`
  (selection_prob \> 0.5).

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
