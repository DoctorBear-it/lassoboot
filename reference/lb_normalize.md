# Normalize a response by a reference strength

A convenience wrapper around
[`lb_derive()`](https://doctorbear-it.github.io/lassoboot/reference/lb_derive.md)
for the pattern `response = measured / reference`, where both `measured`
and `reference` carry their own measurement uncertainty and are
perturbed independently in each bootstrap iteration. The user is
responsible for declaring uncertainty on both columns and for ensuring
the declared uncertainties are consistent with any pre-aggregation
(e.g., if `reference` is a mean of triplicates, declare the standard
error of that mean, not the single-measurement SD).

## Usage

``` r
lb_normalize(spec, response, measured, reference)
```

## Arguments

- spec:

  An `lb_spec` object.

- response:

  The column to create/overwrite as the normalized response (unquoted
  symbol). This column overwrites the LHS of the spec's formula.

- measured:

  The measured response column (unquoted symbol).

- reference:

  The reference response column (unquoted symbol).

## Value

An updated `lb_spec` object with the normalization registered as a
derived column.
