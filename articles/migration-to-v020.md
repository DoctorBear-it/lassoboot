# Migrating from lassoboot v0.1 to v0.2.0

``` r

library(lassoboot)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## What lassoboot actually computes

lassoboot runs a **parametric bootstrap** over a lasso regression. In
each of *B* iterations:

1.  Each declared predictor is perturbed by an independent draw from its
    measurement uncertainty distribution.
2.  The response is regenerated as `ŷ + ε`, where `ŷ` is the fitted
    value from the *original* lasso fit and `ε ~ N(0, σ̂²)`.
3.  Lasso is refit on the perturbed data.

The *B* refits produce a distribution of coefficient vectors. Everything
`lassoboot` reports — selection probabilities, stability scores,
quantile intervals, prediction envelopes — is a summary of that
distribution.

### v0.2.0 conceptual reframe

In v0.1, `lassoboot` was framed primarily as a tool for **coefficient
inference**: which predictors have non-zero effects, with what
uncertainty? The tidy output mimicked `broom::tidy()` conventions
(`estimate`, `conf.low`, `conf.high`, `std.error`) to invite comparison
with OLS t-based intervals.

In v0.2.0, the primary framing shifts to **prediction envelopes**: given
a new combination of predictor values, where will the response fall, and
how much of that uncertainty is epistemic (we don’t know the model well)
vs. aleatoric (irreducible scatter)? Selection probabilities are now
explicitly described as **stability diagnostics** — diagnostic evidence
that a predictor is robustly identified — not as a substitute for
p-values.

This reframe does not change any computation. It changes how the outputs
are named, documented, and plotted.

------------------------------------------------------------------------

## Column name changes in `tidy()`

The [`tidy()`](https://generics.r-lib.org/reference/tidy.html) method
for `lb_boot` objects returns one row per predictor. In v0.2.0, column
names are:

| v0.1 name | v0.2.0 name | Notes |
|----|----|----|
| `estimate` | `mean` | Bootstrap mean (zeros from unselected iterations included) |
| `estimate_median` | `median` | Bootstrap median |
| `std.error` | `sd` | Bootstrap standard deviation |
| `conf.low` | `q025` | 2.5 % quantile (by default; controlled by `probs`) |
| `conf.high` | `q975` | 97.5 % quantile |
| `selection_prob` | `selection_prob` | Unchanged |
| `n_selected` | `n_selected` | Unchanged |
| `stability_score` | `stability_score` | Unchanged |

The `conf.level` argument is replaced by `probs`, a numeric vector of
quantile probabilities. The default `probs = c(0.025, 0.975)` gives the
same interval as the old `conf.level = 0.95`.

**There is no backward-compatibility aliasing.** Code that references
`td$conf.low` will error immediately with a clear message from dplyr.
This is intentional: silent wrong-column access is worse than an early
error.

### Updating existing code

``` r

# v0.1
td <- tidy(boot, conf.level = 0.90)
td$estimate
td$conf.low
td$conf.high

# v0.2.0
td <- tidy(boot, probs = c(0.05, 0.95))
td$mean
td$q050   # quantile name is derived from probs × 1000, zero-padded to 3 digits
td$q950
```

The quantile column names are always three-digit zero-padded integers:
`q025`, `q975`, `q050`, `q950`, `q010`, `q990`, etc.

------------------------------------------------------------------------

## Filtering: `lb_filter_stable()` replaces `lb_is_significant()`

[`lb_is_significant()`](https://doctorbear-it.github.io/lassoboot/reference/lb_is_significant.md)
is retained as a **deprecated** wrapper and will be removed in a future
version. Migrate to
[`lb_filter_stable()`](https://doctorbear-it.github.io/lassoboot/reference/lb_filter_stable.md):

``` r

# v0.1
tidy(boot) |>
  filter(lb_is_significant(pick(everything()), method = "selection", threshold = 0.5))

# v0.2.0
lb_filter_stable(tidy(boot), min_selection_prob = 0.5)
```

[`lb_filter_stable()`](https://doctorbear-it.github.io/lassoboot/reference/lb_filter_stable.md)
accepts three independent criteria (any combination):

| Argument                 | Meaning                                        |
|--------------------------|------------------------------------------------|
| `min_selection_prob`     | Keep rows where `selection_prob ≥` this value  |
| `min_stability_score`    | Keep rows where `stability_score ≥` this value |
| `quantiles_exclude_zero` | Keep rows where `q025 > 0` or `q975 < 0`       |

All supplied criteria are AND-ed together. Rows must satisfy every
declared condition to be retained.

------------------------------------------------------------------------

## Prediction intervals: `interval` argument

[`predict.lb_boot()`](https://doctorbear-it.github.io/lassoboot/reference/predict.lb_boot.md),
[`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md),
[`lb_plot_prediction()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_prediction.md),
and
[`lb_plot_envelopes()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_envelopes.md)
now support an `interval` argument:

**`interval = "confidence"` (default):** The bootstrap quantile envelope
around the *mean response*. Captures uncertainty in the regression
surface — how precisely the model is estimated. Narrows as *n* grows.

