# Test whether terms meet a significance criterion (deprecated)

**\[deprecated\]**

Deprecated in favour of
[`lb_filter_stable()`](https://doctorbear-it.github.io/lassoboot/reference/lb_filter_stable.md),
which uses more precise language and a more flexible argument structure.
`lb_is_significant()` still works but emits a one-time warning per
session.

## Usage

``` r
lb_is_significant(
  tidy_df,
  method = c("ci", "selection", "stability", "all"),
  threshold = 0.5
)
```

## Arguments

- tidy_df:

  A tibble from
  [`tidy.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/tidy.lb_boot.md).

- method:

  One of `"ci"`, `"selection"`, `"stability"`, or `"all"`.

- threshold:

  Probability threshold for `"selection"` and `"stability"` methods.
  Default `0.5`.

## Value

A logical vector the same length as `nrow(tidy_df)`.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 20)
td <- tidy(boot)
suppressWarnings(lb_is_significant(td, method = "selection", threshold = 0.5))
#> [1] TRUE TRUE TRUE
```
