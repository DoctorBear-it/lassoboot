test_that("package loads cleanly", {
  expect_true(requireNamespace("lassoboot", quietly = TRUE))
})
