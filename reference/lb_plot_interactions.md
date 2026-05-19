# Plot interaction effects as a heatmap

Displays second-order interaction term estimates from the bootstrap as a
symmetric tile heatmap. Returns a blank plot with an informative title
if the model contains no interaction terms.

## Usage

``` r
lb_plot_interactions(x, order = 2L, ...)
```

## Arguments

- x:

  An `lb_boot` object.

- order:

  Interaction order to display. Default `2L` (pairwise).

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
lb_plot_interactions(boot)

# }
```
