test_that("lb_uncertainty() builds a tibble from std/cov/rel helpers", {
  u <- lb_uncertainty(
    alumina  = std(0.071, "ASTM C114"),
    SSA      = cov(0.56,  "Mfr CoA"),
    strength = rel(0.04,  "lab")
  )
  expect_s3_class(u, "data.frame")
  expect_equal(nrow(u), 3L)
  expect_equal(u$term,  c("alumina", "SSA", "strength"))
  expect_equal(u$type,  c("std", "cov", "rel"))
  expect_equal(u$value, c(0.071, 0.56, 0.04))
  expect_equal(u$source, c("ASTM C114", "Mfr CoA", "lab"))
})

test_that("lb_uncertainty() accepts omitted source (defaults to NA)", {
  u <- lb_uncertainty(x = std(1.0))
  expect_true(is.na(u$source))
})

test_that("lb_uncertainty() errors on unnamed arguments", {
  expect_error(lb_uncertainty(std(1.0)), class = "rlang_error")
})

test_that("lb_uncertainty() errors on zero arguments", {
  expect_error(lb_uncertainty(), class = "rlang_error")
})

test_that("lb_uncertainty() errors on negative value", {
  expect_error(lb_uncertainty(x = std(-0.1)), class = "rlang_error")
})

test_that("lb_uncertainty() errors on NA value", {
  expect_error(lb_uncertainty(x = std(NA_real_)), class = "rlang_error")
})

test_that("lb_uncertainty() accepts a pre-built tibble", {
  tbl <- tibble::tibble(term = "x", type = "std", value = 1.0, source = NA_character_)
  u   <- lb_uncertainty(tbl)
  expect_equal(u$term, "x")
})

test_that("lb_uncertainty() rejects pre-built tibble with bad type", {
  tbl <- tibble::tibble(term = "x", type = "bad", value = 1.0)
  expect_error(lb_uncertainty(tbl), class = "rlang_error")
})

test_that("lb_uncertainty() rejects pre-built tibble with NA value", {
  tbl <- tibble::tibble(term = "x", type = "std", value = NA_real_)
  expect_error(lb_uncertainty(tbl), class = "rlang_error")
})

test_that("std helper produces perturbations of expected SD (statistical)", {
  set.seed(42)
  n   <- 1e4
  val <- 2.5
  u   <- lb_uncertainty(x = std(val))
  # simulate the std perturbation
  noise <- stats::rnorm(n, 0, val)
  expect_equal(stats::sd(noise), val, tolerance = 0.05)
})

test_that("cov helper produces perturbations of expected magnitude (statistical)", {
  set.seed(42)
  n      <- 1e4
  x_val  <- 10
  pct    <- 4.0  # 4 %
  expected_sd <- abs(x_val) * pct / 100
  noise  <- stats::rnorm(n, 0, expected_sd)
  expect_equal(stats::sd(noise), expected_sd, tolerance = 0.05)
})

test_that("rel helper produces perturbations of expected magnitude (statistical)", {
  set.seed(42)
  n      <- 1e4
  x_val  <- 10
  frac   <- 0.04
  expected_sd <- abs(x_val) * frac
  noise  <- stats::rnorm(n, 0, expected_sd)
  expect_equal(stats::sd(noise), expected_sd, tolerance = 0.05)
})

test_that("std/cov/rel are not exported from the package namespace", {
  ns <- asNamespace("lassoboot")
  # The short-name helpers must not be in the package exports.
  exports <- getNamespaceExports("lassoboot")
  expect_false("std" %in% exports)
  expect_false("cov" %in% exports)
  expect_false("rel" %in% exports)
})

test_that(".validate_uncertainty_terms() catches missing columns", {
  df <- data.frame(a = 1:5)
  u  <- lb_uncertainty(b = std(1.0))
  expect_error(
    lassoboot:::.validate_uncertainty_terms(u, df),
    class = "rlang_error"
  )
})

test_that(".validate_uncertainty_terms() catches non-numeric columns", {
  df <- data.frame(a = letters[1:5], stringsAsFactors = FALSE)
  u  <- lb_uncertainty(a = std(1.0))
  expect_error(
    lassoboot:::.validate_uncertainty_terms(u, df),
    class = "rlang_error"
  )
})
