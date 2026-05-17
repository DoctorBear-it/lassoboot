# data_seed: seeds data generation; cv_reps/n_lambda have fixed defaults here;
# ... forwards any remaining lb_control() args (e.g. lambda, sigma_method).
make_spec <- function(n = 40, p = 3, data_seed = 1L,
                      cv_reps = 2L, n_lambda = 15L, ...) {
  set.seed(data_seed)
  mat <- matrix(rnorm(n * p), n, p)
  df  <- as.data.frame(mat)
  names(df) <- paste0("x", seq_len(p))
  df$y <- df$x1 * 1.5 + rnorm(n, sd = 0.5)
  suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(cv_reps = cv_reps, n_lambda = n_lambda, ...))
  )
}

test_that("lb_fit rejects non-lb_spec input", {
  expect_error(lb_fit(list()), "lb_spec")
})

test_that("lb_fit returns lb_fit with required fields", {
  spec <- make_spec()
  fit  <- lb_fit(spec)
  expect_s3_class(fit, "lb_fit")
  expect_s3_class(fit, "lb_spec")  # inherited
  expect_named(fit, c("spec", "fit_obj", "lambda", "lambda_path",
                       "cv_results", "sigma_hat", "x", "y"))
  expect_true(is.numeric(fit$lambda) && length(fit$lambda) == 1L && fit$lambda > 0)
  expect_true(is.numeric(fit$sigma_hat) && length(fit$sigma_hat) == 1L && fit$sigma_hat > 0)
  expect_s4_class(fit$x, "dgCMatrix")
  expect_true(is.numeric(fit$y))
  expect_equal(length(fit$y), 40L)
})

test_that("lb_fit numeric lambda pass-through uses supplied value", {
  spec <- make_spec(lambda = 0.05)
  fit  <- lb_fit(spec)
  expect_equal(fit$lambda, 0.05)
})

test_that("lb_fit lambda.1se selects a larger lambda than min", {
  spec_min <- make_spec(lambda = "min")
  spec_1se <- make_spec(lambda = "1se")
  fit_min  <- lb_fit(spec_min)
  fit_1se  <- lb_fit(spec_1se)
  expect_gte(fit_1se$lambda, fit_min$lambda)
})

test_that("lb_fit lambda_path has approximately n_lambda values", {
  spec <- make_spec(n_lambda = 15L)
  fit  <- lb_fit(spec)
  # glmnet may return fewer lambda values if the path terminates early
  expect_true(length(fit$lambda_path) >= 1L)
  expect_true(length(fit$lambda_path) <= 15L)
})

test_that("lb_fit repeated-CV is reproducible under fixed seed", {
  spec <- make_spec(lambda = "repeated_cv", cv_reps = 3L)
  fit1 <- withr::with_seed(7L, lb_fit(spec))
  fit2 <- withr::with_seed(7L, lb_fit(spec))
  expect_equal(fit1$lambda, fit2$lambda)
})

test_that("lb_fit warns when folds contain fewer than 2 observations", {
  set.seed(1)
  # 4 rows, 4 folds → each fold gets 1 row; glmnet requires ≥2 predictors
  df <- data.frame(y = 1:4 + rnorm(4, sd = 0.1), x1 = 1:4, x2 = rnorm(4))
  spec <- suppressMessages(
    lb_spec(y ~ x1 + x2, data = df,
            folds   = lb_folds_kfold(4),
            control = lb_control(cv_reps = 1L, n_lambda = 5L))
  )
  expect_warning(lb_fit(spec), "fewer than 2")
})

test_that("lb_fit sigma_method = naive returns positive value", {
  spec <- make_spec(sigma_method = "naive")
  fit  <- lb_fit(spec)
  expect_gt(fit$sigma_hat, 0)
})

test_that("print.lb_fit produces non-empty output", {
  spec <- make_spec()
  fit  <- lb_fit(spec)
  out  <- capture.output(print(fit))
  expect_true(any(grepl("lb_fit", out)))
  expect_true(any(grepl("lambda", out)))
})
