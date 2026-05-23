# Flagship measurement-uncertainty-propagated prediction envelope plot

Produces per-combination prediction ribbons over a focal predictor, with
optional faceting, raw data overlay, and horizontal reference lines.
This is the recommended visualization for communicating bootstrap
results to an applied audience.

## Usage

``` r
lb_plot_envelopes(
  boot,
  focal,
  group = NULL,
  facet = NULL,
  data = NULL,
  hlines = NULL,
  hline_types = NULL,
  xlim = NULL,
  ylim = NULL,
  n = 100L,
  alpha_ribbon = 0.25,
  label_x = NULL,
  label_y = NULL,
  interval = c("confidence", "prediction", "both"),
  ...
)
```

## Arguments

- boot:

  An `lb_boot` object.

- focal:

  Name of the focal (x-axis) predictor (string). Passed to
  [`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md).

- group:

  String column name to map to color, fill, and linetype aesthetics, or
  `NULL`. Typically a grouping variable such as a replacement level.

- facet:

  A `vars()` expression for faceting (e.g.
  `vars(Fineness, Alumina_Grade)`), or `NULL` for no faceting.

- data:

  A data frame to overlay as raw data points, or `NULL`. Must contain
  the `focal` column and the response variable.

- hlines:

  Numeric vector of y-values for horizontal reference lines, or `NULL`.
  The first value is drawn solid; subsequent values are dashed. Override
  with `hline_types`.

- hline_types:

  Character vector of ggplot2 linetype values, one per element of
  `hlines`. Default: first is `"solid"`, rest are `"dashed"`.

- xlim:

  Length-2 numeric or `NULL`. Passed to
  [`ggplot2::coord_cartesian()`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html).

- ylim:

  Length-2 numeric or `NULL`. Passed to
  [`ggplot2::coord_cartesian()`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html).

- n:

  Number of grid points along the focal axis. Passed to
  [`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md).
  Default `100`.

- alpha_ribbon:

  Alpha for ribbon fill. Default `0.25`.

- label_x:

  X-axis label string, or `NULL` to use the focal column name.

- label_y:

  Y-axis label string, or `NULL` to use the response variable name from
  the formula.

- interval:

  One of `"confidence"` (default), `"prediction"`, or `"both"`.
  `"confidence"` shows where the model's mean function lives under
  measurement-uncertainty perturbation. `"prediction"` shows where a
  single new observation would land (confidence + residual scatter).
  `"both"` draws an outer prediction ribbon (low alpha) and an inner
  confidence ribbon (higher alpha) with the line on top.

- ...:

  Additional arguments passed to
  [`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md)
  (e.g. `clip_to_observed`, `at`, `extrapolate`).

## Value

A `ggplot` object. No side effects; add layers with `+`.

## Details

The user adds domain-specific binning columns to the prediction grid
(returned by
[`lb_grid()`](https://doctorbear-it.github.io/lassoboot/reference/lb_grid.md))
and to the raw data before calling this function; the function does not
guess what binning makes sense. Aesthetic overrides and additional
ggplot2 layers can be added to the returned object with `+`.

## Examples

``` r
# \donttest{
set.seed(1)
n  <- 40
df <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
df$y <- 2 * df$x1 + rnorm(n)
spec <- suppressMessages(lb_spec(y ~ x1 + x2 + x3, data = df))
boot <- lb_bootstrap(spec, B = 5)
lb_plot_envelopes(boot, focal = "x1")

# }
```
