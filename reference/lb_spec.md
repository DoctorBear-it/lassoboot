# Specify a lasso bootstrap model

The primary entry point for `lassoboot`. Declares the formula, data,
measurement uncertainty, derived quantities, per-column constraints,
cross-validation fold scheme, engine, and tuning control for the
subsequent bootstrap. Validates all inputs immediately and emits
informative errors that name domain quantities, not statistical
operations.

## Usage

``` r
lb_spec(
  formula,
  data,
  uncertainty = NULL,
  derive = NULL,
  constraints = NULL,
  folds = lb_folds_kfold(10),
  engine = lb_engine_glmnet(),
  control = lb_control()
)
```

## Arguments

- formula:

  A model formula. The response must be numeric. Random-effect terms
  (e.g. `(1 | group)`) are not supported by the glmnet engine and raise
  an informative error.

- data:

  A data frame or tibble.

- uncertainty:

  A measurement uncertainty specification from
  [`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md),
  or `NULL` for no predictor perturbation. Default `NULL`.

- derive:

  A list of
  [`lb_derive()`](https://doctorbear-it.github.io/lassoboot/reference/lb_derive.md)
  objects evaluated in declaration order inside the bootstrap loop after
  uncertainty injection and constraint clipping. Default `NULL`.

- constraints:

  A
  [`lb_constraints()`](https://doctorbear-it.github.io/lassoboot/reference/lb_constraints.md)
  object specifying per-column clipping bounds, or `NULL` to infer
  defaults (non-negative if all observed values \>= 0, unconstrained
  otherwise). Default `NULL`. Inferred defaults are reported once at
  construction.

- folds:

  A fold-generator function from `lb_folds_*()`. Default
  [`lb_folds_kfold()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_kfold.md).

- engine:

  An engine from `lb_engine_*()`. Default
  [`lb_engine_glmnet()`](https://doctorbear-it.github.io/lassoboot/reference/lb_engine_glmnet.md).

- control:

  A
  [`lb_control()`](https://doctorbear-it.github.io/lassoboot/reference/lb_control.md)
  object. Default
  [`lb_control()`](https://doctorbear-it.github.io/lassoboot/reference/lb_control.md).

## Value

An `lb_spec` object.

## Examples

``` r
spec <- suppressMessages(lb_spec(strength_MPa ~ clayHOH + alumina, data = concrete))
print(spec)
#> <lb_spec>
#>   formula:     strength_MPa ~ clayHOH + alumina
#>   data:        75 rows x 10 columns
#>   uncertainty: none
#>   derive:      none
#>   constraints: 2 column(s)
#>   engine:      lb_engine_glmnet
#>   control:     <lb_control: all defaults> 
```
