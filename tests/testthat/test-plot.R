# Snapshots for this file are stored in tests/testthat/_snaps/test-plot/
# (vdiffr default for test-plot.R), not _snaps/visual/ as in spec §9.3.

# ---- Fixtures ----------------------------------------------------------------

make_plot_boot <- function(n = 60, p = 4, data_seed = 1L, B = 30L,
                            store_path = TRUE, ...) {
  set.seed(data_seed)
  mat <- matrix(rnorm(n * p), n, p)
  df  <- as.data.frame(mat)
  names(df) <- paste0("x", seq_len(p))
  df$y <- df$x1 * 2 + df$x2 + rnorm(n, sd = 0.5)
  spec <- suppressMessages(
    lb_spec(y ~ ., data = df,
            control = lb_control(n_lambda = 10L, cv_reps = 2L,
                                 store_path = store_path, ...))
  )
  withr::with_seed(42L, lb_bootstrap(spec, B = B))
}

make_plot_boot_interactions <- function(n = 60, data_seed = 2L, B = 30L, ...) {
  set.seed(data_seed)
  df <- data.frame(
    x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n), x4 = rnorm(n)
  )
  df$y <- df$x1 * 2 + df$x2 + df$x1 * df$x2 * 0.5 + rnorm(n, sd = 0.5)
  spec <- suppressMessages(
    lb_spec(y ~ x1 * x2 + x3 + x4, data = df,
            control = lb_control(n_lambda = 10L, cv_reps = 2L, ...))
  )
  withr::with_seed(55L, lb_bootstrap(spec, B = B))
}

# ---- Interaction fixture sanity check ----------------------------------------
# Verify that model.matrix expands y ~ x1 * x2 + x3 + x4 to include an
# x1:x2 column before any interaction-plot tests rely on it.

test_that("interaction fixture produces x1:x2 design-matrix column", {
  boot <- make_plot_boot_interactions()
  expect_true("x1:x2" %in% colnames(boot$fit$x))
})

# ---- autoplot.lb_boot() dispatcher ------------------------------------------

test_that("autoplot returns a ggplot for type='coefficients' (default)", {
  boot <- make_plot_boot()
  p    <- autoplot(boot)
  expect_s3_class(p, "ggplot")
})

test_that("autoplot returns a ggplot for type='selection'", {
  boot <- make_plot_boot()
  p    <- autoplot(boot, type = "selection")
  expect_s3_class(p, "ggplot")
})

test_that("autoplot returns a ggplot for type='complexity'", {
  boot <- make_plot_boot()
  p    <- autoplot(boot, type = "complexity")
  expect_s3_class(p, "ggplot")
})

test_that("autoplot dispatches type='prediction' with focal through ...", {
  boot <- make_plot_boot()
  p    <- autoplot(boot, type = "prediction", focal = "x1", n = 20)
  expect_s3_class(p, "ggplot")
})

# ---- lb_plot_coefficients() --------------------------------------------------

test_that("lb_plot_coefficients returns a ggplot", {
  boot <- make_plot_boot()
  p    <- lb_plot_coefficients(boot)
  expect_s3_class(p, "ggplot")
})

test_that("lb_plot_coefficients has GeomLinerange, GeomPoint, GeomVline", {
  boot         <- make_plot_boot()
  p            <- lb_plot_coefficients(boot)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true(all(c("GeomLinerange", "GeomPoint", "GeomVline") %in% geom_classes))
})

test_that("lb_plot_coefficients filter='significant' returns <= nrow(filter='all')", {
  boot   <- make_plot_boot()
  p_all  <- lb_plot_coefficients(boot, filter = "all")
  p_sig  <- lb_plot_coefficients(boot, filter = "significant")
  n_all  <- nrow(p_all$data)
  n_sig  <- nrow(p_sig$data)
  expect_lte(n_sig, n_all)
})

test_that("lb_plot_coefficients filter='selected' returns <= nrow(filter='all')", {
  boot   <- make_plot_boot()
  p_all  <- lb_plot_coefficients(boot, filter = "all")
  p_sel  <- lb_plot_coefficients(boot, filter = "selected")
  n_all  <- nrow(p_all$data)
  n_sel  <- nrow(p_sel$data)
  expect_lte(n_sel, n_all)
})

test_that("lb_plot_coefficients scale='gelman' differs from scale='raw'", {
  boot   <- make_plot_boot()
  p_raw  <- lb_plot_coefficients(boot, scale = "raw")
  p_gel  <- lb_plot_coefficients(boot, scale = "gelman")
  expect_false(isTRUE(all.equal(p_raw$data$estimate, p_gel$data$estimate)))
})

test_that("lb_plot_coefficients vdiffr: canonical", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("coefficients-canonical",
                               lb_plot_coefficients(boot))
})

test_that("lb_plot_coefficients vdiffr: gelman + selected filter", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("coefficients-gelman-selected",
                               lb_plot_coefficients(boot,
                                                    scale  = "gelman",
                                                    filter = "selected"))
})

# ---- lb_plot_selection() -----------------------------------------------------

test_that("lb_plot_selection returns a ggplot", {
  boot <- make_plot_boot()
  p    <- lb_plot_selection(boot)
  expect_s3_class(p, "ggplot")
})

test_that("lb_plot_selection has GeomCol and GeomVline", {
  boot         <- make_plot_boot()
  p            <- lb_plot_selection(boot)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true("GeomCol" %in% geom_classes)
  expect_true("GeomVline" %in% geom_classes)
})

