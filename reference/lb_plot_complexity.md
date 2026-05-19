# Plot model complexity (number of selected terms) across bootstrap iterations

Displays the distribution of how many predictors were selected in each
bootstrap iteration. A dashed vertical line marks the mean.

## Usage

``` r
lb_plot_complexity(x, ...)
```

## Arguments

- x:

  An `lb_boot` object.

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
lb_plot_complexity(boot)

# }
```
