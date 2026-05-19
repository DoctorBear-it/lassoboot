# Grouped k-fold fold generator (prevents within-group train/test leakage)

Assigns whole groups to the same fold so that no group's observations
appear in both training and test sets.

## Usage

``` r
lb_folds_grouped(group, k = 10)
```

## Arguments

- group:

  Column name (string) whose levels define groups.

- k:

  Number of folds. Default `10`.

## Value

A fold-generator closure `function(data) -> integer vector`.

## Examples

``` r
gen   <- lb_folds_grouped("mixture", k = 5)
folds <- gen(concrete)
# Each mixture's observations share the same fold
tapply(folds, concrete$mixture, unique)
#>  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 
#>  1  2  4  1  5  2  4  1  5  2  1  5  3  3  3  5  4  2  4  2  3  4  1  5  3 
```
