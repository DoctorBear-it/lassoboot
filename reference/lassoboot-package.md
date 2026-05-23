# lassoboot: Parametric Bootstrap for Lasso Regression with Measurement Uncertainty

`lassoboot` provides a tidy, declarative API for parametric bootstrap
inference on lasso regression in the presence of measurement
uncertainty. It is designed for domain scientists — particularly
materials scientists — who need principled variable selection when their
predictors carry known instrument or method uncertainties.

### Core workflow

    library(lassoboot)

    # 1. Declare the model, data, and measurement uncertainties
    spec <- lb_spec(
      strength_MPa ~ (clayHOH + log(clayHOH)) * replacement * alumina * SSA * D50,
      data        = concrete,
      uncertainty = uncertainty_concrete,
      folds       = lb_folds_grouped("mixture")
    )

    # 2. Run the parametric bootstrap
    boot <- lb_bootstrap(spec, B = 500)

    # 3. Summarise
    tidy(boot)          # one row per predictor: estimate, CI, selection_prob
    glance(boot)        # model-level summary
    autoplot(boot)      # coefficient forest plot
    autoplot(boot, type = "selection")   # selection probability bar chart

### Key concepts

**Measurement uncertainty propagation.** Each predictor can carry a
declared uncertainty
([`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md))
expressed as a standard deviation, coefficient of variation, or relative
SD. In each bootstrap iteration, predictors are perturbed by their
declared uncertainty before refitting, so the output CIs and selection
probabilities reflect both model and measurement variance.

**Selection probability.** The fraction of bootstrap iterations in which
a predictor is retained (has a nonzero coefficient at `lambda.min`).
This is the primary inferential output: predictors with high selection
probability are robustly informative regardless of the specific lambda
value chosen.

**Stability score.** The maximum selection probability across the
regularization path (Meinshausen & Bühlmann 2010). More conservative
than point-lambda selection probability; a high stability score
indicates a predictor is selected across a *range* of regularization
strengths.

### Scope and limitations (v0.1)

- Gaussian response only (GLM support deferred to v0.2).

- Lasso penalty only (`alpha = 1`); elastic net reserved.

- No mixed-effects support; the engine abstraction is designed to
  accommodate `lb_engine_glmmlasso()` in a future release without API
  changes.

- Bootstrap CIs are approximate under regularization (not
  selectively-inferentially exact in the Lockhart et al. 2014 sense);
  see
  [`vignette("measurement-uncertainty")`](https://doctorbear-it.github.io/lassoboot/articles/measurement-uncertainty.md)
  for discussion.

## References

Meinshausen, N. and Bühlmann, P. (2010). Stability selection. *Journal
of the Royal Statistical Society: Series B*, **72**(4), 417–473.

Gelman, A. (2008). Scaling regression inputs by dividing by two standard
deviations. *Statistics in Medicine*, **27**(15), 2865–2873.

## See also

Useful links:

- Report bugs at <https://github.com/DoctorBear-it/lassoboot/issues>

## Author

**Maintainer**: Timothy Barrett <dr.timothy.j.barrett@gmail.com>
([ORCID](https://orcid.org/0000-0002-7703-1011))

Authors:

- Timothy Barrett <dr.timothy.j.barrett@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-7703-1011))
