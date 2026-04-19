#' Compute the Temporal Fragility Index (TFI)
#'
#' The TFI estimates the minimum amount of hidden bias (modeled as a scalar
#' attenuation parameter \eqn{u}) required to nullify a longitudinal trend
#' conclusion. The observed trend is summarized as the OLS slope of
#' `effect_series` on time index. Under perturbation \eqn{u}, the adjusted
#' slope is:
#'
#' \deqn{\hat{\beta}(u) = \hat{\beta}_{obs} \times (1 - u)}
#'
#' The TFI is the smallest \eqn{u \ge 0} such that \eqn{\hat{\beta}(u) \le 0}
#' (for positive slopes) or \eqn{\hat{\beta}(u) \ge 0} (for negative slopes).
#' If no such \eqn{u} exists within `perturb_seq`, TFI is returned as `Inf`,
#' indicating a highly robust conclusion.
#'
#' @details
#' This is an intentionally accessible, first-generation operationalization
#' of temporal robustness. Future versions will support perturbation models
#' based on E-values, ITCV (impact threshold for a confounding variable), and
#' simulation-based tipping-point approaches.
#'
#' @param effect_series Numeric vector of observed effects over time
#'   (e.g., DII values, gap values). The trend is estimated as the slope of
#'   a simple OLS regression of `effect_series` on a unit time index
#'   (`1, 2, ..., T`). `NA` values are removed before estimation.
#' @param perturb_seq Numeric vector of perturbation values to evaluate.
#'   Must be non-negative. Defaults to `seq(0, 2, by = 0.01)`.
#'
#' @return A named list with the following elements:
#' \describe{
#'   \item{`tfi`}{Numeric scalar. The minimum perturbation that nullifies
#'     the trend, or `Inf` if none in `perturb_seq` does so.}
#'   \item{`observed_slope`}{Numeric scalar. OLS slope of `effect_series`
#'     on the time index.}
#'   \item{`sensitivity_curve`}{Data frame with columns `perturbation` and
#'     `adjusted_effect` (the slope under each perturbation value).}
#'   \item{`summary_table`}{One-row data frame with columns `Metric` and
#'     `Value`, summarizing the observed slope, TFI, and interpretation.}
#' }
#'
#' @export
#'
#' @references
#' Hait, S. (2025). *RobustFlow: Robustness and drift auditing for
#' longitudinal decision systems*. R package version 0.1.0.
#'
#' @examples
#' # Upward drift trend - moderately robust
#' dii_vals <- c(0.05, 0.10, 0.14, 0.19, 0.25)
#' result <- compute_tfi_simple(dii_vals)
#' result$tfi
#' result$summary_table
#'
#' # Flat trend - TFI is 0
#' compute_tfi_simple(c(0.1, 0.1, 0.1, 0.1))$tfi
compute_tfi_simple <- function(
    effect_series,
    perturb_seq = seq(0, 2, by = 0.01)
) {
  effect_series <- effect_series[!is.na(effect_series)]
  n <- length(effect_series)

  if (n < 2L) {
    stop("`effect_series` must contain at least two non-missing values.",
         call. = FALSE)
  }
  if (any(perturb_seq < 0)) {
    stop("`perturb_seq` must contain only non-negative values.",
         call. = FALSE)
  }

  time_index <- seq_len(n)
  fit        <- stats::lm(effect_series ~ time_index)
  obs_slope  <- unname(stats::coef(fit)[2L])

  adjusted <- obs_slope * (1 - perturb_seq)

  sensitivity_df <- data.frame(
    perturbation    = perturb_seq,
    adjusted_effect = round(adjusted, 8L)
  )

  tfi <- if (abs(obs_slope) < sqrt(.Machine$double.eps)) {
    0
  } else if (obs_slope > 0) {
    idx <- which(adjusted <= 0)[1L]
    if (is.na(idx)) Inf else perturb_seq[idx]
  } else {
    idx <- which(adjusted >= 0)[1L]
    if (is.na(idx)) Inf else perturb_seq[idx]
  }

  interp <- if (is.infinite(tfi)) {
    "Highly robust (TFI = Inf)"
  } else if (tfi > 0.5) {
    "Moderately robust"
  } else {
    "Fragile"
  }

  summary_table <- data.frame(
    Metric = c("Observed slope", "TFI", "Interpretation"),
    Value  = c(
      as.character(round(obs_slope, 6L)),
      if (is.infinite(tfi)) "Inf" else as.character(round(tfi, 4L)),
      interp
    ),
    stringsAsFactors = FALSE
  )

  list(
    tfi               = tfi,
    observed_slope    = obs_slope,
    sensitivity_curve = sensitivity_df,
    summary_table     = summary_table
  )
}
