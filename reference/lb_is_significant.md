# Test whether terms meet a significance criterion

A convenience predicate for use in
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).
Three complementary criteria: bootstrap CI exclusion of zero (`"ci"`),
selection probability threshold (`"selection"`), stability score
threshold (`"stability"`), or all three simultaneously (`"all"`).

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
# Construct a minimal tidy-style tibble to demonstrate the predicate
td <- data.frame(
  conf.low        = c(-0.5,  0.1, -0.2),
  conf.high       = c(-0.1,  0.8,  0.3),
  selection_prob  = c( 0.9,  0.7,  0.2),
  stability_score = c( 0.85, 0.65, 0.15)
)
lb_is_significant(td, method = "ci")
#> [1]  TRUE  TRUE FALSE
lb_is_significant(td, method = "selection", threshold = 0.6)
#> [1]  TRUE  TRUE FALSE
```
