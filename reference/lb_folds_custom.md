# Custom fold generator

Custom fold generator

## Usage

``` r
lb_folds_custom(fn)
```

## Arguments

- fn:

  A function with signature `function(data) -> integer vector` of fold
  IDs the same length as `nrow(data)`, with values in `1:k` for some
  `k`. The function is responsible for any re-randomisation across CV
  repetitions (typically by not closing over a fixed state).

## Value

The input `fn`, validated and classed as an `lb_fold_generator`.

## Examples

``` r
gen   <- lb_folds_custom(function(data) sample(rep(1:5, length.out = nrow(data))))
folds <- gen(concrete)
table(folds)
#> folds
#>  1  2  3  4  5 
#> 15 15 15 15 15 
```
