test_that("lb_constraints() returns an lb_constraints object", {
  c1 <- lb_constraints(alumina = c(0, 100), SSA = c(0, Inf))
  expect_s3_class(c1, "lb_constraints")
  expect_equal(c1$alumina, c(0, 100))
  expect_equal(c1$SSA, c(0, Inf))
})

test_that("lb_constraints() errors on unnamed arguments", {
  expect_error(lb_constraints(c(0, 1)), class = "rlang_error")
})

test_that("lb_constraints() errors on no arguments", {
  expect_error(lb_constraints(), class = "rlang_error")
})

test_that("lb_constraints() errors when lower > upper", {
  expect_error(lb_constraints(x = c(10, 0)), class = "rlang_error")
})

test_that("lb_constraints() errors when argument is not length-2 numeric", {
  expect_error(lb_constraints(x = c(0, 1, 2)), class = "rlang_error")
  expect_error(lb_constraints(x = "bad"),       class = "rlang_error")
})

test_that(".apply_constraints() clips values to [lower, upper]", {
  df <- data.frame(x = c(-1, 0, 50, 101, 200))
  cs <- list(x = c(0, 100))
  out <- lassoboot:::.apply_constraints(df, cs)
  expect_equal(out$x, c(0, 0, 50, 100, 100))
})

test_that(".apply_constraints() clips at lower bound", {
  df  <- data.frame(x = c(-5, -1, 0, 3))
  cs  <- list(x = c(0, Inf))
  out <- lassoboot:::.apply_constraints(df, cs)
  expect_equal(out$x, c(0, 0, 0, 3))
})

test_that(".apply_constraints() passes through c(-Inf, Inf) unchanged", {
  df  <- data.frame(x = c(-5, 0, 5))
  cs  <- list(x = c(-Inf, Inf))
  out <- lassoboot:::.apply_constraints(df, cs)
  expect_equal(out$x, df$x)
})

test_that(".apply_constraints() ignores columns not in constraints", {
  df  <- data.frame(x = c(-1, 2), y = c(200, 300))
  cs  <- list(x = c(0, Inf))
  out <- lassoboot:::.apply_constraints(df, cs)
  expect_equal(out$y, df$y)  # y untouched
  expect_equal(out$x, c(0, 2))
})

test_that(".infer_constraints() infers c(0, Inf) for all-positive columns", {
  df   <- data.frame(a = c(1, 2, 3), b = c(-1, 0, 1))
  msgs <- character(0L)
  # Capture output without printing
  out  <- suppressMessages(
    lassoboot:::.infer_constraints(df, list(), c("a", "b"))
  )
  expect_equal(out$a, c(0, Inf))
  expect_equal(out$b, c(-Inf, Inf))
})

test_that(".infer_constraints() emits a cli message listing inferences", {
  df <- data.frame(a = c(1, 2))
  expect_message(
    lassoboot:::.infer_constraints(df, list(), "a")
  )
})

test_that(".infer_constraints() groups message by constraint type", {
  df  <- data.frame(pos = c(1, 2), neg = c(-1, 1))
  msg <- capture.output(
    suppressMessages(
      withCallingHandlers(
        lassoboot:::.infer_constraints(df, list(), c("pos", "neg")),
        message = function(m) {
          cat(conditionMessage(m))
          invokeRestart("muffleMessage")
        }
      )
    )
  )
  combined <- paste(msg, collapse = " ")
  # Both constraint types should appear in ONE message, not two separate ones
  expect_match(combined, "c\\(0, Inf\\)")
  expect_match(combined, "c\\(-Inf, Inf\\)")
})

test_that(".infer_constraints() does not infer for columns in explicit constraints", {
  df   <- data.frame(a = c(1, 2))
  expl <- list(a = c(0, 100))
  out  <- suppressMessages(
    lassoboot:::.infer_constraints(df, expl, "a")
  )
  expect_equal(length(out), 0L)   # nothing inferred; a is already explicit
})

test_that(".merge_constraints() combines explicit and inferred", {
  expl <- list(a = c(0, 100))
  inf  <- list(b = c(0, Inf))
  out  <- lassoboot:::.merge_constraints(expl, inf)
  expect_equal(out$a, c(0, 100))
  expect_equal(out$b, c(0, Inf))
})
