# Plot selection probabilities

Produces a horizontal bar chart of selection probabilities for all model
terms, ordered by probability. A reference line marks the threshold.

## Usage

``` r
lb_plot_selection(x, threshold = 0.5, ...)
```

## Arguments

- x:

  An `lb_boot` object.

- threshold:

  Reference line at this selection probability. Default `0.5`.

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
lb_plot_selection(boot)

# }
```