test_that("lb_plot_selection vdiffr: canonical", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("selection-canonical",
                               lb_plot_selection(boot))
})

test_that("lb_plot_selection vdiffr: threshold=0.8", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("selection-threshold-0.8",
                               lb_plot_selection(boot, threshold = 0.8))
})

# ---- lb_plot_stability() -----------------------------------------------------

test_that("lb_plot_stability errors when store_path=FALSE", {
  boot <- make_plot_boot(store_path = FALSE)
  expect_error(lb_plot_stability(boot), class = "rlang_error")
})

test_that("lb_plot_stability returns a ggplot when store_path=TRUE", {
  boot <- make_plot_boot()
  p    <- lb_plot_stability(boot)
  expect_s3_class(p, "ggplot")
})

test_that("lb_plot_stability has GeomLine and GeomHline", {
  boot         <- make_plot_boot()
  p            <- lb_plot_stability(boot)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true("GeomLine"  %in% geom_classes)
  expect_true("GeomHline" %in% geom_classes)
})

test_that("lb_plot_stability top_n=2 shows at most 2 terms", {
  boot      <- make_plot_boot()
  p         <- lb_plot_stability(boot, top_n = 2L)
  n_terms   <- length(unique(p$data$term))
  expect_lte(n_terms, 2L)
})

test_that("lb_plot_stability vdiffr: canonical", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("stability-canonical",
                               lb_plot_stability(boot))
})

test_that("lb_plot_stability vdiffr: top2", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("stability-top2",
                               lb_plot_stability(boot, top_n = 2L))
})

# ---- lb_plot_interactions() --------------------------------------------------

test_that("lb_plot_interactions returns a ggplot silently when no interactions", {
  boot <- make_plot_boot()   # y ~ . has no interaction terms
  expect_no_message(p <- lb_plot_interactions(boot))
  expect_s3_class(p, "ggplot")
})

test_that("lb_plot_interactions returns a ggplot with GeomTile when interactions present", {
  boot         <- make_plot_boot_interactions()
  p            <- lb_plot_interactions(boot)
  expect_s3_class(p, "ggplot")
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true("GeomTile" %in% geom_classes)
})

test_that("lb_plot_interactions vdiffr: no-terms (base fixture)", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("interactions-no-terms",
                               lb_plot_interactions(boot))
})

test_that("lb_plot_interactions vdiffr: canonical (interaction fixture)", {
  boot <- make_plot_boot_interactions()
  vdiffr::expect_doppelganger("interactions-canonical",
                               lb_plot_interactions(boot))
})

# ---- lb_plot_prediction() ----------------------------------------------------

test_that("lb_plot_prediction returns a ggplot", {
  boot <- make_plot_boot()
  p    <- lb_plot_prediction(boot, focal = "x1", n = 20)
  expect_s3_class(p, "ggplot")
})

test_that("lb_plot_prediction has GeomRibbon and GeomLine", {
  boot         <- make_plot_boot()
  p            <- lb_plot_prediction(boot, focal = "x1", n = 20)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true("GeomRibbon" %in% geom_classes)
  expect_true("GeomLine"   %in% geom_classes)
})

test_that("lb_plot_prediction raw_data overlay adds GeomPoint", {
  boot     <- make_plot_boot()
  raw      <- boot$fit$spec$data
  p        <- lb_plot_prediction(boot, focal = "x1", raw_data = raw, n = 20)
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true("GeomPoint" %in% geom_classes)
})

test_that("lb_plot_prediction by= adds FacetWrap", {
  boot <- make_plot_boot()
  p    <- lb_plot_prediction(boot, focal = "x1", n = 20, by = ggplot2::vars(x2))
  expect_s3_class(p$facet, "FacetWrap")
})

test_that("lb_plot_prediction vdiffr: canonical", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("prediction-canonical",
                               lb_plot_prediction(boot, focal = "x1", n = 20))
})

test_that("lb_plot_prediction vdiffr: with raw_data overlay", {
  boot <- make_plot_boot()
  raw  <- boot$fit$spec$data
  vdiffr::expect_doppelganger("prediction-with-raw-data",
                               lb_plot_prediction(boot, focal = "x1",
                                                  raw_data = raw, n = 20))
})

# ---- lb_plot_complexity() ----------------------------------------------------

test_that("lb_plot_complexity returns a ggplot", {
  boot <- make_plot_boot()
  p    <- lb_plot_complexity(boot)
  expect_s3_class(p, "ggplot")
})

test_that("lb_plot_complexity uses StatBin (histogram) and has GeomVline", {
  boot         <- make_plot_boot()
  p            <- lb_plot_complexity(boot)
  stat_classes <- vapply(p$layers, function(l) class(l$stat)[1L], character(1L))
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true("StatBin"  %in% stat_classes)
  expect_true("GeomVline" %in% geom_classes)
})

test_that("lb_plot_complexity vdiffr: canonical", {
  boot <- make_plot_boot()
  vdiffr::expect_doppelganger("complexity-canonical",
                               lb_plot_complexity(boot))
})

test_that("lb_plot_complexity vdiffr: B=50", {
  boot <- make_plot_boot(B = 50L)
  vdiffr::expect_doppelganger("complexity-B50",
                               lb_plot_complexity(boot))
})
