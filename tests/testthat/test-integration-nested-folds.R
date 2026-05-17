# ── helpers ────────────────────────────────────────────────────────────────────

# Pure-stratum fixture: each outer group has exactly one inner value.
# 6 groups × 2 ages (each group belongs to one age) × 4 rows = 24 rows.
make_pure_fixture <- function() {
  tibble::tibble(
    mixture = rep(1:6, each = 4),
    age     = rep(c(7, 7, 28, 28, 56, 56), each = 4),
    x       = rnorm(24),
    y       = rnorm(24)
  )
}

# Mixed-stratum fixture: groups 4 and 5 span two ages.
make_mixed_fixture <- function() {
  tibble::tibble(
    mixture = c(rep(1:3, each = 4),       # pure-stratum groups 1-3
                rep(4, 4), rep(5, 4)),     # mixed-stratum groups 4-5
    age     = c(rep(7,  4), rep(28, 4), rep(56, 4),   # groups 1-3 pure
                c(7, 7, 28, 28),                        # group 4: mixed
                c(28, 56, 28, 56)),                     # group 5: mixed
    x = rnorm(20),
    y = rnorm(20)
  )
}

# ── carry-forward #1: mixed-stratum error (Option A) ───────────────────────────

test_that("lb_folds_nested errors on mixed-stratum outer groups", {
  df       <- make_mixed_fixture()
  fold_gen <- lb_folds_nested(outer = "mixture", inner = "age", k_outer = 3)
  expect_error(fold_gen(df), "multiple inner values")
})

test_that("lb_folds_nested error message names the offending group", {
  df       <- make_mixed_fixture()
  fold_gen <- lb_folds_nested(outer = "mixture", inner = "age", k_outer = 3)
  err <- tryCatch(fold_gen(df), error = function(e) conditionMessage(e))
  expect_match(err, "4|5")  # offending group number appears in message
})

# ── pure-stratum: correct fold structure ───────────────────────────────────────

test_that("lb_folds_nested pure-stratum produces valid fold IDs", {
  df       <- make_pure_fixture()
  fold_gen <- lb_folds_nested(outer = "mixture", inner = "age", k_outer = 3)
  fids     <- fold_gen(df)

  expect_length(fids, nrow(df))
  expect_true(all(fids %in% seq_len(3)))
  # No empty folds
  expect_equal(sort(unique(fids)), 1:3)
})

test_that("lb_folds_nested pure-stratum: each group stays in one fold", {
  df       <- make_pure_fixture()
  fold_gen <- lb_folds_nested(outer = "mixture", inner = "age", k_outer = 3)
  fids     <- fold_gen(df)

  for (mix in unique(df$mixture)) {
    folds_for_mix <- unique(fids[df$mixture == mix])
    expect_equal(length(folds_for_mix), 1L,
                 info = paste("mixture", mix, "spans multiple folds"))
  }
})

test_that("lb_folds_nested pure-stratum: inner strata are balanced across folds", {
  # 6 groups: 2 per age (7, 28, 56), k_outer = 3 → each fold gets 1 age-7, 1 age-28, 1 age-56 group
  df       <- make_pure_fixture()
  fold_gen <- lb_folds_nested(outer = "mixture", inner = "age", k_outer = 3)

  # Run several times; inner balance should hold on average
  balanced <- replicate(20, {
    fids         <- fold_gen(df)
    group_folds  <- tapply(fids, df$mixture, unique)
    group_ages   <- tapply(df$age, df$mixture, unique)
    fold_age_tbl <- table(fold = unlist(group_folds), age = unlist(group_ages))
    # Each fold should have at most 1 group per age stratum (6 groups / 3 folds / 3 ages = 1)
    all(fold_age_tbl <= 1L)
  })
  expect_true(mean(balanced) >= 0.8)  # allow some variance from sampling
})

# ── integration: grouped vs. ungrouped CV produces different selection probs ───

test_that("grouped CV prevents leakage: initial lambda is more conservative", {
  skip_on_cran()
  set.seed(55)

  # Data: y is almost entirely determined by group identity (sd=5) with tiny
  # within-group noise (sd=0.1). The predictor `group` is a factor with 20
  # levels — its dummy variables perfectly encode group identity.
  #
  # Under ungrouped CV: all 20 factor levels appear in every training fold
  #   → lasso uses group dummies → very low CV error → small (permissive) lambda
  # Under grouped CV: 4 unseen groups per fold have zero-variance dummies in
  #   training → lasso cannot use them → high CV error → large (conservative) lambda
  #
  # The CV lambda is therefore LARGER under grouped CV — the key observable
  # consequence of preventing within-group leakage.

  n_groups <- 20L; n_per <- 10L; n <- n_groups * n_per
  group    <- factor(rep(seq_len(n_groups), each = n_per))
  y        <- rep(rnorm(n_groups, sd = 5), each = n_per) + rnorm(n, sd = 0.1)
  x_noise  <- rnorm(n)
  df       <- tibble::tibble(y = y, group = group, x_noise = x_noise)

  ctrl <- lb_control(seed = 55L, cv_reps = 3L, n_lambda = 30L, lambda = "min")

  spec_grouped <- suppressMessages(
    lb_spec(y ~ group + x_noise, data = df,
            folds   = lb_folds_grouped("group", k = 5),
            control = ctrl)
  )
  spec_ungrouped <- suppressMessages(
    lb_spec(y ~ group + x_noise, data = df,
            folds   = lb_folds_kfold(5),
            control = ctrl)
  )

  fit_grouped   <- withr::with_seed(55L, lb_fit(spec_grouped))
  fit_ungrouped <- withr::with_seed(55L, lb_fit(spec_ungrouped))

  # Grouped CV must produce a strictly larger lambda than ungrouped CV.
  # This is the lambda-level evidence that grouped CV resists within-group leakage.
  expect_gt(
    fit_grouped$lambda, fit_ungrouped$lambda,
    label = sprintf("grouped lambda (%.4f) should exceed ungrouped (%.4f)",
                    fit_grouped$lambda, fit_ungrouped$lambda)
  )
})
