# Normalize a response by a reference strength

A convenience wrapper for the pattern `response = measured / reference`,
where both `measured` and `reference` carry their own measurement
uncertainty and are perturbed independently in each bootstrap iteration.

## Usage

``` r
lb_normalize(spec, response, measured, reference)
```

## Arguments

- spec:

  An `lb_spec` object.

- response:

  The column to create/overwrite as the normalized response (unquoted
  symbol). This column name replaces the LHS of the spec's formula.

- measured:

  The measured response column (unquoted symbol). Must exist in
  `spec$data` and be declared in `spec$uncertainty`.

- reference:

  The reference response column (unquoted symbol). Must exist in
  `spec$data` and be declared in `spec$uncertainty`.

## Value

An updated `lb_spec` object with the normalization registered as a
derived column and the response column materialized.

## Details

`lb_normalize()` operates on an already-constructed `lb_spec`. It
materializes the response column from `measured / reference` on
`spec$data` so the spec's formula is valid for the initial fit, then
registers an
[`lb_derive()`](https://doctorbear-it.github.io/lassoboot/reference/lb_derive.md)
that recomputes the same expression inside the bootstrap loop on the
perturbed inputs.

**Important — response column must pre-exist in `data`.**
[`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md)
validates that the formula's left-hand side column exists in `data`
before `lb_normalize()` can run. If `response` does not exist in the
data passed to
[`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md),
the spec call will abort. The recommended pattern is to initialise the
response column with placeholder values (`NA_real_` is fine) in the data
frame before calling
[`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md):

    df$strength_ratio <- NA_real_          # placeholder; lb_normalize() overwrites
    spec <- lb_spec(strength_ratio ~ ...,  # formula LHS matches the placeholder
                    data = df, ...) |>
      lb_normalize(response = strength_ratio,
                   measured  = meas_strength,
                   reference = ref_strength)

`lb_normalize()` overwrites the column with `measured / reference` on
`spec$data` immediately, so the initial
[`lb_fit()`](https://doctorbear-it.github.io/lassoboot/reference/lb_fit.md)
inside
[`lb_bootstrap()`](https://doctorbear-it.github.io/lassoboot/reference/lb_bootstrap.md)
uses the correct ratio values.

The user is responsible for declaring uncertainty on **both** `measured`
and `reference` (via
[`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md)).
Forgetting to declare uncertainty on a normalization component is the
kind of silent mistake that would invalidate the analysis;
`lb_normalize()` treats it as a hard error.

**Pre-aggregation note:** If `reference` is the mean of triplicate
measurements, the declared uncertainty should be the standard error of
that mean (`single-measurement SD / sqrt(n_replicates)`), not the
single-measurement SD. The package propagates whatever you declare; it
does not know about pre-aggregation.

## Examples

``` r
if (FALSE) { # \dontrun{
# lb_spec() requires the response column to exist in `data` when the spec
# is built. Initialise a placeholder; lb_normalize() overwrites it with the
# correct ratio before the first lasso fit.
concrete_with_ref$strength_ratio <- NA_real_   # placeholder

spec <- lb_spec(
  strength_ratio ~ clayHOH + alumina,
  data        = concrete_with_ref,
  uncertainty = lb_uncertainty(
    meas_strength = cov(3.0, "ASTM C109"),
    ref_strength  = cov(2.2, "ASTM C109, mean of 3")
  )
) |>
  lb_normalize(
    response  = strength_ratio,
    measured  = meas_strength,
    reference = ref_strength
  )
# spec$data$strength_ratio now holds meas_strength / ref_strength for every
# row; each bootstrap iteration recomputes the ratio from perturbed inputs.
} # }
```
