# Capture a derived-variable expression for re-evaluation in the bootstrap loop

Derived quantities (e.g. `volume = mass / density`) must be recomputed
*after* uncertainty injection and constraint clipping so that
measurement error propagates correctly through the derived value.

## Usage

``` r
lb_derive(...)
```

## Arguments

- ...:

  A single named expression `lhs = rhs`. `lhs` is the column name to
  create or overwrite in the perturbed data frame; `rhs` is an
  expression evaluated via
  [`rlang::eval_tidy()`](https://rlang.r-lib.org/reference/eval_tidy.html)
  in the context of that data frame.

## Value

An `lb_derive` object (a classed list with `$name` and `$expr`).

## Details

Derives run in declaration order and may chain: a second derive may
reference a column produced by the first.

## Examples

``` r
# Derive volume from mass and density
lb_derive(volume = mass / density)
#> $name
#> [1] "volume"
#> 
#> $expr
#> <quosure>
#> expr: ^mass / density
#> env:  0x56265f675b60
#> 
#> attr(,"class")
#> [1] "lb_derive"

# Second derive can reference a column from the first
lb_derive(volume_total = volume_Alite + volume_Belite)
#> $name
#> [1] "volume_total"
#> 
#> $expr
#> <quosure>
#> expr: ^volume_Alite + volume_Belite
#> env:  0x56265f675b60
#> 
#> attr(,"class")
#> [1] "lb_derive"
```
