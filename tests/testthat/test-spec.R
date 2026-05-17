test_that("lb_spec rejects non-formula", {
  expect_error(
    lb_spec("y ~ x", data = data.frame(y = 1, x = 1)),
    "two-sided formula"
  )
})

test_that("lb_spec rejects one-sided formula", {
  expect_error(
    lb_spec(~ x, data = data.frame(x = 1)),
    "two-sided formula"
  )
})

test_that("lb_spec rejects non-data-frame data", {
  expect_error(lb_spec(y ~ x, data = list(y = 1, x = 1)), "data frame")
})

test_that("lb_spec rejects missing response column", {
  df <- data.frame(x = rnorm(10))
  expect_error(lb_spec(y ~ x, data = df), "y")
})

test_that("lb_spec rejects non-numeric response", {
  df <- data.frame(y = letters[1:10], x = rnorm(10), stringsAsFactors = FALSE)
  expect_error(lb_spec(y ~ x, data = df), "numeric")
})

test_that("lb_spec validates uncertainty terms", {
  df <- data.frame(y = rnorm(10), x = rnorm(10))
  u  <- lb_uncertainty(z = std(0.1))   # 'z' not in data
  expect_error(lb_spec(y ~ x, data = df, uncertainty = u), "z")
})

test_that("lb_spec fires derive overwrite message once", {
  df <- data.frame(y = rnorm(10), x = rnorm(10), vol = rnorm(10))
  d  <- list(lb_derive(vol = x * 2))
  # expect_message captures the first matching message; don't suppress inside it
  expect_message(lb_spec(y ~ x, data = df, derive = d), "vol")
})

test_that("lb_spec emits constraint inference message", {
  df <- data.frame(y = abs(rnorm(10)) + 1, x = abs(rnorm(10)))
  expect_message(lb_spec(y ~ x, data = df), "Inferred")
})

test_that("lb_spec rejects non-lb_constraints constraints argument", {
  df <- data.frame(y = rnorm(10), x = rnorm(10))
  expect_error(
    suppressMessages(lb_spec(y ~ x, data = df, constraints = list(x = c(0, 1)))),
    "lb_constraints"
  )
})

test_that("lb_spec rejects non-function folds argument", {
  df <- data.frame(y = rnorm(10), x = rnorm(10))
  expect_error(suppressMessages(lb_spec(y ~ x, data = df, folds = 5)), "fold")
})

test_that("lb_spec rejects non-lb_control control argument", {
  df <- data.frame(y = rnorm(10), x = rnorm(10))
  expect_error(
    suppressMessages(lb_spec(y ~ x, data = df, control = list())),
    "lb_control"
  )
})

test_that("lb_spec returns lb_spec with expected fields", {
  df   <- data.frame(y = rnorm(20), x = rnorm(20))
  spec <- suppressMessages(lb_spec(y ~ x, data = df))
  expect_s3_class(spec, "lb_spec")
  expect_named(spec, c("formula", "data", "uncertainty", "derive",
                        "constraints", "folds", "engine", "control"))
  expect_null(spec$uncertainty)
  expect_null(spec$derive)
})

test_that("lb_spec merges explicit and inferred constraints", {
  df <- data.frame(y = rnorm(10) + 5,
                   x1 = abs(rnorm(10)),    # non-negative
                   x2 = rnorm(10))          # signed
  con  <- lb_constraints(x1 = c(0, 100))   # explicit for x1
  spec <- suppressMessages(lb_spec(y ~ x1 + x2, data = df, constraints = con))
  expect_equal(spec$constraints[["x1"]], c(0, 100))  # explicit wins
  expect_true("x2" %in% names(spec$constraints))     # inferred for x2
})

test_that("lb_spec RE-term detection errors when lme4 or reformulas is available", {
  skip_if(
    !requireNamespace("reformulas", quietly = TRUE) &&
      !requireNamespace("lme4", quietly = TRUE),
    "neither reformulas nor lme4 installed"
  )
  df <- data.frame(y = rnorm(20), x = rnorm(20), g = rep(letters[1:4], 5))
  expect_error(lb_spec(y ~ x + (1 | g), data = df), "Random-effect")
})

test_that("print.lb_spec produces non-empty output", {
  df   <- data.frame(y = rnorm(20), x = rnorm(20))
  spec <- suppressMessages(lb_spec(y ~ x, data = df))
  out  <- capture.output(print(spec))
  expect_true(any(nchar(out) > 0))
  expect_true(any(grepl("lb_spec", out)))
})
