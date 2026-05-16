# Internal: apply Gelman 2-SD scaling to a named coefficient vector.
# Each numeric predictor's coefficient is multiplied by 2 * sd(predictor),
# placing all predictors on a "2-standard-deviation change" scale so that
# continuous and binary predictors are comparable (Gelman 2008).
# Categorical contrasts are unscaled (multiplied by 1).
# Interaction terms scale by the product of the parent predictors' 2-SD factors.
.scale_gelman <- function(coefs, data) {
  stop("Not yet implemented", call. = FALSE)
}
