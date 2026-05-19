# Plot stability trajectories (selection probability vs. lambda)

Shows how each term's selection probability varies across the
regularization path. Requires `store_path = TRUE` in
[`lb_control()`](https://doctorbear-it.github.io/lassoboot/reference/lb_control.md).

## Usage

``` r
lb_plot_stability(x, top_n = 20, ...)
```

## Arguments

- x:

  An `lb_boot` object. Requires `store_path = TRUE`.

- top_n:

  Number of terms to show ranked by max selection probability. Default
  `20`.

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
lb_plot_stability(boot)

# }
```
