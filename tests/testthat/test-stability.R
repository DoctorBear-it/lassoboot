make_stab_boot <- function(n = 60, p = 4, data_seed = 1L, B = 30L,
                            store_path = TRUE) {
  set.seed(data_seed)
  mat <- matrix(rnorm(n * p), n, p)
  df  <- as.data.frame(mat)
  names(df) <- paste0("x", seq_len(p))
  df$y <- df$x1 * 2 + df$x2 + rnorm(n, sd = 0.5)
  spec <- suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(n_lambda = 10L, cv_reps = 2L,
                                 store_path = store_path))
  )
  withr::with_seed(99L, lb_bootstrap(spec, B = B))
}

# ---- lb_stability() ---------------------------------------------------------

test_that("lb_stability rejects non-lb_boot input", {
  expect_error(lb_stability(list()), "lb_boot")
})

test_that("lb_stability with store_path=TRUE returns expected columns", {
  boot <- make_stab_boot()
  stab <- lb_stability(boot)
  expected <- c("term", "max_selection_prob", "lambda_at_max",
                "lambda_range_low", "lambda_range_high", "n_lambda_above_half")
  expect_named(stab, expected)
})

test_that("lb_stability has one row per non-intercept design-matrix term", {
  boot <- make_stab_boot()
  stab <- lb_stability(boot)
  expect_equal(nrow(stab), ncol(boot$fit$x))
  expect_false("(Intercept)" %in% stab$term)
})

test_that("lb_stability max_selection_prob is in [0, 1]", {
  boot <- make_stab_boot()
  stab <- lb_stability(boot)
  expect_true(all(stab$max_selection_prob >= 0))
  expect_true(all(stab$max_selection_prob <= 1))
})

test_that("lb_stability when store_path=FALSE returns stability_score = selection_prob", {
  boot <- make_stab_boot(store_path = FALSE)
  stab <- lb_stability(boot)
  td   <- tidy(boot)
  # stability output's max_selection_prob should equal tidy selection_prob
  # for terms that appear in both
  common <- intersect(stab$term, td$term)
  stab_sub <- stab$max_selection_prob[match(common, stab$term)]
  tidy_sub <- td$selection_prob[match(common, td$term)]
  expect_equal(stab_sub, tidy_sub)
})

test_that("lb_stability lambda_at_max is NA when store_path=FALSE", {
  boot <- make_stab_boot(store_path = FALSE)
  stab <- lb_stability(boot)
  expect_true(all(is.na(stab$lambda_at_max)))
})

# ---- lb_correlated_pairs() --------------------------------------------------

test_that("lb_correlated_pairs rejects non-lb_boot input", {
  expect_error(lb_correlated_pairs(list()), "lb_boot")
})

test_that("lb_correlated_pairs flags a genuinely split correlated pair (deterministic)", {
  # Build a minimal fake lb_boot with hand-crafted coef_tbl so the test does not
  # depend on bootstrap RNG.  Math: prob_1 = prob_2 = 0.5, prob_either = 1.0.
  # With cor_threshold = 0.9 and prob_threshold = 0.6:
  #   max(p1, p2) = 0.5 < 0.6  -> guard does NOT skip
  #   p_either = 1.0 > 0.6     -> row is added
  # Expected result: exactly one row flagging (x1, x2).
  z <- seq_len(80L)   # deterministic; cor(x1, x2) > 0.99 with tiny noise
  fake_boot <- withr::with_seed(7L, {
    structure(
      list(
        B        = 60L,
        coef_tbl = tibble::tibble(
          iteration = c(seq_len(30L), seq_len(30L) + 30L),
          term      = c(rep("x1", 30L), rep("x2", 30L)),
          estimate  = c(rep( 1.0, 30L), rep(-1.0, 30L))
        ),
        path_coefs = NULL,
        fit = list(
          x = `colnames<-`(
            matrix(c(z + rnorm(80L, sd = 0.05),
                     z + rnorm(80L, sd = 0.05)), 80L, 2L),
            c("x1", "x2")
          ),
          lambda_path = NULL,
          lambda      = 0.1,
          spec        = list(data = data.frame(x1 = numeric(0L),
                                               x2 = numeric(0L)))
        )
      ),
      class = c("lb_boot", "lb_fit", "lb_spec")
    )
  })

  result <- lb_correlated_pairs(fake_boot, cor_threshold = 0.9, prob_threshold = 0.6)
  expect_equal(nrow(result), 1L)
  expect_true("x1" %in% c(result$term_1, result$term_2))
  expect_true("x2" %in% c(result$term_1, result$term_2))
  expect_gte(result$prob_either[1L], 0.6)
})

test_that("lb_correlated_pairs returns empty tibble for uncorrelated data", {
  set.seed(3L)
  n  <- 60
  df <- data.frame(
    x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n), x4 = rnorm(n),
    y  = rnorm(n, sd = 1)
  )
  spec  <- suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(n_lambda = 10L, cv_reps = 2L))
  )
  boot  <- withr::with_seed(22L, lb_bootstrap(spec, B = 30L))
  pairs <- lb_correlated_pairs(boot, cor_threshold = 0.99)
  expect_equal(nrow(pairs), 0L)
})

# ---- lb_is_significant() ----------------------------------------------------

test_that("lb_is_significant returns a logical vector", {
  boot <- make_stab_boot()
  td   <- tidy(boot)
  expect_type(lb_is_significant(td, method = "ci"),        "logical")
  expect_type(lb_is_significant(td, method = "selection"), "logical")
  expect_type(lb_is_significant(td, method = "stability"), "logical")
  expect_type(lb_is_significant(td, method = "all"),       "logical")
})

test_that("lb_is_significant length equals nrow(tidy_df)", {
  boot <- make_stab_boot()
  td   <- tidy(boot)
  for (m in c("ci", "selection", "stability", "all")) {
    expect_equal(length(lb_is_significant(td, method = m)), nrow(td))
  }
})

test_that("lb_is_significant 'ci' flags terms whose CI excludes zero", {
  boot <- make_stab_boot()
  td   <- tidy(boot)
  sig  <- lb_is_significant(td, method = "ci")
  manual <- td$conf.low > 0 | td$conf.high < 0
  expect_equal(sig, manual)
})

test_that("lb_is_significant 'selection' respects threshold", {
  boot <- make_stab_boot()
  td   <- tidy(boot)
  sig  <- lb_is_significant(td, method = "selection", threshold = 0.5)
  expect_equal(sig, td$selection_prob >= 0.5)
})

test_that("lb_is_significant 'all' is conjunction of all three", {
  boot <- make_stab_boot()
  td   <- tidy(boot)
  th   <- 0.5
  sig_all <- lb_is_significant(td, method = "all", threshold = th)
  ci_sig  <- td$conf.low > 0 | td$conf.high < 0
  sel_sig <- td$selection_prob >= th
  stb_sig <- td$stability_score >= th
  expect_equal(sig_all, ci_sig & sel_sig & stb_sig)
})
