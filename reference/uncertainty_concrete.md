# Measurement uncertainty specification for the concrete dataset

A tibble declaring the measurement uncertainties for the continuous
predictor and response columns in
[concrete](https://doctorbear-it.github.io/lassoboot/reference/concrete.md).
Pass directly to the `uncertainty` argument of
[`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md).

## Usage

``` r
uncertainty_concrete
```

## Format

A tibble with 5 rows and 4 variables:

- term:

  Character. Column name in
  [concrete](https://doctorbear-it.github.io/lassoboot/reference/concrete.md)
  the uncertainty applies to.

- type:

  Character. Uncertainty type: `"std"` (absolute standard deviation, in
  the units of `term`) or `"cov"` (coefficient of variation as a
  percentage).

- value:

  Numeric. Uncertainty magnitude.

- source:

  Character. Normative source documenting the uncertainty.

Declared uncertainties:

|              |          |           |             |
|--------------|----------|-----------|-------------|
| **Term**     | **Type** | **Value** | **Source**  |
| clayHOH      | std      | 3.2 J/g   | ASTM C1897  |
| alumina      | std      | 0.07 wt%  | ASTM C114   |
| SSA          | cov      | 5.5 %     | Mfr. CoA    |
| D50          | cov      | 4.0 %     | Laser diff. |
| strength_MPa | cov      | 3.0 %     | ASTM C109   |

## See also

[concrete](https://doctorbear-it.github.io/lassoboot/reference/concrete.md)
for the dataset these uncertainties describe.
