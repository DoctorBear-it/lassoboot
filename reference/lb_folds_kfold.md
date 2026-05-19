# Standard k-fold cross-validation fold generator

Standard k-fold cross-validation fold generator

## Usage

``` r
lb_folds_kfold(k = 10)
```

## Arguments

- k:

  Number of folds. Default `10`.

## Value

A fold-generator closure `function(data) -> integer vector` of fold IDs
the same length as `nrow(data)`.

## Examples

``` r
gen   <- lb_folds_kfold(k = 5)
folds <- gen(concrete)
table(folds)
#> folds
#>  1  2  3  4  5 
#> 15 15 15 15 15 
```
