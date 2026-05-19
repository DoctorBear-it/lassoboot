# Block fold generator

Treats each unique value of `block` as an indivisible unit and assigns
whole blocks to folds in their natural order (no shuffling), preserving
temporal or spatial ordering.

## Usage

``` r
lb_folds_blocked(block, k = 5)
```

## Arguments

- block:

  Column name (string) defining contiguous blocks assigned as complete
  units to folds.

- k:

  Number of folds. Default `5`.

## Value

A fold-generator closure `function(data) -> integer vector`.

## Examples

``` r
gen   <- lb_folds_blocked("mixture", k = 5)
folds <- gen(concrete)
table(folds)
#> folds
#>  1  2  3  4  5 
#> 15 15 15 15 15 
```