**`interval = "prediction"`:** Adds residual scatter `ε ~ N(0, σ̂²)` to
each bootstrap draw before computing quantiles. Captures where a *new
individual observation* will fall. Does not narrow with *n* beyond the
point where σ̂ dominates.

**`interval = "both"`** (in
[`lb_plot_envelopes()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_envelopes.md)
only): draws both ribbons simultaneously — prediction ribbon in the
background at lower opacity, confidence ribbon in the foreground at
higher opacity.

``` r

boot <- lb_bootstrap(lb_spec(y ~ x1 + x2, data = df), B = 300)

# Confidence band
lb_plot_prediction(boot, focal = "x1", interval = "confidence")

# Prediction band
lb_plot_prediction(boot, focal = "x1", interval = "prediction")

# Both (envelope plot)
lb_plot_envelopes(boot, focal = "x1", interval = "both")
```

------------------------------------------------------------------------

## Measurement uncertainty precision levels

[`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md)
now supports two precision levels per term via the `multi` argument:

``` r

u <- lb_uncertainty(
  alumina      = std(0.071, source = "ASTM C114"),          # single-lab
  strength_MPa = cov(3.0,  multi = 6.0, source = "ASTM C109")  # single + multi-lab
)
u
#> # A tibble: 2 × 5
#>   term         type  value_single value_multi source   
#>   <chr>        <chr>        <dbl>       <dbl> <chr>    
#> 1 alumina      std          0.071       0.071 ASTM C114
#> 2 strength_MPa cov          3           6     ASTM C109
```

The `lb_control(precision = ...)` argument selects which column is used
during the bootstrap:

- `precision = "single"` (default): use `value_single` —
  within-laboratory repeatability. Appropriate when all data come from
  one lab.
- `precision = "multi"`: use `value_multi` — between-laboratory
  reproducibility. Use when comparing results across labs or for
  worst-case sensitivity analysis.

**Backward compatibility.** The old `uncertainty_concrete` dataset uses
a single `value` column (the v0.1 format).
[`lb_uncertainty()`](https://doctorbear-it.github.io/lassoboot/reference/lb_uncertainty.md)
automatically backfills `value_single = value_multi = value` when it
reads a legacy tibble, so existing code continues to work without
modification.

------------------------------------------------------------------------

## `lb_normalize()` is now exported

[`lb_normalize()`](https://doctorbear-it.github.io/lassoboot/reference/lb_normalize.md)
was an internal function in v0.1. It is now exported and documented. Use
it when the response is a ratio of two measured quantities:

``` r

# lb_spec() requires the response column to exist in data at build time.
# Initialise a placeholder; lb_normalize() overwrites it with the ratio.
df_with_ref$strength_ratio <- NA_real_

spec <- lb_spec(
  strength_ratio ~ clayHOH * replacement,
  data        = df_with_ref,
  uncertainty = lb_uncertainty(
    meas_strength = cov(3.0, "ASTM C109"),
    ref_strength  = cov(2.2, "ASTM C109")
  )
) |>
  lb_normalize(
    response  = strength_ratio,
    measured  = meas_strength,
    reference = ref_strength
  )
```

Each bootstrap iteration perturbs `meas_strength` and `ref_strength`
independently before recomputing the ratio, correctly propagating their
correlated uncertainties.

------------------------------------------------------------------------

## Summary of API changes

| Feature | v0.1 | v0.2.0 |
|----|----|----|
| tidy column: mean | `estimate` | `mean` |
| tidy column: lower CI | `conf.low` | `q025` (or `q` + probs × 1000) |
| tidy column: upper CI | `conf.high` | `q975` |
| tidy column: SD | `std.error` | `sd` |
| tidy interval control | `conf.level = 0.95` | `probs = c(0.025, 0.975)` |
| filter helper | [`lb_is_significant()`](https://doctorbear-it.github.io/lassoboot/reference/lb_is_significant.md) | [`lb_filter_stable()`](https://doctorbear-it.github.io/lassoboot/reference/lb_filter_stable.md) |
| predict interval | not supported | `interval = "confidence"/"prediction"` |
| two precision levels | not supported | `lb_uncertainty(..., multi = ...)` |
| precision selection | not supported | `lb_control(precision = "single"/"multi")` |
| [`lb_normalize()`](https://doctorbear-it.github.io/lassoboot/reference/lb_normalize.md) | internal | exported |
| [`lb_plot_envelopes()`](https://doctorbear-it.github.io/lassoboot/reference/lb_plot_envelopes.md) | not available | new in v0.2.0 |

------------------------------------------------------------------------

## References

Efron, B. and Tibshirani, R. J. (1993). *An Introduction to the
Bootstrap.* Chapman & Hall.

Gelman, A. (2008). Scaling regression inputs by dividing by two standard
deviations. *Statistics in Medicine*, **27**(15), 2865–2873.

Meinshausen, N. and Bühlmann, P. (2010). Stability selection. *Journal
of the Royal Statistical Society: Series B*, **72**(4), 417–473.
