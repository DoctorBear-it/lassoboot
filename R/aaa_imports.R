#' @importFrom cli cli_abort cli_inform cli_warn cli_progress_bar
#'   cli_progress_update cli_progress_done
#' @importFrom dplyr filter mutate select group_by summarise arrange left_join
#'   bind_rows n
#' @importFrom generics tidy glance augment
#' @importFrom ggplot2 ggplot aes autoplot geom_point geom_linerange
#'   geom_hline geom_line geom_ribbon facet_wrap theme_bw scale_color_viridis_d
#'   scale_fill_brewer labs
#' @importFrom glmnet glmnet cv.glmnet
#' @importFrom Matrix Matrix
#' @importFrom matrixStats rowQuantiles rowMeans2 rowSds
#' @importFrom purrr map map2 walk
#' @importFrom rlang `%||%` abort warn inform enquo enquos eval_tidy
#'   quo_is_null
#' @importFrom scales pseudo_log_trans
#' @importFrom stats model.matrix quantile rnorm predict lm sd coef residuals
#'   fitted cor
#' @importFrom tibble tibble as_tibble is_tibble
#' @importFrom tidyr pivot_longer pivot_wider crossing
#' @importFrom vctrs vec_check_size vec_assert
#' @importFrom withr with_seed local_options
NULL
