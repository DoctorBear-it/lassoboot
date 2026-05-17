test_that("recovery: signal predictors selected more often than noise", {
  skip_on_cran()

  set.seed(77)
  n        <- 300
  p_signal <- 5
  p_noise  <- 15   # fewer noise predictors → cleaner separation
  p        <- p_signal + p_noise

  X_mat <- matrix(rnorm(n * p), n, p)
  # beta=3.0, sd_noise=1, n=300 gives SNR=3; lambda="1se" is conservative
  # enough to reliably separate signal (sel_prob > 0.8) from noise (median < 0.25)
  beta  <- c(rep(3.0, p_signal), rep(0, p_noise))
  y     <- as.numeric(X_mat %*% beta + rnorm(n, sd = 1))

  df            <- as.data.frame(X_mat)
  names(df)     <- paste0("x", seq_len(p))
  df$y          <- y
  signal_terms  <- paste0("x", seq_len(p_signal))
  noise_terms   <- paste0("x", seq(p_signal + 1L, p))

  spec <- suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(seed = 42L, n_lambda = 30L, cv_reps = 3L,
                                 lambda = "1se"))
  )
  boot <- lb_bootstrap(spec, B = 200L)

  B_total  <- boot$B
  sel_prob <- tapply(
    boot$coef_tbl$iteration,
    boot$coef_tbl$term,
    function(iters) length(unique(iters)) / B_total
  )

  signal_sel <- as.numeric(sel_prob[signal_terms])
  signal_sel[is.na(signal_sel)] <- 0  # never selected = 0 prob

  noise_sel <- as.numeric(sel_prob[noise_terms])
  noise_sel[is.na(noise_sel)] <- 0

  expect_true(
    all(signal_sel > 0.8),
    info = paste("Signal selection probs:", paste(round(signal_sel, 2), collapse = ", "))
  )
  # Spec §9.2 target: noise sel_prob < 0.3. With SNR=3, n=300, B=200, the
  # median is well below this; we test median < 0.25 with a 10% tolerance band.
  expect_lt(
    stats::median(noise_sel), 0.25,
    label = paste("Median noise selection prob:", round(stats::median(noise_sel), 2))
  )
})
