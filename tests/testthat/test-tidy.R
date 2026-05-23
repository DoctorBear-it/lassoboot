make_tidy_boot <- function(n = 60, p = 4, data_seed = 1L, B = 30L,
                            store_path = TRUE, ...) {
  set.seed(data_seed)
  mat <- matrix(rnorm(n * p), n, p)
  df  <- as.data.frame(mat)
  names(df) <- paste0("x", seq_len(p))
  df$y <- df$x1 * 2 + df$x2 + rnorm(n, sd = 0.5)
  spec <- suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(n_lambda = 10L, cv_reps = 2L,
                                 store_path = store_path, ...))
  )
  withr::with_seed(42L, lb_bootstrap(spec, B = B))
}

# ---- tidy() schema -----------------------------------------------------------

test_that("tidy.lb_boot returns the v0.2.0 documented columns", {
  boot <- make_tidy_boot()
  td   <- tidy(boot)
  expected <- c("term", "mean", "median", "sd",
                "q025", "q975",
                "selection_prob", "n_selected",
                "stability_score")
  expect_named(td, expected)
})

test_that("tidy.lb_boot drops (Intercept) by default", {
  boot <- make_tidy_boot()
  td   <- tidy(boot)
  expect_false("(Intercept)" %in% td$term)
})

test_that("tidy.lb_boot has one row per predictor term", {
  boot <- make_tidy_boot()
  td   <- tidy(boot)
  expect_equal(nrow(td), ncol(boot$fit$x))
})

test_that("selection_prob is in [0, 1] for every row", {
  boot <- make_tidy_boot()
  td   <- tidy(boot)
  expect_true(all(td$selection_prob >= 0 & td$selection_prob <= 1))
})

test_that("n_selected <= B for every row", {
  boot <- make_tidy_boot()
  td   <- tidy(boot)
  expect_true(all(td$n_selected <= boot$B))
})

test_that("probs argument changes the quantile interval width", {
  boot <- make_tidy_boot()
  td95 <- tidy(boot, probs = c(0.025, 0.975))
  td80 <- tidy(boot, probs = c(0.10,  0.90))
  # 95% interval should be at least as wide as 80%
  width95 <- td95$q975 - td95$q025
  width80 <- td80$q900 - td80$q100
  expect_true(all(width95 >= width80 - 1e-10))
})

test_that("probs produces correctly named quantile columns", {
  boot <- make_tidy_boot()
  td   <- tidy(boot, probs = c(0.05, 0.95))
  expect_true("q050" %in% names(td))
  expect_true("q950" %in% names(td))
})

test_that("invalid probs is rejected", {
  boot <- make_tidy_boot()
  expect_error(tidy(boot, probs = c(1.5, 0.5)), "probs")
  expect_error(tidy(boot, probs = numeric(0)),   "probs")
})

# ---- stability_score --------------------------------------------------------

test_that("stability_score equals selection_prob when store_path = FALSE", {
  boot <- make_tidy_boot(store_path = FALSE)
  td   <- tidy(boot)
  expect_equal(td$stability_score, td$selection_prob)
})

test_that("stability_score is in [0, 1] when store_path = TRUE", {
  boot <- make_tidy_boot(store_path = TRUE)
  td   <- tidy(boot)
  expect_true(all(td$stability_score >= 0 & td$stability_score <= 1))
})

# ---- Gelman scaling ---------------------------------------------------------

test_that("scale = 'gelman' multiplies mean by 2*sd(predictor)", {
  boot   <- make_tidy_boot()
  td_raw <- tidy(boot, scale = "raw")
  td_gel <- tidy(boot, scale = "gelman")

  data   <- boot$fit$spec$data
  # Check one numeric predictor (x1) that is always selected
  term   <- "x1"
  if (!term %in% td_raw$term) skip("x1 not in tidy output for this seed")

  est_raw <- td_raw$mean[td_raw$term == term]
  est_gel <- td_gel$mean[td_gel$term == term]
  sf_expected <- 2 * stats::sd(data[[term]])

  expect_equal(est_gel / est_raw, sf_expected, tolerance = 1e-10)
})

test_that("scale = 'raw' and scale = 'gelman' differ on numeric predictors", {
  boot   <- make_tidy_boot()
  td_raw <- tidy(boot, scale = "raw")
  td_gel <- tidy(boot, scale = "gelman")
  # At least one row should differ
  expect_false(isTRUE(all.equal(td_raw$mean, td_gel$mean)))
})

# ---- glance() ---------------------------------------------------------------

test_that("glance.lb_boot returns a one-row tibble with expected columns", {
  boot <- make_tidy_boot()
  gl   <- glance(boot)
  expect_equal(nrow(gl), 1L)
  expected_cols <- c("n", "B", "lambda", "lambda_mad", "mean_n_selected",
                     "sd_n_selected", "dev_ratio", "elapsed_sec",
                     "sigma_method", "fold_spec")
  expect_named(gl, expected_cols)
})

test_that("glance B matches boot$B", {
  boot <- make_tidy_boot(B = 20L)
  gl   <- glance(boot)
  expect_equal(gl$B, 20L)
})

test_that("glance mean_n_selected is non-negative", {
  boot <- make_tidy_boot()
  gl   <- glance(boot)
  expect_gte(gl$mean_n_selected, 0)
})

test_that("glance dev_ratio is in [0, 1]", {
  boot <- make_tidy_boot()
  gl   <- glance(boot)
  expect_gte(gl$dev_ratio, 0)
  expect_lte(gl$dev_ratio, 1)
})

# ---- augment() --------------------------------------------------------------

test_that("augment.lb_boot returns original data plus .fitted/.lower/.upper", {
  boot <- make_tidy_boot()
  ag   <- augment(boot)
  data <- boot$fit$spec$data
  expect_equal(nrow(ag), nrow(data))
  expect_true(all(c(".fitted", ".lower", ".upper") %in% names(ag)))
})

test_that("augment.lb_boot with newdata augments that data", {
  boot    <- make_tidy_boot()
  newdata <- boot$fit$spec$data[1:5, ]
  ag      <- augment(boot, newdata = newdata)
  expect_equal(nrow(ag), 5L)
  expect_true(".fitted" %in% names(ag))
})
