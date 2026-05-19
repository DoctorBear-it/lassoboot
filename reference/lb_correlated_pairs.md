# Identify correlated predictor pairs with split selection probabilities

Detects the "lasso picked one of two correlated predictors at random"
pathology. Flags pairs where `cor > cor_threshold` in the original data
and the individual selection probabilities are split (neither clearly
dominant) while the joint either-one probability is high.

## Usage

``` r
lb_correlated_pairs(boot, cor_threshold = 0.7, prob_threshold = 0.5)
```

## Arguments

- boot:

  An `lb_boot` object.

- cor_threshold:

  Correlation threshold above which pairs are examined. Default `0.7`.

- prob_threshold:

  Individual selection probability threshold below which a term is
  considered "split". Default `0.5`.

## Value

A tibble of flagged pairs with columns `term_1`, `term_2`,
`correlation`, `prob_1`, `prob_2`, `prob_either`.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
lb_correlated_pairs(boot)
#> # A tibble: 0 × 6
#> # ℹ 6 variables: term_1 <chr>, term_2 <chr>, correlation <dbl>, prob_1 <dbl>,
#> #   prob_2 <dbl>, prob_either <dbl>
```
