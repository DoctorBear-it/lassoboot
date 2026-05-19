# Changelog

## lassoboot 0.1.0

First CRAN release.

### New features

- [`lb_spec()`](https://doctorbear-it.github.io/lassoboot/reference/lb_spec.md)
  — declarative model specification with measurement uncertainty,
  derived quantities, and per-predictor constraints.
- [`lb_bootstrap()`](https://doctorbear-it.github.io/lassoboot/reference/lb_bootstrap.md)
  — parametric bootstrap fitting: perturbs predictors by their declared
  uncertainties, re-fits lasso in each iteration, and accumulates
  coefficient tables.
- [`lb_fit()`](https://doctorbear-it.github.io/lassoboot/reference/lb_fit.md)
  — single-fit helper (useful for inspection and testing).
- [`lb_control()`](https://doctorbear-it.github.io/lassoboot/reference/lb_control.md)
  — runtime options: CV folds, lambda strategy, sigma method, seed,
  parallelism, path storage.
- [`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md)
  — per-predictor measurement uncertainty declarations (`std()`,
  [`cov()`](https://rdrr.io/r/stats/cor.html), `rel_sd()` sub-helpers).
- [`lb_constraints()`](https://doctorbear-it.github.io/lassoboot/reference/lb_constraints.md)
  — per-predictor sign/range constraints applied after each bootstrap
  draw.
- [`lb_derive()`](https://doctorbear-it.github.io/lassoboot/reference/lb_derive.md)
  — derived-quantity definitions evaluated in data column space before
  model fitting.
- [`lb_engine_glmnet()`](https://doctorbear-it.github.io/lassoboot/reference/lb_engine_glmnet.md)
  — glmnet backend (default); the engine abstraction is designed to
  accommodate future backends without API changes.
- [`lb_folds_kfold()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_kfold.md),
  [`lb_folds_grouped()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_grouped.md),
  [`lb_folds_nested()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_nested.md),
  [`lb_folds_blocked()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_blocked.md),
  [`lb_folds_custom()`](https://doctorbear-it.github.io/lassoboot/reference/lb_folds_custom.md)
  — fold generators for standard, grouped, nested, blocked, and
  user-defined cross-validation schemes.
- [`tidy()`](https://generics.r-lib.org/reference/tidy.html),
  [`glance()`](https://generics.r-lib.org/reference/glance.html),
  [`augment()`](https://generics.r-lib.org/reference/augment.html) —
  broom-compatible summaries of an `lb_boot` object (selection
  probabilities, stability scores, bootstrap CIs).
- [`predict()`](https://rdrr.io/r/stats/predict.html),
  [`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md)
  — matrix-based prediction and prediction-grid construction for ribbon
  plots.
- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html),
  [`lb_plot_coefficients()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_coefficients.md),
  [`lb_plot_selection()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_selection.md),
  [`lb_plot_stability()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_stability.md),
  [`lb_plot_interactions()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_interactions.md),
  [`lb_plot_complexity()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_complexity.md),
  [`lb_plot_prediction()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_prediction.md)
  — ggplot2-based visualisations.
- [`lb_stability()`](https://doctorbear-it.github.io/lassoboot/reference/lb_stability.md),
  [`lb_correlated_pairs()`](https://doctorbear-it.github.io/lassoboot/reference/lb_correlated_pairs.md),
  [`lb_is_significant()`](https://doctorbear-it.github.io/lassoboot/reference/lb_is_significant.md)
  — stability and significance helpers.
- `concrete` and `uncertainty_concrete` — bundled example dataset
  (concrete compressive strength with per-predictor measurement
  uncertainties).

### Notes

- Gaussian response only; GLM support is deferred to v0.2.
- Lasso penalty only (`alpha = 1`); elastic net is reserved.
- No mixed-effects support; the engine abstraction is designed to
  accommodate `lb_engine_glmmlasso()` in a future release without API
  changes.
