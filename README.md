# lassoboot

**Parametric Bootstrap for Lasso Regression with Measurement Uncertainty**

`lassoboot` provides a tidy, declarative API for principled variable selection
when predictors carry known instrument or method uncertainties. It is aimed at
domain scientists — particularly materials scientists — who need to understand
which predictors *reliably* drive an outcome rather than which predictors
happen to be selected at one particular regularization value.

## Installation

```r
# Development version
pak::pak("DoctorBear-it/lassoboot")
```

## Quick start

```r
library(lassoboot)

# 1. Declare the model, data, and ASTM-documented measurement uncertainties
spec <- lb_spec(
  strength_MPa ~ (clayHOH + log(clayHOH)) * replacement * alumina * SSA * D50,
  data        = concrete,
  uncertainty = uncertainty_concrete,
  folds       = lb_folds_grouped("mixture")
)

# 2. Run the parametric bootstrap (B = 500 takes ~30 s on a laptop)
boot <- withr::with_seed(2025, lb_bootstrap(spec, B = 500))

# 3. Read the results
tidy(boot)          # estimate, CI, selection_prob, stability_score per term
glance(boot)        # model-level summary
autoplot(boot)      # coefficient forest plot
autoplot(boot, type = "selection")   # selection probability bar chart
autoplot(boot, type = "stability")   # selection-vs-lambda trajectory

# 4. Predict
lb_plot_prediction(boot, focal = "clayHOH", n = 80)
```

## Key ideas

**Selection probability.** The fraction of bootstrap iterations in which a
predictor is retained at `lambda.min`. Primary inferential output: high
selection probability = robustly important predictor.

**Stability score.** Maximum selection probability across the regularization
path (Meinshausen & Bühlmann 2010). More conservative; use for confirmatory
claims.

**Measurement uncertainty propagation.** Predictors are perturbed by their
declared noise in each bootstrap iteration before refitting. Uses a
`"refit"` sigma method (OLS on selected variables) to avoid the coverage
under-shoot of naive regularized residuals.

## Vignettes

- `vignette("getting-started")` — 4-predictor toy example; the basic workflow.
- `vignette("measurement-uncertainty")` — uncertainty types, derived quantities,
  normalization, sigma methods, and the selective-inference caveat.
- `vignette("interpreting-results")` — selection vs. CI vs. stability, Gelman
  scaling, correlated predictors, prediction grids, nested CV.

## License

MIT
