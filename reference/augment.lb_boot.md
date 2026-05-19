# Augment data with bootstrap fitted values and prediction intervals

Returns the data (training or new) augmented with `.fitted`, `.lower`,
and `.upper` columns from the bootstrap coefficient distribution at
`level` confidence.

## Usage

``` r
# S3 method for class 'lb_boot'
augment(x, newdata = NULL, level = 0.95, ...)
```

## Arguments

- x:

  An `lb_boot` object.

- newdata:

  A data frame for out-of-sample augmentation, or `NULL` to use training
  data. Default `NULL`.

- level:

  Confidence level for the prediction interval. Default `0.95`.

- ...:

  Unused; for S3 compatibility.

## Value

The (new)data tibble augmented with `.fitted`, `.lower`, `.upper`.

## Examples

``` r
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
augment(boot)
#> # A tibble: 40 × 7
#>        x1     x2     x3      y .fitted  .lower .upper
#>     <dbl>  <dbl>  <dbl>  <dbl>   <dbl>   <dbl>  <dbl>
#>  1 -0.626 -0.165 -0.569 -1.76   -1.76  -2.03   -1.46 
#>  2  0.184 -0.253 -0.135  1.71    0.195  0.0564  0.501
#>  3 -0.836  0.697  1.18  -1.89   -2.33  -2.70   -1.88 
#>  4  1.60   0.557 -1.52   3.01    2.57   1.81    3.43 
#>  5  0.330 -0.689  0.594  0.559   0.931  0.643   1.10 
#>  6 -0.820 -0.707  0.333 -0.928  -1.68  -2.01   -1.50 
#>  7  0.487  0.365  1.06   0.901   0.783  0.513   1.09 
#>  8  0.738  0.769 -0.304  1.44    0.810  0.565   1.31 
#>  9  0.576 -0.112  0.370  0.470   1.10   0.851   1.37 
#> 10 -0.305  0.881  0.267 -0.935  -1.46  -1.70   -1.19 
#> # ℹ 30 more rows
```
