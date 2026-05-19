# lassoboot 0.1.0

First CRAN release.

## New features

* `lb_spec()` — declarative model specification with measurement uncertainty,
  derived quantities, and per-predictor constraints.
* `lb_bootstrap()` — parametric bootstrap fitting: perturbs predictors by their
  declared uncertainties, re-fits lasso in each iteration, and accumulates
  coefficient tables.
* `lb_fit()` — single-fit helper (useful for inspection and testing).
* `lb_control()` — runtime options: CV folds, lambda strategy, sigma method,
  seed, parallelism, path storage.
* `lb_uncertainty()` — per-predictor measurement uncertainty declarations
  (`std()`, `cov()`, `rel_sd()` sub-helpers).
* `lb_constraints()` — per-predictor sign/range constraints applied after each
  bootstrap draw.
* `lb_derive()` — derived-quantity definitions evaluated in data column space
  before model fitting.
* `lb_engine_glmnet()` — glmnet backend (default); the engine abstraction is
  designed to accommodate future backends without API changes.
* `lb_folds_kfold()`, `lb_folds_grouped()`, `lb_folds_nested()`,
  `lb_folds_blocked()`, `lb_folds_custom()` — fold generators for standard,
  grouped, nested, blocked, and user-defined cross-validation schemes.
* `tidy()`, `glance()`, `augment()` — broom-compatible summaries of an
  `lb_boot` object (selection probabilities, stability scores, bootstrap CIs).
* `predict()`, `lb_grid()` — matrix-based prediction and prediction-grid
  construction for ribbon plots.
* `autoplot()`, `lb_plot_coefficients()`, `lb_plot_selection()`,
  `lb_plot_stability()`, `lb_plot_interactions()`, `lb_plot_complexity()`,
  `lb_plot_prediction()` — ggplot2-based visualisations.
* `lb_stability()`, `lb_correlated_pairs()`, `lb_is_significant()` — stability
  and significance helpers.
* `concrete` and `uncertainty_concrete` — bundled example dataset (concrete
  compressive strength with per-predictor measurement uncertainties).

## Notes

* Gaussian response only; GLM support is deferred to v0.2.
* Lasso penalty only (`alpha = 1`); elastic net is reserved.
* No mixed-effects support; the engine abstraction is designed to accommodate
  `lb_engine_glmmlasso()` in a future release without API changes.
