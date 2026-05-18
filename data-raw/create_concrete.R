# data-raw/create_concrete.R
# Generates the synthetic `concrete` and `uncertainty_concrete` datasets
# shipped with the lassoboot package.
#
# The structure mirrors the df_final object in the package's prototype analysis:
# limestone calcined clay cement (LC3) mixtures tested at multiple ages with
# varying clay replacement levels. Sample IDs are anonymized to integers;
# supplier names are removed. Four clay types (CC0–CC3) with distinct
# mineralogical profiles represent a realistic spread of pozzolanic reactivity.
#
# Run with: Rscript data-raw/create_concrete.R  (from the package root)
# or:       source("data-raw/create_concrete.R") in an interactive R session.

set.seed(2024L)

library(tibble)

# ---- Clay mineralogical properties (fixed per clay type) --------------------

clay_props <- tribble(
  ~clay,  ~clayHOH, ~alumina, ~SSA,  ~D50,
  "CC0",   669.4,    39.5,    22.1,   2.8,
  "CC1A",  413.1,    36.2,    14.5,   5.6,
  "CC1B",  478.8,    37.8,    17.2,   4.3,
  "CC2",   334.4,    34.6,    11.0,   8.1,
  "CC3",   541.0,    38.3,    19.5,   3.5
)

# ---- Experimental design -----------------------------------------------------

replacements <- c(10, 15, 20, 25, 30)
ages_days    <- c(7L, 28L, 56L)
wcm_fixed    <- 0.485

# Full factorial: 5 clays × 5 replacements × 3 ages = 75 rows
design <- expand.grid(
  clay        = clay_props$clay,
  replacement = replacements,
  age_days    = ages_days,
  stringsAsFactors = FALSE
)
design <- merge(design, clay_props, by = "clay")

# Assign mixture IDs: unique per (clay × replacement) combination
mix_key <- unique(design[, c("clay", "replacement")])
mix_key$mixture <- seq_len(nrow(mix_key))
design  <- merge(design, mix_key, by = c("clay", "replacement"))

# ---- Realistic strength model ------------------------------------------------
# strength_MPa(age, clay, replacement) is generated from a plausible
# semi-empirical model:
#   base_28d  ~ 47 MPa for pure cement (wcm = 0.485)
#   age_mult  ~ log-linear with age (days)
#   clay_activity ~ function of clayHOH (pozzolanic reactivity proxy)
#   dilution  ~ slight MPa loss per % replacement, offset by pozzolanic gain

# Age multiplier (relative to 28d reference)
age_mult <- function(days) {
  0.30 + 0.70 * (log(days) / log(28))^0.55
}

# Pozzolanic gain per % replacement (reactive = positive; inert = negative)
# Higher HOH = more reactive clay = higher pozzolan contribution
pozzolan_gain <- function(hoh, repl) {
  # HOH range ~330–670; normalise so mean ~0.5
  activity  <- (hoh - 300) / 400   # 0.08 (CC2) to 0.92 (CC0)
  gain_per_pct <- 0.30 * activity - 0.05   # CC0: +0.18, CC2: -0.01 per %
  gain_per_pct * repl
}

base_28d   <- 47.0
noise_sd   <- 1.8

design$strength_MPa <- with(design, {
  am   <- age_mult(age_days)
  pg   <- pozzolan_gain(clayHOH, replacement)
  base <- (base_28d + pg) * am
  pmax(base + rnorm(nrow(design), 0, noise_sd), 5)  # floor at 5 MPa
})

# ---- Add small realistic noise to mineralogical properties ------------------
# (instrument precision uncertainty — not the declared measurement uncertainty
#  that goes in uncertainty_concrete)

design$clayHOH  <- design$clayHOH  + rnorm(nrow(design), 0, 0.8)
design$alumina  <- design$alumina  + rnorm(nrow(design), 0, 0.03)
design$SSA      <- design$SSA      + rnorm(nrow(design), 0, 0.15)
design$D50      <- design$D50      + rnorm(nrow(design), 0, 0.04)
design$strength_MPa <- round(design$strength_MPa, 1)

# ---- Assemble final tibble ---------------------------------------------------

concrete <- tibble::tibble(
  mixture     = as.integer(design$mixture),
  clay        = factor(design$clay, levels = clay_props$clay),
  replacement = as.numeric(design$replacement),
  clayHOH     = round(design$clayHOH,  1),
  alumina     = round(design$alumina,  2),
  SSA         = round(design$SSA,      2),
  D50         = round(design$D50,      2),
  strength_MPa = design$strength_MPa,
  age         = factor(paste0(design$age_days, "d"),
                        levels = c("7d", "28d", "56d")),
  wcm         = wcm_fixed
)

# Sort by mixture then age
concrete <- concrete[order(concrete$mixture, concrete$age), ]
row.names(concrete) <- NULL

cat("concrete: ", nrow(concrete), "rows,", ncol(concrete), "columns\n")
print(summary(concrete[, c("replacement", "clayHOH", "alumina", "SSA",
                             "D50", "strength_MPa")]))

# ---- uncertainty_concrete ---------------------------------------------------

uncertainty_concrete <- tibble::tribble(
  ~term,         ~type,   ~value, ~source,
  "clayHOH",     "std",   3.2,   "ASTM C1897 §X3, single-operator reproducibility",
  "alumina",     "std",   0.07,  "ASTM C114 §7.3, method precision",
  "SSA",         "cov",   5.5,   "Manufacturer certificate of analysis",
  "D50",         "cov",   4.0,   "Laser diffraction, repeat measurement CV",
  "strength_MPa","cov",   3.0,   "ASTM C109 §10.3, single-operator precision"
)

cat("\nuncertainty_concrete:\n")
print(uncertainty_concrete)

# ---- Save -------------------------------------------------------------------

usethis::use_data(concrete, uncertainty_concrete, overwrite = TRUE)
cat("\nSaved data/concrete.rda and data/uncertainty_concrete.rda\n")
