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
  columns `term`, `type`, and either `value` (backfilled for
  single/multi) or `value_single` and `value_multi`.

## Value

A tibble with columns `term` (chr), `type` (chr: `"std"/"cov"/"rel"`),
`value_single` (dbl, \>= 0), `value_multi` (dbl, \>= 0), `source` (chr).

## Details

### Helper constructors

Inside `lb_uncertainty(...)` calls, three short helpers are available:

- `std(value, multi = NULL, source)` — absolute standard deviation in
  the units of the column. `value` is the single-operator (within-lab)
  precision; `multi` (optional) is the multi-laboratory reproducibility.

- `cov(value, multi = NULL, source)` — coefficient of variation as a
  **percentage** (`cov(4.0, ...)` means 4%, not 400%).

- `rel(value, multi = NULL, source)` — relative standard deviation as a
  **fraction** (`rel(0.04, ...)` is equivalent to `cov(4.0, ...)`).

These helpers are **only available inside `lb_uncertainty()`** — they do
not appear in the package namespace and do not shadow
[`stats::cov()`](https://rdrr.io/r/stats/cor.html) or any other function
globally. Internally, `lb_uncertainty()` evaluates its arguments in a
child environment that defines `std`, `cov`, and `rel`; outside that
call, the names resolve normally.

### Multi-laboratory precision

Supply the named `multi` argument to declare two precision levels:

    lb_uncertainty(
      alumina = std(0.071, multi = 0.213, source = "ASTM C114")
    )

Switch between levels with `lb_control(precision = "single")` (default)
or `lb_control(precision = "multi")`.

v0.1 calls like `std(0.071, "ASTM C114")` continue to work unchanged and
set `multi = single = 0.071`.

## Examples

``` r
# Single precision level (v0.1 compatible)
lb_uncertainty(
  alumina  = std(0.071, "ASTM C114"),
  SSA      = cov(0.56,  "Mfr certificate of analysis"),
  strength = cov(4.0,   "ASTM C109 single-operator")
)
#> # A tibble: 3 × 5
#>   term     type  value_single value_multi source                     
#>   <chr>    <chr>        <dbl>       <dbl> <chr>                      
#> 1 alumina  std          0.071       0.071 ASTM C114                  
#> 2 SSA      cov          0.56        0.56  Mfr certificate of analysis
#> 3 strength cov          4           4     ASTM C109 single-operator  

# Two precision levels (v0.2.0+)
lb_uncertainty(
  alumina  = std(0.071, multi = 0.213, source = "ASTM C114"),
  strength = cov(4.0,   multi = 7.8,   source = "ASTM C109")
)
#> # A tibble: 2 × 5
#>   term     type  value_single value_multi source   
#>   <chr>    <chr>        <dbl>       <dbl> <chr>    
#> 1 alumina  std          0.071       0.213 ASTM C114
#> 2 strength cov          4           7.8   ASTM C109
```
