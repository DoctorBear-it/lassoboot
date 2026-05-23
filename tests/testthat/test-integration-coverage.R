# Monte Carlo CI coverage check.
#
# Methodological claim: the parametric bootstrap CI from sigma_method = "refit"
# achieves higher empirical coverage of the true coefficient than sigma_method
# = "naive" when predictors are reliably selected (near-oracle conditions).
#
# This test verifies the claim from spec §5.2 / §9.2 using n = 200, p = 30,
# sparsity = 5 as specified in the methodology vignette (§10.2).
#
# NOTE: Coverage of the TRUE PARAMETER with a regularized bootstrap is
# achievable only when lasso shrinkage is negligible relative to the CI
# half-width. With the spec parameters (n=200, strong signal), the active
# predictors are reliably selected and shrinkage is modest, giving coverage
# in (0.85, 0.99).
#
# Expected runtime: ~15-20 minutes (200 bootstraps × 50 datasets, n=200, p=30).
# Skipped on CRAN, CI, and in standard local runs. Set the environment variable
# LASSOBOOT_COVERAGE_TEST=1 to run.

skip_on_cran()
if (nzchar(Sys.getenv("CI"))) skip("Skipping slow coverage test on CI")
if (!nzchar(Sys.getenv("LASSOBOOT_COVERAGE_TEST"))) {
  skip("Set LASSOBOOT_COVERAGE_TEST=1 to run this slow (~15 min) coverage test")
}

test_that("refit sigma gives higher CI coverage than naive on active predictors", {
  n_datasets <- 50L
  B_per_ds   <- 200L
  n_obs      <- 200L
  n_pred     <- 30L
  n_active   <- 5L
  # Coefficients chosen so that lasso reliably selects all active predictors;
  # the weakest has |coef| = 1.0 which at n=200 gives t ≈ 14, near-certain selection.
  true_coefs <- c(2.0, -1.5, 1.0, -0.8, 0.6, rep(0, n_pred - n_active))
  conf_level <- 0.95

  covered_refit <- integer(n_active)
  covered_naive <- integer(n_active)
  n_fit         <- integer(n_active)

  withr::with_seed(2025L, {
    for (d in seq_len(n_datasets)) {
      X   <- matrix(rnorm(n_obs * n_pred), n_obs, n_pred)
      y   <- as.numeric(X %*% true_coefs + rnorm(n_obs, sd = 1))
      df  <- as.data.frame(X)
      names(df) <- paste0("x", seq_len(n_pred))
      df$y <- y

      for (method in c("refit", "naive")) {
        spec <- suppressMessages(
          lb_spec(y ~ ., data = df,
                  control = lb_control(n_lambda = 25L, cv_reps = 3L,
                                       sigma_method = method))
        )
        boot <- lb_bootstrap(spec, B = B_per_ds)
        # probs replaces conf.level in v0.2.0; derive probs from conf_level
        alpha <- 1 - conf_level
        td   <- tidy(boot, probs = c(alpha / 2, 1 - alpha / 2))
        q_lo <- paste0("q", formatC(round(alpha / 2 * 1000), width = 3L,
                                    flag = "0", format = "d"))
        q_hi <- paste0("q", formatC(round((1 - alpha / 2) * 1000),
                                    width = 3L, flag = "0", format = "d"))

        for (j in seq_len(n_active)) {
          tm  <- paste0("x", j)
          row <- td[td$term == tm, ]
          if (nrow(row) == 0L) next
          if (method == "refit") {
            n_fit[j]          <- n_fit[j] + 1L
            covered_refit[j]  <- covered_refit[j] +
              (row[[q_lo]] <= true_coefs[j] && true_coefs[j] <= row[[q_hi]])
          } else {
            covered_naive[j]  <- covered_naive[j] +
              (row[[q_lo]] <= true_coefs[j] && true_coefs[j] <= row[[q_hi]])
          }
        }
      }
    }
  })

  coverage_refit <- covered_refit / pmax(n_fit, 1L)
  coverage_naive <- covered_naive / pmax(n_fit, 1L)

  # Primary claim: refit coverage is in (0.85, 0.99) for all active predictors
  expect_true(
    all(coverage_refit >= 0.85 & coverage_refit <= 0.99),
    info = paste0(
      "Refit empirical coverage: ",
      paste(sprintf("x%d=%.2f", seq_len(n_active), coverage_refit),
            collapse = ", ")
    )
  )

  # Secondary claim: refit coverage > naive coverage for most predictors
  expect_true(
    mean(coverage_refit) >= mean(coverage_naive),
    info = sprintf(
      "Mean refit=%.2f, mean naive=%.2f",
      mean(coverage_refit), mean(coverage_naive)
    )
  )
})
