make_pred_boot <- function(n = 60, p = 4, data_seed = 1L, B = 30L, ...) {
  set.seed(data_seed)
  mat <- matrix(rnorm(n * p), n, p)
  df  <- as.data.frame(mat)
  names(df) <- paste0("x", seq_len(p))
  df$y <- df$x1 * 2 + df$x2 + rnorm(n, sd = 0.5)
  spec <- suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(n_lambda = 10L, cv_reps = 2L, ...))
  )
  withr::with_seed(42L, lb_bootstrap(spec, B = B))
}

# ---- type = "response" / interval = "none" ----------------------------------

test_that("predict returns .fitted of correct length for training data", {
  boot <- make_pred_boot()
  pred <- predict(boot)
  expect_equal(nrow(pred), length(boot$fit$y))
  expect_named(pred, ".fitted")
  expect_true(is.numeric(pred$.fitted))
})

test_that("predict with newdata returns .fitted of correct length", {
  boot    <- make_pred_boot()
  newdata <- boot$fit$spec$data[1:10, ]
  pred    <- predict(boot, newdata = newdata)
  expect_equal(nrow(pred), 10L)
})

test_that("predict with interval='confidence' returns .fitted/.lower/.upper", {
  boot <- make_pred_boot()
  pred <- predict(boot, interval = "confidence")
  expect_named(pred, c(".fitted", ".lower", ".upper"))
  expect_true(all(pred$.lower <= pred$.fitted + 1e-10))
  expect_true(all(pred$.upper >= pred$.fitted - 1e-10))
})

# ---- Matrix-pipeline correctness regression test ----------------------------
# The fast matrix-based pipeline must produce results identical (to 1e-10) to
# a naive reference implementation that reconstructs predictions per iteration.
test_that("matrix pipeline matches naive reference on small example", {
  set.seed(1L)
  n <- 20; p <- 3
  df <- data.frame(
    x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n),
    y  = rnorm(n)
  )
  spec  <- suppressMessages(lb_spec(y ~ .,  data = df,
    control = lb_control(n_lambda = 5L, cv_reps = 1L,
                         store_path = FALSE)))
  boot  <- withr::with_seed(7L, lb_bootstrap(spec, B = 10L))

  # Fast path
  fast_pred <- predict(boot, interval = "none")$.fitted

  # Naive reference: for each iteration, reconstruct the full coefficient
  # vector (zeros filled), multiply by the design matrix, accumulate, then
  # average.
  X        <- as.matrix(boot$fit$x)
  B        <- boot$B
  term_nms <- c("(Intercept)", colnames(boot$fit$x))
  pred_sum <- numeric(n)
  for (b in seq_len(B)) {
    coef_b <- stats::setNames(rep(0.0, length(term_nms)), term_nms)
    sub    <- boot$coef_tbl[boot$coef_tbl$iteration == b, ]
    coef_b[sub$term] <- sub$estimate
    pred_b <- coef_b["(Intercept)"] + X %*% coef_b[-1L]
    pred_sum <- pred_sum + as.numeric(pred_b)
  }
  naive_pred <- pred_sum / B

  expect_equal(fast_pred, naive_pred, tolerance = 1e-10)
})

# ---- B_sub subsampling ------------------------------------------------------

test_that("B_sub subsamples iterations for type='response'", {
  boot <- make_pred_boot(B = 20L)
  withr::with_seed(1L, {
    pred_full <- predict(boot, interval = "none")
    pred_sub  <- predict(boot, interval = "none", B_sub = 5L)
  })
  # Both have same length
  expect_equal(nrow(pred_sub), nrow(pred_full))
  # Results differ when subsampling (not identical to full)
  # (very unlikely to be equal by chance)
  expect_false(isTRUE(all.equal(pred_sub$.fitted, pred_full$.fitted)))
})

test_that("B_sub for type='coef' subsamples coef_tbl iterations", {
  # make_pred_boot uses strong signal (x1*2 + x2) so every bootstrap
  # iteration selects at least one term; nrow(ct_sub) > 0 is guaranteed.
  boot   <- make_pred_boot(B = 20L)
  ct_sub <- withr::with_seed(1L, predict(boot, type = "coef", B_sub = 5L))
  n_iters <- length(unique(ct_sub$iteration))
  expect_true(nrow(ct_sub) > 0L)
  expect_true(n_iters >= 1L && n_iters <= 5L)
})

# ---- lb_grid ----------------------------------------------------------------

test_that("lb_grid returns a tibble with the focal column and predictions", {
  boot <- make_pred_boot()
  grid <- lb_grid(boot, focal = "x1", n = 10)
  expect_s3_class(grid, "tbl_df")
  expect_true("x1" %in% names(grid))
  expect_true(all(c(".fitted", ".lower", ".upper") %in% names(grid)))
})

test_that("lb_grid errors if focal is not a data column", {
  boot <- make_pred_boot()
  expect_error(lb_grid(boot, focal = "not_a_column"), "not found")
})

test_that("lb_grid at='median' returns correct number of rows", {
  boot <- make_pred_boot()
  grid <- lb_grid(boot, focal = "x1", n = 20, at = "median")
  expect_equal(nrow(grid), 20L)
})

test_that("lb_grid at=list(...) uses supplied values", {
  boot <- make_pred_boot()
  data <- boot$fit$spec$data
  grid <- lb_grid(boot, focal = "x1", n = 5,
                  at = list(x2 = 0, x3 = 0, x4 = 0))
  expect_equal(nrow(grid), 5L)
  expect_true(all(grid$x2 == 0))
})

test_that("lb_grid at='median' preserves factor class on non-focal columns", {
  # Regression test: modal value of a factor column must come back as factor,
  # not character, so that predict.lb_boot's model.frame() does not error.
  set.seed(9L)
  n  <- 40
  df <- data.frame(
    x1 = rnorm(n),
    grp = factor(sample(c("A", "B", "C"), n, replace = TRUE)),
    y   = rnorm(n)
  )
  spec <- suppressMessages(
    lb_spec(y ~ x1 + grp, data = df,
            control = lb_control(n_lambda = 5L, cv_reps = 1L,
                                 store_path = FALSE))
  )
  boot <- withr::with_seed(3L, lb_bootstrap(spec, B = 10L))
  grid <- lb_grid(boot, focal = "x1", n = 10, at = "median")
  expect_s3_class(grid$grp, "factor")
  # Confirm predict did not error (grid has predictions)
  expect_true(all(c(".fitted", ".lower", ".upper") %in% names(grid)))
})

test_that("lb_grid focal values stay within observed range by default", {
  boot  <- make_pred_boot()
  data  <- boot$fit$spec$data
  grid  <- lb_grid(boot, focal = "x1", n = 50)
  x_min <- min(data$x1, na.rm = TRUE)
  x_max <- max(data$x1, na.rm = TRUE)
  expect_true(all(grid$x1 >= x_min - 1e-10))
  expect_true(all(grid$x1 <= x_max + 1e-10))
})
