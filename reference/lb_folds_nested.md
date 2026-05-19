# Nested fold generator with outer grouping and optional inner stratification

Places whole outer groups in the same fold (no leakage of group identity
across train/test) and, when `inner` is supplied, stratifies the
assignment of outer groups to folds so each fold sees a balanced
distribution of the inner variable.

## Usage

``` r
lb_folds_nested(outer, inner = NULL, k_outer = 5, k_inner = NULL)
```

## Arguments

- outer:

  Column name (string) defining the outer grouping (no leakage).

- inner:

  Column name (string) for inner stratification within each fold, or
  `NULL`. Default `NULL`.

- k_outer:

  Number of outer folds. Default `5`.

- k_inner:

  Reserved for future sub-folding; must be `NULL` in v0.1.

## Value

A fold-generator closure `function(data) -> integer vector`.

## Examples

``` r
# Each mixture has exactly one clay type, so inner stratification works
gen   <- lb_folds_nested(outer = "mixture", inner = "clay", k_outer = 5)
folds <- gen(concrete)
table(folds)
#> folds
#>  1  2  3  4  5 
#> 15 15 15 15 15 
```
