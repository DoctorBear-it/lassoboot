test_that("lb_control() returns an lb_control with all defaults", {
  ctrl <- lb_control()
  expect_s3_class(ctrl, "lb_control")
  expect_equal(ctrl$lambda,       "repeated_cv")
  expect_equal(ctrl$cv_folds,     10L)
  expect_equal(ctrl$cv_reps,      5L)
  expect_true(ctrl$fix_lambda)
  expect_true(ctrl$store_path)
  expect_equal(ctrl$n_lambda,     50L)
  expect_false(ctrl$keep_models)
  expect_equal(ctrl$sigma_method, "refit")
  expect_false(ctrl$parallel)
  expect_null(ctrl$seed)
  expect_true(ctrl$intercept)
  expect_true(ctrl$standardize)
})

test_that("lb_control() coerces counts to integer", {
  ctrl <- lb_control(cv_folds = 5, cv_reps = 3, n_lambda = 100)
  expect_type(ctrl$cv_folds, "integer")
  expect_type(ctrl$cv_reps,  "integer")
  expect_type(ctrl$n_lambda, "integer")
})

test_that("lb_control() accepts valid lambda values", {
  expect_no_error(lb_control(lambda = "repeated_cv"))
  expect_no_error(lb_control(lambda = "min"))
  expect_no_error(lb_control(lambda = "1se"))
  expect_no_error(lb_control(lambda = 0.01))
})

test_that("lb_control() rejects invalid lambda", {
  expect_error(lb_control(lambda = "bad"),   class = "rlang_error")
  expect_error(lb_control(lambda = -1),      class = "rlang_error")
  expect_error(lb_control(lambda = c(1, 2)), class = "rlang_error")
  expect_error(lb_control(lambda = NULL),    class = "rlang_error")
})

test_that("lb_control() accepts valid sigma_method values", {
  expect_no_error(lb_control(sigma_method = "refit"))
  expect_no_error(lb_control(sigma_method = "naive"))
  expect_no_error(lb_control(sigma_method = "cv"))
})

test_that("lb_control() rejects invalid sigma_method", {
  expect_error(lb_control(sigma_method = "ols"),  class = "rlang_error")
  expect_error(lb_control(sigma_method = 1),      class = "rlang_error")
})

test_that("lb_control() validates logical args", {
  expect_error(lb_control(fix_lambda  = "yes"), class = "rlang_error")
  expect_error(lb_control(store_path  = 1),     class = "rlang_error")
  expect_error(lb_control(keep_models = NA),    class = "rlang_error")
  expect_error(lb_control(parallel    = "T"),   class = "rlang_error")
})

test_that("lb_control() validates count args", {
  expect_error(lb_control(cv_folds = 0),   class = "rlang_error")
  expect_error(lb_control(cv_folds = 1),   class = "rlang_error")  # 1-fold CV undefined
  expect_error(lb_control(cv_reps  = -1),  class = "rlang_error")
  expect_error(lb_control(n_lambda = 0.5), class = "rlang_error")
})

test_that("lb_control() validates seed", {
  expect_no_error(lb_control(seed = 42L))
  expect_no_error(lb_control(seed = 42))    # numeric integer-valued
  expect_error(lb_control(seed = 1.5),      class = "rlang_error")
  expect_error(lb_control(seed = "abc"),    class = "rlang_error")
  ctrl <- lb_control(seed = 42)
  expect_type(ctrl$seed, "integer")
})

test_that("format.lb_control() prints all defaults message when no overrides", {
  ctrl <- lb_control()
  out  <- format(ctrl)
  expect_match(out, "all defaults")
})

test_that("format.lb_control() shows non-default values", {
  ctrl <- lb_control(lambda = "min", sigma_method = "naive", seed = 99L)
  out  <- format(ctrl)
  expect_match(out, "lambda")
  expect_match(out, "sigma_method")
  expect_match(out, "seed")
  expect_no_match(out, "all defaults")
})

test_that("print.lb_control() is invisible", {
  ctrl <- lb_control()
  expect_invisible(print(ctrl))
})
