# Changelog

## lassoboot 0.2.0

### Breaking changes

- [`tidy()`](https://generics.r-lib.org/reference/tidy.html) column
  names have changed — there is no backward-compatibility aliasing.
  Update all code that references old names:
  - `estimate` → `mean`
  - `estimate_median` → `median`
  - `std.error` → `sd`
  - `conf.low` → `q025` (or `q` + quantile × 1000, zero-padded to 3
    digits)
  - `conf.high` → `q975`
- [`tidy()`](https://generics.r-lib.org/reference/tidy.html) argument
  `conf.level` replaced by `probs` (a numeric vector of quantile
  probabilities, e.g. `probs = c(0.025, 0.975)`).

### New features

- **Prediction intervals.**
  [`predict.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/predict.lb_boot.md),
  [`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md),
  [`lb_plot_prediction()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_prediction.md),
  and the new
  [`lb_plot_envelopes()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_envelopes.md)
  all accept `interval = "confidence"` (bootstrap quantile envelope
  around the mean response, the default) or `interval = "prediction"`
  (adds residual scatter ε ~ N(0, σ̂²) to each bootstrap draw). The sigma
  used for prediction draws is stored per-iteration as
  `boot$sigma_hats`.

- **[`lb_plot_envelopes()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_envelopes.md).**
  New high-level plotting function for prediction envelopes. Supports
  `group`, `facet`, `hlines`, `xlim`/`ylim`, and `interval = "both"` for
  overlaid confidence + prediction ribbons. Maps the `group` variable to
  color, fill, and linetype simultaneously.

- **Dual precision levels in
  [`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md).**
  Each uncertainty entry now carries `value_single` (within-lab) and
  `value_multi` (between-lab) columns. Declare both via
  `std(value, multi = ..., source = ...)`. Legacy single-column `value`
  tibbles are automatically backfilled and remain fully compatible.
  Select the active level with `lb_control(precision = ...)`.

- **`lb_control(precision = ...)`.** New argument (`"single"` or
  `"multi"`, default `"single"`) routes the bootstrap to within-lab or
  between-lab uncertainty values declared in
  [`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md).

- **[`lb_normalize()`](https://doctorbear-it.github.io/lassoboot/reference/lb_normalize.md)
  exported.** Previously internal; now exported with full documentation.
  Registers a ratio response (measured / reference) and rewrites the
  formula LHS so that each bootstrap iteration correctly propagates
  uncertainty through the ratio.

- **[`lb_filter_stable()`](https://doctorbear-it.github.io/lassoboot/reference/lb_filter_stable.md).**
  New primary API for filtering
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) output.
  Accepts `min_selection_prob`, `min_stability_score`, and
  `quantiles_exclude_zero` (any combination, AND-ed). Replaces
  [`lb_is_significant()`](https://doctorbear-it.github.io/lassoboot/reference/lb_is_significant.md),
  which is retained as a deprecated wrapper.

- **[`lb_is_significant()`](https://doctorbear-it.github.io/lassoboot/reference/lb_is_significant.md)
  deprecated.** Use
  [`lb_filter_stable()`](https://doctorbear-it.github.io/lassoboot/reference/lb_filter_stable.md)
  instead. The old function still works but emits a one-time deprecation
  warning.

- **New vignette: `methodological-foundations`.** Covers the v0.2.0
  conceptual reframe (prediction envelopes vs. parameter inference), the
  full column-rename migration table, the `probs` /
  [`lb_filter_stable()`](https://doctorbear-it.github.io/lassoboot/reference/lb_filter_stable.md)
  API, dual precision levels, and the confidence vs. prediction band
  taxonomy.

### Bug fixes and improvements

- [`lb_normalize()`](https://doctorbear-it.github.io/lassoboot/reference/lb_normalize.md)
  now materializes the response column on `spec$data` before registering
  the derive, fixing a subtle evaluation-order bug when the response
  column did not yet exist in the data frame.
- `.estimate_sigma()` gains an explicit `lambda` argument; per-iteration
  sigma estimates are now stored as `boot$sigma_hats` (length-*B*
  numeric vector) and used when constructing prediction intervals.
- [`lb_plot_coefficients()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_coefficients.md):
  axis label updated from “Bootstrap coefficient estimate” to “Bootstrap
  coefficient (mean)”; the `filter` argument now accepts
  `"quantiles_exclude_zero"` as the preferred name for what was
  previously `"significant"`.

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
