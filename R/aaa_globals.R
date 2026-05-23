utils::globalVariables(c(
  # Phase 2 — no dplyr NSE bare names introduced yet; all column access
  # in constraints/derive/folds uses [[ ]] string subscripting.

  # Phase 5 plot aesthetics — tidy-output columns used in aes()
  # v0.1 names (kept for lb_is_significant backward compat)
  "estimate", "conf.low", "conf.high", "term", "selection_prob",
  "n_selected", "stability_score",

  # v0.2.0 tidy column names
  "mean", "median", "sd",

  # lb_plot_coefficients: ordered factor column created per-call
  "term_ord",

  # lb_plot_selection: above-threshold indicator
  "above",

  # lb_plot_stability: long-format columns
  "lambda", "sel_prob",

  # lb_plot_prediction / lb_grid output columns
  ".fitted", ".lower", ".upper",

  # lb_plot_interactions: heatmap columns
  "var1", "var2",

  # lb_grid clip_to_observed: internal join columns
  ".focal_min", ".focal_max",

  # lb_plot_envelopes: group aesthetic and interaction column
  ".data", ".grp_int"
))
