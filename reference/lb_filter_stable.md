# Filter tidy bootstrap output on stability criteria

A convenience predicate for use inside
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).
Applies one or more stability criteria to a tibble from
[`tidy.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/tidy.lb_boot.md).
Unlike the deprecated
[`lb_is_significant()`](https://doctorbear-it.github.io/lassoboot/reference/lb_is_significant.md),
each criterion is an independent named argument that can be combined in
any combination.

## Usage

``` r
lb_filter_stable(
  tidy_df,
  min_selection_prob = NULL,
  min_stability_score = NULL,
  quantiles_exclude_zero = FALSE
)
```

## Arguments

- tidy_df:

  A tibble from
  [`tidy.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/tidy.lb_boot.md).

- min_selection_prob:

  Minimum selection probability threshold. Rows with
  `selection_prob < min_selection_prob` are excluded. Default `NULL` (no
  filter on this criterion).

- min_stability_score:

  Minimum stability score threshold. Rows with
  `stability_score < min_stability_score` are excluded. Default `NULL`
  (no filter on this criterion).

- quantiles_exclude_zero:

  Logical. If `TRUE`, exclude rows where the default 95 % quantile
  interval (`q025` to `q975`) does not exclude zero (i.e. rows where
  `q025 <= 0` AND `q975 >= 0`). Default `FALSE`.

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
# Keep only terms selected in the majority of replicates
td[lb_filter_stable(td, min_selection_prob = 0.5), ]
#> # A tibble: 3 × 9
#>   term    mean median    sd    q025   q975 selection_prob n_selected
#>   <chr>  <dbl>  <dbl> <dbl>   <dbl>  <dbl>          <dbl>      <int>
#> 1 x1     2.23   2.21  0.174  1.98    2.52             1           20
#> 2 x2    -0.401 -0.404 0.149 -0.685  -0.213            1           20
#> 3 x3     0.156  0.119 0.153 -0.0206  0.473            0.9         18
#> # ℹ 1 more variable: stability_score <dbl>
# Combine criteria
td[lb_filter_stable(td, min_selection_prob = 0.5, min_stability_score = 0.4), ]
#> # A tibble: 3 × 9
#>   term    mean median    sd    q025   q975 selection_prob n_selected
#>   <chr>  <dbl>  <dbl> <dbl>   <dbl>  <dbl>          <dbl>      <int>
#> 1 x1     2.23   2.21  0.174  1.98    2.52             1           20
#> 2 x2    -0.401 -0.404 0.149 -0.685  -0.213            1           20
#> 3 x3     0.156  0.119 0.153 -0.0206  0.473            0.9         18
#> # ℹ 1 more variable: stability_score <dbl>
```
