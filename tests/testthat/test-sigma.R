test_that("sigma naive matches sd(y - fitted)", {
  set.seed(42)
  n <- 50; p <- 5
  x <- Matrix::Matrix(matrix(rnorm(n * p), n, p), sparse = TRUE)
  y <- rnorm(n)
  fit <- glmnet::glmnet(x, y, alpha = 1, lambda = 0.01)

  sigma_n       <- lassoboot:::.sigma_naive(fit, x, y)
  fitted_manual <- as.numeric(predict(fit, newx = x, s = fit$lambda[1L]))
  expect_equal(sigma_n, sd(y - fitted_manual))
  expect_gt(sigma_n, 0)
})

test_that("sigma refit matches direct lm on selected vars", {
  set.seed(42)
  n <- 100; p <- 5
  x_mat <- matrix(rnorm(n * p), n, p)
  y     <- x_mat[, 1L] + x_mat[, 2L] + rnorm(n, sd = 0.5)
  x     <- Matrix::Matrix(x_mat, sparse = TRUE)
  fit   <- glmnet::glmnet(x, y, alpha = 1, lambda = 0.05)

  sigma_r <- lassoboot:::.sigma_refit(fit, x, y)
  expect_gt(sigma_r, 0)

  cf          <- as.numeric(coef(fit, s = fit$lambda[1L]))
  nonzero_idx <- which(cf[-1L] != 0)
  if (length(nonzero_idx) > 0L) {
    X_sel      <- as.matrix(x[, nonzero_idx, drop = FALSE])
    lm_direct  <- lm(y ~ X_sel)
    expect_equal(sigma_r, summary(lm_direct)$sigma, tolerance = 1e-10)
  }
})

test_that("sigma cv returns positive value", {
  set.seed(42)
  n <- 80; p <- 5
  x      <- Matrix::Matrix(matrix(rnorm(n * p), n, p), sparse = TRUE)
  y      <- rnorm(n)
  fit    <- glmnet::glmnet(x, y, alpha = 1, lambda = 0.01)
  foldid <- sample(rep_len(1:5, n))

  sigma_cv_val <- lassoboot:::.sigma_cv(fit, x, y, foldid = foldid)
  expect_gt(sigma_cv_val, 0)
  expect_true(is.finite(sigma_cv_val))
})

test_that("all three sigma methods return positive finite scalars", {
  set.seed(99)
  n  <- 60; p <- 4
  x  <- Matrix::Matrix(matrix(rnorm(n * p), n, p), sparse = TRUE)
  y  <- rnorm(n)
  fit <- glmnet::glmnet(x, y, alpha = 1, lambda = 0.02)
  foldid <- sample(rep_len(1:5, n))

  expect_gt(lassoboot:::.estimate_sigma(fit, x, y, method = "refit"),             0)
  expect_gt(lassoboot:::.estimate_sigma(fit, x, y, method = "naive"),             0)
  expect_gt(lassoboot:::.estimate_sigma(fit, x, y, method = "cv", foldid = foldid), 0)

  expect_true(is.finite(lassoboot:::.estimate_sigma(fit, x, y, method = "refit")))
  expect_true(is.finite(lassoboot:::.estimate_sigma(fit, x, y, method = "naive")))
})

test_that("sigma refit falls back gracefully when nothing is selected", {
  set.seed(1)
  n <- 20; p <- 3
  x   <- Matrix::Matrix(matrix(rnorm(n * p), n, p), sparse = TRUE)
  y   <- rnorm(n)
  # Very large lambda forces all coefficients to zero
  fit <- glmnet::glmnet(x, y, alpha = 1, lambda = 1e6)

  expect_warning(
    sigma_r <- lassoboot:::.sigma_refit(fit, x, y),
    "No predictors selected"
  )
  expect_gt(sigma_r, 0)
})
