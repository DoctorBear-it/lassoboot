# NOTE: stats::cov() must always be called with the explicit `stats::` prefix
# throughout this package. The internal .unc_cov() helper (evaluated only
# inside lb_uncertainty()) shadows the name `cov` in that local environment.
# Using `stats::cov()` everywhere else prevents any future ambiguity if a
# maintainer adds another `cov`-named symbol to the package.

#' @importFrom cli cli_abort cli_inform cli_warn cli_progress_bar cli_progress_update cli_progress_done
#' @importFrom dplyr filter mutate select group_by summarise arrange left_join bind_rows bind_cols across n
#' @importFrom generics tidy glance augment
#' @importFrom ggplot2 ggplot aes autoplot geom_point geom_linerange geom_hline geom_line geom_ribbon geom_col geom_vline geom_tile geom_histogram element_text facet_wrap theme_bw scale_color_viridis_c scale_color_viridis_d scale_fill_brewer scale_fill_manual scale_fill_distiller scale_x_continuous scale_y_continuous labs
#' @importFrom glmnet glmnet cv.glmnet
#' @importFrom Matrix Matrix sparse.model.matrix
#' @importFrom matrixStats rowQuantiles rowMeans2 rowSds rowMaxs rowSums2
#' @importFrom purrr map map2 walk
#' @importFrom rlang `%||%` .data abort warn inform enquo enquos eval_tidy quo_is_null new_environment caller_env
#' @importFrom scales pseudo_log_trans squish
#' @importFrom stats model.matrix model.frame model.response terms delete.response reformulate update quantile rnorm predict lm lm.fit sd coef residuals fitted cor setNames median
#' @importFrom tibble tibble as_tibble is_tibble
#' @importFrom tidyr pivot_longer pivot_wider crossing
#' @importFrom vctrs vec_check_size vec_assert
#' @importFrom withr with_seed local_options
NULL
