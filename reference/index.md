# Package index

## Model specification

Declare what to fit and how.

- [`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md)
  : Specify a lasso bootstrap model
- [`lb_control()`](https://doctorbear-it.github.io/lassoboot/reference/lb_control.md)
  : Set tuning parameters for the bootstrap
- [`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md)
  : Construct a measurement uncertainty specification
- [`lb_constraints()`](https://doctorbear-it.github.io/lassoboot/reference/lb_constraints.md)
  : Specify per-column clipping constraints for bootstrap perturbation
- [`lb_derive()`](https://doctorbear-it.github.io/lassoboot/reference/lb_derive.md)
  : Capture a derived-variable expression for re-evaluation in the
  bootstrap loop
- [`lb_engine_glmnet()`](https://doctorbear-it.github.io/lassoboot/reference/lb_engine_glmnet.md)
  : Create a glmnet engine for lassoboot

## Fold generators

Cross-validation fold assignment strategies.

- [`lb_folds_kfold()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_kfold.md)
  : Standard k-fold cross-validation fold generator
- [`lb_folds_grouped()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_grouped.md)
  : Grouped k-fold fold generator (prevents within-group train/test
  leakage)
- [`lb_folds_nested()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_nested.md)
  : Nested fold generator with outer grouping and optional inner
  stratification
- [`lb_folds_blocked()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_blocked.md)
  : Block fold generator
- [`lb_folds_custom()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_custom.md)
  : Custom fold generator

## Fitting and bootstrapping

Run the model and the parametric bootstrap.

- [`lb_fit()`](https://doctorbear-it.github.io/lassoboot/reference/lb_fit.md)
  : Fit an initial lasso model and select lambda
- [`lb_bootstrap()`](https://doctorbear-it.github.io/lassoboot/reference/lb_bootstrap.md)
  : Run the parametric bootstrap

## Tidy model summaries

broom-compatible extraction of results.

- [`tidy(`*`<lb_boot>`*`)`](https://doctorbear-it.github.io/lassoboot/reference/tidy.lb_boot.md)
  : Tidy bootstrap coefficients into a one-row-per-term tibble
- [`glance(`*`<lb_boot>`*`)`](https://doctorbear-it.github.io/lassoboot/reference/glance.lb_boot.md)
  : Model-level bootstrap summary
- [`augment(`*`<lb_boot>`*`)`](https://doctorbear-it.github.io/lassoboot/reference/augment.lb_boot.md)
  : Augment data with bootstrap fitted values and prediction intervals

## Prediction

Generate predictions and prediction grids.

- [`predict(`*`<lb_boot>`*`)`](https://doctorbear-it.github.io/lassoboot/reference/predict.lb_boot.md)
  : Predict from a bootstrap lasso fit
- [`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md)
  : Build a prediction grid varying a focal predictor

## Plots

ggplot2-based visualisations of bootstrap results.

- [`autoplot(`*`<lb_boot>`*`)`](https://doctorbear-it.github.io/lassoboot/reference/autoplot.lb_boot.md)
  : Plot bootstrap lasso output
- [`lb_plot_coefficients()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_coefficients.md)
  : Plot bootstrap coefficient estimates with confidence intervals
- [`lb_plot_selection()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_selection.md)
  : Plot selection probabilities
- [`lb_plot_stability()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_stability.md)
  : Plot stability trajectories (selection probability vs. lambda)
- [`lb_plot_interactions()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_interactions.md)
  : Plot interaction effects as a heatmap
- [`lb_plot_complexity()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_complexity.md)
  : Plot model complexity (number of selected terms) across bootstrap
  iterations
- [`lb_plot_prediction()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_prediction.md)
  : Plot a prediction ribbon for a focal predictor

## Stability and significance helpers

Post-hoc diagnostics on bootstrap output.

- [`lb_stability()`](https://doctorbear-it.github.io/lassoboot/reference/lb_stability.md)
  : Compute stability-selection summaries for bootstrap output
- [`lb_correlated_pairs()`](https://doctorbear-it.github.io/lassoboot/reference/lb_correlated_pairs.md)
  : Identify correlated predictor pairs with split selection
  probabilities
- [`lb_is_significant()`](https://doctorbear-it.github.io/lassoboot/reference/lb_is_significant.md)
  : Test whether terms meet a significance criterion

## Data

Bundled example datasets.

- [`concrete`](https://doctorbear-it.github.io/lassoboot/reference/concrete.md)
  : Limestone calcined clay cement strength dataset
- [`uncertainty_concrete`](https://doctorbear-it.github.io/lassoboot/reference/uncertainty_concrete.md)
  : Measurement uncertainty specification for the concrete dataset

## Package

- [`lassoboot`](https://doctorbear-it.github.io/lassoboot/reference/lassoboot-package.md)
  [`lassoboot-package`](https://doctorbear-it.github.io/lassoboot/reference/lassoboot-package.md)
  : lassoboot: Parametric Bootstrap for Lasso Regression with
  Measurement Uncertainty
