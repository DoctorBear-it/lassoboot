# Construct a measurement uncertainty specification

Builds a tidy tibble declaring the measurement uncertainty on predictor
columns. Use the helper constructors `std()`,
[`cov()`](https://rdrr.io/r/stats/cor.html), and `rel()` as values
inside the call.

## Usage

``` r
lb_uncertainty(...)
```

## Arguments

- ...:

  Named arguments `column = std(value)`, `column = cov(value)`, or
  `column = rel(value)`. Alternatively, a single pre-built tibble with
  columns `term`, `type`, `value`, and optionally `source`.

## Value

A tibble with columns `term` (chr), `type` (chr: `"std"/"cov"/"rel"`),
`value` (dbl, \>= 0), `source` (chr).

## Details

### Helper constructors

Inside `lb_uncertainty(...)` calls, three short helpers are available:

- `std(value, source)` — absolute standard deviation in the units of the
  column.

- `cov(value, source)` — coefficient of variation as a **percentage**
  (`cov(4.0, ...)` means 4%, not 400%).

- `rel(value, source)` — relative standard deviation as a **fraction**
  (`rel(0.04, ...)` is equivalent to `cov(4.0, ...)`).

These helpers are **only available inside `lb_uncertainty()`** — they do
not appear in the package namespace and do not shadow
[`stats::cov()`](https://rdrr.io/r/stats/cor.html) or any other function
globally. Internally, `lb_uncertainty()` evaluates its arguments in a
child environment that defines `std`, `cov`, and `rel`; outside that
call, the names resolve normally.

## Examples

``` r
lb_uncertainty(
  alumina  = std(0.071, "ASTM C114"),
  SSA      = cov(0.56,  "Mfr certificate of analysis"),
  strength = cov(4.0,   "ASTM C109 §10.3 single-operator")
)
#> # A tibble: 3 × 4
#>   term     type  value source                         
#>   <chr>    <chr> <dbl> <chr>                          
#> 1 alumina  std   0.071 ASTM C114                      
#> 2 SSA      cov   0.56  Mfr certificate of analysis    
#> 3 strength cov   4     ASTM C109 §10.3 single-operator
```
