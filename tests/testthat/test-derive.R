test_that("lb_derive() returns an lb_derive object", {
  d <- lb_derive(vol = mass / density)
  expect_s3_class(d, "lb_derive")
  expect_equal(d$name, "vol")
})

test_that("lb_derive() errors on zero arguments", {
  expect_error(lb_derive(), class = "rlang_error")
})

test_that("lb_derive() errors on more than one argument", {
  expect_error(lb_derive(a = x + 1, b = y + 2), class = "rlang_error")
})

test_that("lb_derive() errors on unnamed argument", {
  expect_error(lb_derive(x + 1), class = "rlang_error")
})

test_that(".apply_derives() adds a new column correctly", {
  df  <- data.frame(mass = c(10, 20), density = c(2, 4))
  drv <- list(lb_derive(volume = mass / density))
  out <- lassoboot:::.apply_derives(df, drv)
  expect_equal(out$volume, c(5, 5))
})

test_that(".apply_derives() chained derives work", {
  df  <- data.frame(mass_A = c(10, 20), mass_B = c(5, 10), density = c(2, 4))
  drv <- list(
    lb_derive(vol_A  = mass_A / density),
    lb_derive(vol_B  = mass_B / density),
    lb_derive(vol_total = vol_A + vol_B)
  )
  out <- lassoboot:::.apply_derives(df, drv)
  expect_equal(out$vol_A,     c(5, 5))
  expect_equal(out$vol_B,     c(2.5, 2.5))
  expect_equal(out$vol_total, c(7.5, 7.5))
})

test_that(".apply_derives() overwrites existing column", {
  df  <- data.frame(x = c(1, 2), y = c(10, 20))
  drv <- list(lb_derive(y = x * 3))
  out <- lassoboot:::.apply_derives(df, drv)
  expect_equal(out$y, c(3, 6))
})

test_that(".apply_derives() re-raises error with context", {
  df  <- data.frame(x = c(1, 2))
  drv <- list(lb_derive(z = stop("boom")))
  expect_error(
    lassoboot:::.apply_derives(df, drv),
    class = "rlang_error"
  )
})

test_that(".apply_derives() errors on wrong-length RHS", {
  df  <- data.frame(x = 1:5)
  drv <- list(lb_derive(z = mean(x)))   # returns length-1 scalar
  expect_error(
    lassoboot:::.apply_derives(df, drv),
    class = "rlang_error"
  )
})

test_that(".apply_derives() emits overwrite message when quiet=FALSE", {
  df  <- data.frame(x = 1:3, y = 10:12)
  drv <- list(lb_derive(y = x * 2))   # y already exists
  expect_message(
    lassoboot:::.apply_derives(df, drv,
                               existing_cols = names(df),
                               quiet = FALSE)
  )
})

test_that(".apply_derives() returns data unchanged on empty list", {
  df  <- data.frame(x = 1:3)
  out <- lassoboot:::.apply_derives(df, list())
  expect_identical(out, df)
})

test_that(".apply_derives() derive sees perturbed column value", {
  # Simulate: mass has been perturbed; volume should reflect the perturbed mass
  df  <- data.frame(mass = c(12, 22), density = c(2, 4))  # 'perturbed' mass
  drv <- list(lb_derive(volume = mass / density))
  out <- lassoboot:::.apply_derives(df, drv)
  expect_equal(out$volume, df$mass / df$density)
})
