# Plot bootstrap lasso output

Dispatcher for all `lb_plot_*()` functions. Each type delegates to the
corresponding named function and returns a plain `ggplot` object (no
[`print()`](https://rdrr.io/r/base/print.html), no side effects). All
inherit data through
[`tidy.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/tidy.lb_boot.md)
so user-supplied filtering works identically.

## Usage

``` r
# S3 method for class 'lb_boot'
autoplot(
  object,
  type = c("coefficients", "selection", "stability", "interactions", "complexity",
    "prediction"),
  ...
)
```

## Arguments

- object:

  An `lb_boot` object.

- type:

  Plot type: `"coefficients"` (default), `"selection"`, `"stability"`,
  `"interactions"`, `"complexity"`, or `"prediction"`.

- ...:

  Passed to the underlying `lb_plot_*()` function. For
  `type = "prediction"`, `focal` (a column name string) must be supplied
  here.

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
autoplot(boot)

autoplot(boot, type = "selection")

# }
```
