# Tests for lb_normalize()
#
# Three scenarios per the code review:
#   (a) error when measured/reference not in data
#   (b) error when measured/reference not declared in uncertainty
#   (c) end-to-end spec -> normalize -> bootstrap -> predict round trip

# --- Helper fixture -------------------------------------------------------

make_norm_data <- function(n = 30L, seed = 1L) {
  set.seed(seed)
  df <- data.frame(
    x1           = rnorm(n),
    x2           = rnorm(n),
    meas_strength = abs(rnorm(n, mean = 40, sd = 4)),
    ref_strength  = abs(rnorm(n, mean = 35, sd = 3))
  )
  # Placeholder response column required by lb_spec()
  df$strength_ratio <- NA_real_
  df
}

# --- (a) Error: measured/reference columns not in data --------------------

test_that("lb_normalize() errors when measured column is absent from data", {
  df   <- make_norm_data()
  df$strength_ratio <- NA_real_
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        meas_strength = cov(3.0),
        ref_strength  = cov(2.2)
      )
    )
  )
  expect_error(
    lb_normalize(spec,
                 response  = strength_ratio,
                 measured  = no_such_col,
                 reference = ref_strength),
    class = "rlang_error"
  )
})

test_that("lb_normalize() errors when reference column is absent from data", {
  df   <- make_norm_data()
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        meas_strength = cov(3.0),
        ref_strength  = cov(2.2)
      )
    )
  )
  expect_error(
    lb_normalize(spec,
                 response  = strength_ratio,
                 measured  = meas_strength,
                 reference = no_such_ref),
    class = "rlang_error"
  )
})

# --- (b) Error: measured/reference not declared in uncertainty ------------

test_that("lb_normalize() errors when measured column not in uncertainty", {
  df   <- make_norm_data()
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        # meas_strength deliberately omitted
        ref_strength  = cov(2.2)
      )
    )
  )
  expect_error(
    lb_normalize(spec,
                 response  = strength_ratio,
                 measured  = meas_strength,
                 reference = ref_strength),
    class = "rlang_error"
  )
})

test_that("lb_normalize() errors when reference column not in uncertainty", {
  df   <- make_norm_data()
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        meas_strength = cov(3.0)
        # ref_strength deliberately omitted
      )
    )
  )
  expect_error(
    lb_normalize(spec,
                 response  = strength_ratio,
                 measured  = meas_strength,
                 reference = ref_strength),
    class = "rlang_error"
  )
})

# --- (c) End-to-end round trip -------------------------------------------

test_that("lb_normalize() materializes response column with correct values", {
  df   <- make_norm_data()
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        meas_strength = cov(3.0),
        ref_strength  = cov(2.2)
      )
    )
  )
  spec2 <- lb_normalize(spec,
                         response  = strength_ratio,
                         measured  = meas_strength,
                         reference = ref_strength)

  expected <- df$meas_strength / df$ref_strength
  expect_equal(spec2$data$strength_ratio, expected, tolerance = 1e-12)
})

test_that("lb_normalize() registers a derive that recomputes the ratio", {
  df   <- make_norm_data()
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        meas_strength = cov(3.0),
        ref_strength  = cov(2.2)
      )
    )
  )
  spec2 <- lb_normalize(spec,
                         response  = strength_ratio,
                         measured  = meas_strength,
                         reference = ref_strength)

  expect_true(length(spec2$derive) > 0L)
  # The derive name must be the response column
  derive_names <- vapply(spec2$derive, function(d) d$name, character(1L))
  expect_true("strength_ratio" %in% derive_names)
})

test_that("lb_normalize() updates the formula LHS", {
  df   <- make_norm_data()
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        meas_strength = cov(3.0),
        ref_strength  = cov(2.2)
      )
    )
  )
  spec2 <- lb_normalize(spec,
                         response  = strength_ratio,
                         measured  = meas_strength,
                         reference = ref_strength)

  lhs <- as.character(spec2$formula[[2L]])
  expect_equal(lhs, "strength_ratio")
})

test_that("lb_normalize() spec -> bootstrap -> predict round trip succeeds", {
  df   <- make_norm_data(n = 40L)
  spec <- suppressMessages(
    lb_spec(
      strength_ratio ~ x1 + x2,
      data        = df,
      uncertainty = lb_uncertainty(
        meas_strength = cov(3.0),
        ref_strength  = cov(2.2)
      ),
      control = lb_control(n_lambda = 8L, cv_reps = 1L, store_path = FALSE)
    )
  )
  spec2 <- lb_normalize(spec,
                         response  = strength_ratio,
                         measured  = meas_strength,
                         reference = ref_strength)

  boot <- withr::with_seed(7L, lb_bootstrap(spec2, B = 10L))
  expect_s3_class(boot, "lb_boot")

  # predict() confidence interval
  preds_conf <- predict(boot, newdata = df[1:5, ], interval = "confidence")
  expect_s3_class(preds_conf, "data.frame")
  expect_true(all(c(".fitted", ".lower", ".upper") %in% names(preds_conf)))

  # predict() prediction interval
  preds_pred <- predict(boot, newdata = df[1:5, ], interval = "prediction")
  expect_s3_class(preds_pred, "data.frame")
  # Prediction intervals are at least as wide as confidence intervals
  expect_true(all(preds_pred$.upper - preds_pred$.lower >=
                  preds_conf$.upper - preds_conf$.lower - 1e-10))
})
