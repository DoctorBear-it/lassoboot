make_xy <- function(n = 50, p = 10, seed = 1) {
  set.seed(seed)
  x <- matrix(stats::rnorm(n * p), n, p,
               dimnames = list(NULL, paste0("x", seq_len(p))))
  y <- x[, 1] * 2 + x[, 2] * -1 + stats::rnorm(n)
  list(x = x, y = y)
}

# ---- .validate_engine -------------------------------------------------------

test_that(".validate_engine() accepts a valid lb_engine_glmnet", {
  eng <- lb_engine_glmnet()
  expect_no_error(lassoboot:::.validate_engine(eng))
})

test_that(".validate_engine() errors when class is missing", {
  bad <- structure(list(fit = identity, predict = identity,
                        coef = identity, cv = identity, sigma = identity),
                   class = "not_an_engine")
  expect_error(lassoboot:::.validate_engine(bad), class = "rlang_error")
})

test_that(".validate_engine() errors when a required method is missing", {
  eng <- lb_engine_glmnet()
  eng$cv <- NULL
  # Remove the glmnet class to avoid method dispatch confusion
  class(eng) <- "lb_engine"
  expect_error(lassoboot:::.validate_engine(eng), class = "rlang_error")
})

test_that(".validate_engine() errors when a method is not a function", {
  eng <- lb_engine_glmnet()
  eng$fit <- "not_a_function"
  class(eng) <- "lb_engine"
  expect_error(lassoboot:::.validate_engine(eng), class = "rlang_error")
})

# ---- lb_engine_glmnet() structure -------------------------------------------

test_that("lb_engine_glmnet() has the correct class", {
  eng <- lb_engine_glmnet()
  expect_s3_class(eng, "lb_engine_glmnet")
  expect_s3_class(eng, "lb_engine")
})

test_that("lb_engine_glmnet() has all five required methods", {
  eng      <- lb_engine_glmnet()
  required <- c("fit", "predict", "coef", "cv", "sigma")
  for (m in required) {
    expect_true(is.function(eng[[m]]), label = paste(m, "is a function"))
  }
})

# ---- engine$fit() -----------------------------------------------------------

test_that("engine$fit() matches direct glmnet::glmnet output", {
  xy  <- make_xy()
  eng <- lb_engine_glmnet()
  lam <- 0.1

  eng_fit    <- eng$fit(xy$x, xy$y, lambda = lam, intercept = TRUE, standardize = TRUE)
  direct_fit <- glmnet::glmnet(xy$x, xy$y, alpha = 1, lambda = lam,
                                intercept = TRUE, standardize = TRUE)
  expect_equal(as.numeric(eng_fit$beta), as.numeric(direct_fit$beta),
               tolerance = 1e-10)
})

# ---- engine$predict() -------------------------------------------------------

test_that("engine$predict() returns a numeric vector", {
  xy  <- make_xy()
  eng <- lb_engine_glmnet()
  fit <- eng$fit(xy$x, xy$y, lambda = 0.05)
  out <- eng$predict(fit, xy$x)
  expect_type(out, "double")
  expect_length(out, nrow(xy$x))
})

# ---- engine$coef() ----------------------------------------------------------

test_that("engine$coef() returns a numeric vector with intercept", {
  xy  <- make_xy()
  eng <- lb_engine_glmnet()
  fit <- eng$fit(xy$x, xy$y, lambda = 0.05)
  cf  <- eng$coef(fit)
  expect_type(cf, "double")
  expect_length(cf, ncol(xy$x) + 1L)  # p predictors + intercept
})

# ---- engine$cv() ------------------------------------------------------------

test_that("engine$cv() returns lambda.min, lambda.1se, lambda_path, cvm", {
  xy     <- make_xy()
  eng    <- lb_engine_glmnet()
  foldid <- rep(1:5, length.out = nrow(xy$x))
  res    <- eng$cv(xy$x, xy$y, foldid = foldid, nlambda = 50L)

  expect_named(res, c("lambda.min", "lambda.1se", "lambda_path", "cvm"),
               ignore.order = TRUE)
  expect_true(is.numeric(res$lambda.min))
  expect_true(is.numeric(res$lambda.1se))
  expect_true(is.numeric(res$lambda_path))
  expect_true(is.numeric(res$cvm))
})

test_that("engine$cv() respects the nlambda argument (path length)", {
  xy     <- make_xy(n = 80, p = 10)
  eng    <- lb_engine_glmnet()
  foldid <- rep(1:5, length.out = nrow(xy$x))
  n_lam  <- 30L
  res    <- eng$cv(xy$x, xy$y, foldid = foldid, nlambda = n_lam)
  # glmnet may return fewer lambdas if convergence happens early,
  # but it must not return more than requested.
  expect_lte(length(res$lambda_path), n_lam)
})

test_that("engine$cv() accepts an explicit lambda vector override", {
  xy     <- make_xy()
  eng    <- lb_engine_glmnet()
  foldid <- rep(1:5, length.out = nrow(xy$x))
  lam_grid <- c(0.5, 0.1, 0.05, 0.01)
  res    <- eng$cv(xy$x, xy$y, foldid = foldid, nlambda = 4L, lambda = lam_grid)
  expect_equal(sort(res$lambda_path, decreasing = TRUE),
               sort(lam_grid, decreasing = TRUE),
               tolerance = 1e-10)
})

test_that("engine$cv() errors on invalid nlambda", {
  xy     <- make_xy()
  eng    <- lb_engine_glmnet()
  foldid <- rep(1:5, length.out = nrow(xy$x))
  expect_error(eng$cv(xy$x, xy$y, foldid, nlambda = 0),  class = "rlang_error")
  expect_error(eng$cv(xy$x, xy$y, foldid, nlambda = -1), class = "rlang_error")
})

test_that("engine$cv() errors on invalid lambda vector", {
  xy     <- make_xy()
  eng    <- lb_engine_glmnet()
  foldid <- rep(1:5, length.out = nrow(xy$x))
  expect_error(
    eng$cv(xy$x, xy$y, foldid, nlambda = 4L, lambda = c(-0.1, 0.5)),
    class = "rlang_error"
  )
})

# ---- engine$sigma() ---------------------------------------------------------

test_that("engine$sigma() errors with 'not yet implemented'", {
  xy  <- make_xy()
  eng <- lb_engine_glmnet()
  fit <- eng$fit(xy$x, xy$y, lambda = 0.05)
  expect_error(eng$sigma(fit, xy$x, xy$y), class = "rlang_error")
})
