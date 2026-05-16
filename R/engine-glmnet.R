#' Create a glmnet engine for lassoboot
#'
#' The default engine. Wraps `glmnet::glmnet` and `glmnet::cv.glmnet` behind
#' the `lb_engine` interface. The bootstrap loop calls engine methods by name
#' and never calls `glmnet::glmnet` directly, keeping future engine additions
#' (e.g. `lb_engine_glmmlasso()`) non-breaking.
#'
#' @return An object of class `c("lb_engine_glmnet", "lb_engine")`: a list
#'   with methods `fit`, `predict`, `coef`, `cv`, and `sigma`.
#' @export
lb_engine_glmnet <- function() {
  stop("Not yet implemented", call. = FALSE)
}
