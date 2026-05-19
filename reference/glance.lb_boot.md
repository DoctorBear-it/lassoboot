# Model-level bootstrap summary

Model-level bootstrap summary

## Usage

``` r
# S3 method for class 'lb_boot'
glance(x, ...)
```

## Arguments

- x:

  An `lb_boot` object.

- ...:

  Unused; for S3 compatibility.

## Value

A one-row tibble: `n`, `B`, `lambda`, `lambda_mad`, `mean_n_selected`,
`sd_n_selected`, `dev_ratio`, `elapsed_sec`, `sigma_method`,
`fold_spec`. `lambda_mad` is `NA` when `fix_lambda = TRUE` (all
iterations share the same lambda; the MAD would be zero and is
uninformative).

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
glance(boot)
#> # A tibble: 1 × 10
#>       n     B  lambda lambda_mad mean_n_selected sd_n_selected dev_ratio
#>   <int> <int>   <dbl>      <dbl>           <dbl>         <dbl>     <dbl>
#> 1    40     5 0.00379         NA             3.8         0.447     0.836
#> # ℹ 3 more variables: elapsed_sec <dbl>, sigma_method <chr>, fold_spec <chr>
```
