# Limestone calcined clay cement strength dataset

A synthetic dataset modelling the compressive strength of mortar cubes
produced with limestone calcined clay cement (LC3) blends. Four calcined
clay sources (CC0–CC3) are evaluated at five replacement levels and
three curing ages. Structure mirrors the `df_final` object from the
package's companion prototype analysis; sample identifiers are
anonymised to integers and supplier names removed.

## Usage

``` r
concrete
```

## Format

A tibble with 75 rows and 10 variables:

- mixture:

  Integer. Unique identifier for each cement replacement mixture (25
  unique values, one per clay × replacement combination).

- clay:

  Factor. Clay source identifier. Levels: `"CC0"`, `"CC1A"`, `"CC1B"`,
  `"CC2"`, `"CC3"`.

- replacement:

  Numeric. Cement replacement level (weight %, 10–30).

- clayHOH:

  Numeric. Clay heat of hydration measured by isothermal calorimetry
  (J/g), per ASTM C1897. A proxy for pozzolanic reactivity: higher
  values indicate greater reactivity.

- alumina:

  Numeric. Al\\\_2\\O\\\_3\\ content of the calcined clay (weight %),
  determined by X-ray fluorescence per ASTM C114.

- SSA:

  Numeric. Specific surface area of the calcined clay (m\\^2\\/g),
  measured by BET nitrogen adsorption.

- D50:

  Numeric. Median particle diameter (\\\mu\\m) from laser diffraction
  particle size analysis.

- strength_MPa:

  Numeric. Compressive strength of 50 mm mortar cubes (MPa), tested per
  ASTM C109.

- age:

  Factor. Curing age at which strength was measured. Levels: `"7d"`,
  `"28d"`, `"56d"`.

- wcm:

  Numeric. Water-to-cementitious-material ratio (fixed at 0.485 for all
  mixtures in this dataset).

## Source

Synthetic dataset constructed to represent realistic LC3 mortar strength
data. Clay mineralogical properties (clayHOH, alumina, SSA, D50) are
modelled on typical values reported in the literature for calcined
montmorillonite and kaolinite clays. Strength values are generated from
a semi-empirical age/pozzolanic-activity model with additive noise at
the ASTM C109 single-operator reproducibility level.

## Details

This dataset is designed to demonstrate `lassoboot`'s uncertainty-aware
lasso workflow for materials-science data. Typical use:

    spec <- lb_spec(
      strength_MPa ~ (clayHOH + log(clayHOH)) * replacement * alumina * SSA * D50,
      data        = concrete,
      uncertainty = uncertainty_concrete,
      folds       = lb_folds_grouped("mixture")
    )
    boot <- lb_bootstrap(spec, B = 500)
    tidy(boot)

## See also

[uncertainty_concrete](https://doctorbear-it.github.io/lassoboot/reference/uncertainty_concrete.md)
for the companion uncertainty specification.
