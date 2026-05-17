make_df <- function(n = 30) {
  data.frame(
    x      = stats::rnorm(n),
    group  = rep(letters[1:6], length.out = n),
    age    = rep(c("7d", "28d", "56d"), length.out = n),
    block  = rep(1:5, length.out = n),
    stringsAsFactors = FALSE
  )
}

# ---- helpers ----------------------------------------------------------------

check_fold_ids <- function(ids, n, k) {
  expect_type(ids, "integer")
  expect_length(ids, n)
  expect_true(all(ids >= 1L))
  expect_true(all(ids <= k))
  for (f in seq_len(k)) {
    expect_true(any(ids == f),
                label = paste("fold", f, "is non-empty"))
  }
}

# ---- lb_folds_kfold ---------------------------------------------------------

test_that("lb_folds_kfold() returns a closure", {
  gen <- lb_folds_kfold(k = 5)
  expect_true(is.function(gen))
})

test_that("lb_folds_kfold() produces valid fold IDs", {
  set.seed(1)
  df  <- make_df(30)
  gen <- lb_folds_kfold(k = 5)
  ids <- gen(df)
  check_fold_ids(ids, 30L, 5L)
})

test_that("lb_folds_kfold() errors when n < k", {
  gen <- lb_folds_kfold(k = 20)
  expect_error(gen(make_df(5)), class = "rlang_error")
})

test_that("lb_folds_kfold() errors on k < 2", {
  expect_error(lb_folds_kfold(k = 1), class = "rlang_error")
})

# ---- lb_folds_grouped -------------------------------------------------------

test_that("lb_folds_grouped() produces valid fold IDs", {
  set.seed(1)
  df  <- make_df(30)
  gen <- lb_folds_grouped("group", k = 3)
  ids <- gen(df)
  check_fold_ids(ids, 30L, 3L)
})

test_that("lb_folds_grouped() places all rows of a group in the same fold", {
  set.seed(2)
  df  <- make_df(30)
  gen <- lb_folds_grouped("group", k = 3)
  ids <- gen(df)
  for (g in unique(df$group)) {
    folds_for_g <- unique(ids[df$group == g])
    expect_equal(length(folds_for_g), 1L,
                 label = paste("group", g, "spans only one fold"))
  }
})

test_that("lb_folds_grouped() errors when group column absent", {
  gen <- lb_folds_grouped("missing_col", k = 3)
  expect_error(gen(make_df()), class = "rlang_error")
})

test_that("lb_folds_grouped() errors when n_groups < k", {
  df  <- data.frame(x = 1:10, group = rep("a", 10), stringsAsFactors = FALSE)
  gen <- lb_folds_grouped("group", k = 5)
  expect_error(gen(df), class = "rlang_error")
})

# ---- lb_folds_nested --------------------------------------------------------

test_that("lb_folds_nested() produces valid fold IDs", {
  set.seed(3)
  df  <- make_df(30)
  gen <- lb_folds_nested(outer = "group", inner = "age", k_outer = 3)
  ids <- gen(df)
  check_fold_ids(ids, 30L, 3L)
})

test_that("lb_folds_nested() places all rows of an outer group in the same fold", {
  set.seed(4)
  df  <- make_df(30)
  gen <- lb_folds_nested(outer = "group", inner = "age", k_outer = 3)
  ids <- gen(df)
  for (g in unique(df$group)) {
    folds_for_g <- unique(ids[df$group == g])
    expect_equal(length(folds_for_g), 1L,
                 label = paste("outer group", g, "spans only one fold"))
  }
})

test_that("lb_folds_nested() errors when outer column absent", {
  gen <- lb_folds_nested(outer = "nope", k_outer = 3)
  expect_error(gen(make_df()), class = "rlang_error")
})

test_that("lb_folds_nested() errors when inner column absent", {
  gen <- lb_folds_nested(outer = "group", inner = "nope", k_outer = 3)
  expect_error(gen(make_df()), class = "rlang_error")
})

test_that("lb_folds_nested() informs when k_inner supplied", {
  expect_message(lb_folds_nested(outer = "group", k_outer = 3, k_inner = 2))
})

# ---- lb_folds_blocked -------------------------------------------------------

test_that("lb_folds_blocked() produces valid fold IDs", {
  df  <- make_df(30)
  gen <- lb_folds_blocked("block", k = 5)
  ids <- gen(df)
  check_fold_ids(ids, 30L, 5L)
})

test_that("lb_folds_blocked() assigns whole blocks to one fold", {
  df  <- make_df(30)
  gen <- lb_folds_blocked("block", k = 5)
  ids <- gen(df)
  for (b in unique(df$block)) {
    folds_for_b <- unique(ids[df$block == b])
    expect_equal(length(folds_for_b), 1L,
                 label = paste("block", b, "spans only one fold"))
  }
})

test_that("lb_folds_blocked() errors when block column absent", {
  gen <- lb_folds_blocked("nope", k = 3)
  expect_error(gen(make_df()), class = "rlang_error")
})

# ---- lb_folds_custom --------------------------------------------------------

test_that("lb_folds_custom() accepts a conforming function", {
  fn  <- function(data) rep(1L:5L, length.out = nrow(data))
  gen <- lb_folds_custom(fn)
  expect_true(is.function(gen))
  ids <- gen(make_df(30))
  check_fold_ids(ids, 30L, 5L)
})

test_that("lb_folds_custom() errors when fn is not a function", {
  expect_error(lb_folds_custom("not_a_function"), class = "rlang_error")
})

test_that("lb_folds_custom() errors when fn returns wrong length", {
  fn  <- function(data) 1L:5L    # always length 5
  gen <- lb_folds_custom(fn)
  expect_error(gen(make_df(30)), class = "rlang_error")
})

test_that("lb_folds_custom() errors when fn returns IDs containing NA", {
  fn  <- function(data) rep(NA_integer_, nrow(data))
  gen <- lb_folds_custom(fn)
  expect_error(gen(make_df(30)), class = "rlang_error")
})
