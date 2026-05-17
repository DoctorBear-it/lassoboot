# data_seed seeds the data generator; ... are forwarded to lb_control()
make_boot_spec <- function(n = 50, p = 4, data_seed = 1L, ...) {
  set.seed(data_seed)
  mat <- matrix(rnorm(n * p), n, p)
  df  <- as.data.frame(mat)
  names(df) <- paste0("x", seq_len(p))
  df$y <- df$x1 * 2 + df$x2 + rnorm(n, sd = 0.5)
  suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(n_lambda = 15L, cv_reps = 2L, ...))
  )
}

test_that("lb_bootstrap rejects invalid spec_or_fit", {
  expect_error(lb_bootstrap(list()), "lb_spec")
})

test_that("lb_bootstrap rejects non-positive B", {
  spec <- make_boot_spec()
  expect_error(lb_bootstrap(spec, B = 0), "positive integer")
})

test_that("lb_bootstrap accepts an lb_spec and calls lb_fit internally", {
  spec <- make_boot_spec(data_seed = 10L)
  boot <- lb_bootstrap(spec, B = 5L)
  expect_s3_class(boot, "lb_boot")
  expect_s3_class(boot, "lb_fit")
  expect_s3_class(boot, "lb_spec")
})

test_that("lb_bootstrap accepts an lb_fit directly", {
  spec <- make_boot_spec(data_seed = 11L)
  fit  <- lb_fit(spec)
  boot <- lb_bootstrap(fit, B = 5L)
  expect_s3_class(boot, "lb_boot")
})

test_that("lb_bootstrap B=1 produces coef_tbl for one iteration", {
  spec <- make_boot_spec(data_seed = 20L)
  boot <- lb_bootstrap(spec, B = 1L)
  expect_equal(boot$B, 1L)
  if (nrow(boot$coef_tbl) > 0L) {
    expect_true(all(boot$coef_tbl$iteration == 1L))
  }
})

test_that("lb_bootstrap is reproducible under fixed seed", {
  spec <- make_boot_spec(data_seed = 30L, seed = 123L)
  fit  <- withr::with_seed(5L, lb_fit(spec))
  boot1 <- lb_bootstrap(fit, B = 10L)
  boot2 <- lb_bootstrap(fit, B = 10L)
  expect_equal(boot1$coef_tbl, boot2$coef_tbl)
  expect_equal(boot1$seed_used, boot2$seed_used)
})

test_that("lb_bootstrap always stores seed_used on the returned object", {
  spec <- make_boot_spec()  # no seed in control -> generated randomly
  boot <- lb_bootstrap(spec, B = 3L)
  expect_true(is.integer(boot$seed_used))
  expect_true(is.finite(boot$seed_used))
})

test_that("lb_bootstrap keep_models stores glmnet objects", {
  spec <- make_boot_spec(keep_models = TRUE, data_seed = 40L)
  boot <- lb_bootstrap(spec, B = 5L)
  expect_equal(length(boot$models), 5L)
  expect_true(all(vapply(boot$models, inherits, logical(1L), "glmnet")))
})

test_that("lb_bootstrap keep_models=FALSE stores NULL models", {
  spec <- make_boot_spec(keep_models = FALSE, data_seed = 41L)
  boot <- lb_bootstrap(spec, B = 5L)
  expect_null(boot$models)
})

test_that("lb_bootstrap store_path=TRUE produces path_coefs list", {
  spec <- make_boot_spec(store_path = TRUE, data_seed = 50L)
  boot <- lb_bootstrap(spec, B = 5L)
  expect_false(is.null(boot$path_coefs))
  expect_equal(length(boot$path_coefs), 5L)
  expect_true(all(vapply(boot$path_coefs, inherits, logical(1L), "Matrix")))
})

test_that("lb_bootstrap store_path=FALSE stores NULL path_coefs", {
  spec <- make_boot_spec(store_path = FALSE, data_seed = 51L)
  boot <- lb_bootstrap(spec, B = 5L)
  expect_null(boot$path_coefs)
})

test_that("lb_bootstrap fix_lambda=FALSE re-tunes lambda each iteration", {
  spec <- make_boot_spec(fix_lambda = FALSE, data_seed = 60L)
  expect_no_error(lb_bootstrap(spec, B = 3L))
})

test_that("coef_tbl contains only nonzero estimates", {
  spec <- make_boot_spec(data_seed = 70L)
  boot <- lb_bootstrap(spec, B = 20L)
  if (nrow(boot$coef_tbl) > 0L) {
    expect_true(all(boot$coef_tbl$estimate != 0))
  }
})

test_that("coef_tbl term names match design matrix columns", {
  spec <- make_boot_spec(data_seed = 80L)
  fit  <- lb_fit(spec)
  boot <- lb_bootstrap(fit, B = 10L)
  valid_terms <- c("(Intercept)", colnames(fit$x))
  expect_true(all(boot$coef_tbl$term %in% valid_terms))
})

test_that("print.lb_boot produces non-empty output", {
  spec <- make_boot_spec(data_seed = 90L)
  boot <- lb_bootstrap(spec, B = 3L)
  out  <- capture.output(print(boot))
  expect_true(any(grepl("lb_boot", out)))
  expect_true(any(grepl("iterations", out)))
})
