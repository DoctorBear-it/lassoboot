#' Limestone calcined clay cement strength dataset
#'
#' A synthetic dataset modelling the compressive strength of mortar cubes
#' produced with limestone calcined clay cement (LC3) blends. Four calcined
#' clay sources (CC0–CC3) are evaluated at five replacement levels and three
#' curing ages. Structure mirrors the `df_final` object from the package's
#' companion prototype analysis; sample identifiers are anonymised to integers
#' and supplier names removed.
#'
#' This dataset is designed to demonstrate `lassoboot`'s uncertainty-aware
#' lasso workflow for materials-science data. Typical use:
#'
#' ```r
#' spec <- lb_spec(
#'   strength_MPa ~ (clayHOH + log(clayHOH)) * replacement * alumina * SSA * D50,
#'   data        = concrete,
#'   uncertainty = uncertainty_concrete,
#'   folds       = lb_folds_grouped("mixture")
#' )
#' boot <- lb_bootstrap(spec, B = 500)
#' tidy(boot)
#' ```
#'
#' @format A tibble with 75 rows and 10 variables:
#' \describe{
#'   \item{mixture}{Integer. Unique identifier for each cement replacement
#'     mixture (25 unique values, one per clay × replacement combination).}
#'   \item{clay}{Factor. Clay source identifier.
#'     Levels: `"CC0"`, `"CC1A"`, `"CC1B"`, `"CC2"`, `"CC3"`.}
#'   \item{replacement}{Numeric. Cement replacement level
#'     (weight %, 10--30).}
#'   \item{clayHOH}{Numeric. Clay heat of hydration measured by isothermal
#'     calorimetry (J/g), per ASTM C1897. A proxy for pozzolanic reactivity:
#'     higher values indicate greater reactivity.}
#'   \item{alumina}{Numeric. Al\eqn{_2}O\eqn{_3} content of the calcined
#'     clay (weight %), determined by X-ray fluorescence per ASTM C114.}
#'   \item{SSA}{Numeric. Specific surface area of the calcined clay
#'     (m\eqn{^2}/g), measured by BET nitrogen adsorption.}
#'   \item{D50}{Numeric. Median particle diameter (\eqn{\mu}m) from laser
#'     diffraction particle size analysis.}
#'   \item{strength_MPa}{Numeric. Compressive strength of 50 mm mortar cubes
#'     (MPa), tested per ASTM C109.}
#'   \item{age}{Factor. Curing age at which strength was measured.
#'     Levels: `"7d"`, `"28d"`, `"56d"`.}
#'   \item{wcm}{Numeric. Water-to-cementitious-material ratio (fixed at 0.485
#'     for all mixtures in this dataset).}
#' }
#'
#' @seealso [uncertainty_concrete] for the companion uncertainty specification.
#'
#' @source
#' Synthetic dataset constructed to represent realistic LC3 mortar strength
#' data. Clay mineralogical properties (clayHOH, alumina, SSA, D50) are
#' modelled on typical values reported in the literature for calcined
#' montmorillonite and kaolinite clays. Strength values are generated from
#' a semi-empirical age/pozzolanic-activity model with additive noise at the
#' ASTM C109 single-operator reproducibility level.
"concrete"

#' Measurement uncertainty specification for the concrete dataset
#'
#' A tibble declaring the measurement uncertainties for the continuous
#' predictor and response columns in [concrete]. Pass directly to the
#' `uncertainty` argument of [lb_spec()].
#'
#' @format A tibble with 5 rows and 4 variables:
#' \describe{
#'   \item{term}{Character. Column name in [concrete] the uncertainty applies
#'     to.}
#'   \item{type}{Character. Uncertainty type: `"std"` (absolute standard
#'     deviation, in the units of `term`) or `"cov"` (coefficient of
#'     variation as a percentage).}
#'   \item{value}{Numeric. Uncertainty magnitude.}
#'   \item{source}{Character. Normative source documenting the uncertainty.}
#' }
#'
#' Declared uncertainties:
#' \tabular{llrl}{
#'   **Term**       \tab **Type** \tab **Value** \tab **Source** \cr
#'   clayHOH        \tab std      \tab 3.2 J/g   \tab ASTM C1897 \cr
#'   alumina        \tab std      \tab 0.07 wt%    \tab ASTM C114  \cr
#'   SSA            \tab cov      \tab 5.5 %       \tab Mfr. CoA   \cr
#'   D50            \tab cov      \tab 4.0 %       \tab Laser diff. \cr
#'   strength_MPa   \tab cov      \tab 3.0 %       \tab ASTM C109  \cr
#' }
#'
#' @seealso [concrete] for the dataset these uncertainties describe.
"uncertainty_concrete"
