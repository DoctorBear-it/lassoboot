# Specify per-column clipping constraints for bootstrap perturbation

Each named argument is a length-2 numeric vector `c(lower, upper)`
giving the allowable range for that column after uncertainty injection.
A column not listed receives an inferred default at
[`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md)
time: `c(0, Inf)` if all observed values are `>= 0`, otherwise
`c(-Inf, Inf)`.

## Usage

``` r
lb_constraints(...)
```

## Arguments

- ...:

  Named arguments of the form `column = c(lower, upper)`. Use
  `c(0, Inf)` for non-negative, `c(0, 100)` for weight percent,
  `c(-Inf, Inf)` to disable clipping for signed quantities.

## Value

An `lb_constraints` object (a named list of numeric length-2 vectors).

## Examples

``` r
lb_constraints(
  alumina  = c(0, 100),    # bounded weight percent
  SSA      = c(0, Inf),    # non-negative
  moisture = c(-Inf, Inf)  # signed, no clipping
)
#> $alumina
#> [1]   0 100
#> 
#> $SSA
#> [1]   0 Inf
#> 
#> $moisture
#> [1] -Inf  Inf
#> 
#> attr(,"class")
#> [1] "lb_constraints"
```
