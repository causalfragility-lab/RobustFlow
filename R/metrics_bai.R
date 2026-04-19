#' Compute group-specific trajectories and disparity gaps over time
#'
#' Aggregates the focal-event rate for each group at each time point and
#' computes the pairwise gap between the first two levels of the group
#' variable (sorted alphabetically).
#'
#' @param data A data frame in long format.
#' @param time Character scalar. Name of the time variable.
#' @param decision Character scalar. Name of the decision or outcome variable.
#' @param group Character scalar. Name of the grouping variable.
#' @param focal_value Numeric or character scalar. The decision value treated
#'   as the "event" when computing group rates (e.g., `1` for a binary
#'   at-risk indicator). Default `1`.
#'
#' @return A named list with the following elements:
#' \describe{
#'   \item{`long_format`}{Data frame with columns `time`, `group`, and `rate`
#'     (proportion of the focal event within each group-time cell).}
#'   \item{`gap_df`}{Data frame with columns `time` and `gap`
#'     (Group 1 rate minus Group 2 rate, where groups are the first two
#'     alphabetically sorted levels). `gap` is `NA` when fewer than two
#'     group levels are present.}
#'   \item{`gap`}{Numeric vector of gap values ordered by time (convenience
#'     accessor for [compute_bai()]).}
#'   \item{`group_levels`}{Character vector of all group levels found.}
#' }
#'
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   id    = rep(seq_len(60), each = 3),
#'   time  = rep(seq_len(3), times = 60),
#'   dec   = sample(0:1, 180, replace = TRUE),
#'   grp   = rep(c("Low", "High"), each = 90)
#' )
#' gaps <- compute_group_gaps(
#'   data        = df,
#'   time        = "time",
#'   decision    = "dec",
#'   group       = "grp",
#'   focal_value = 1
#' )
#' gaps$gap_df
#' gaps$group_levels
compute_group_gaps <- function(data, time, decision, group, focal_value = 1) {
  data[["._event_"]] <- as.numeric(data[[decision]] == focal_value)

  agg <- aggregate(
    data[["._event_"]],
    by  = list(time  = data[[time]],
               group = data[[group]]),
    FUN = function(x) mean(x, na.rm = TRUE)
  )
  names(agg)[3L] <- "rate"
  agg$rate       <- round(agg$rate, 6L)

  group_levels <- sort(unique(as.character(agg$group)))

  if (length(group_levels) >= 2L) {
    g1 <- agg[agg$group == group_levels[1L], c("time", "rate")]
    g2 <- agg[agg$group == group_levels[2L], c("time", "rate")]
    mg <- merge(g1, g2, by = "time", suffixes = c("_g1", "_g2"))
    mg$gap <- round(mg$rate_g1 - mg$rate_g2, 6L)
    gap_df <- mg[order(mg$time), c("time", "gap")]
  } else {
    gap_df <- data.frame(
      time = sort(unique(data[[time]])),
      gap  = NA_real_
    )
  }

  rownames(gap_df) <- NULL

  list(
    long_format  = agg,
    gap_df       = gap_df,
    gap          = gap_df$gap,
    group_levels = group_levels
  )
}


#' Compute the Bias Amplification Index (BAI)
#'
#' The BAI measures whether the disparity gap between two groups widens or
#' narrows from the first to the last observed time point. It is defined as:
#'
#' \deqn{BAI = Gap_T - Gap_1}
#'
#' A positive BAI indicates amplification (widening gap); a negative BAI
#' indicates convergence (narrowing gap); values near zero indicate stability.
#'
#' An optional standardized version divides by the standard deviation of the
#' gap series:
#'
#' \deqn{BAI^* = \frac{Gap_T - Gap_1}{SD(Gap_t)}}
#'
#' @param gap_series Numeric vector of gap values, one per time point, ordered
#'   chronologically. `NA` values are removed before computation.
#' @param standardize Logical. If `TRUE`, returns the standardized BAI
#'   (divided by the SD of `gap_series`). Default `FALSE`.
#' @param threshold Numeric scalar. Absolute BAI threshold used to classify
#'   the direction as amplification or convergence. Values with
#'   \eqn{|BAI| \le} `threshold` are classified as "stable".
#'   Default `0.05`.
#'
#' @return A named list with the following elements:
#' \describe{
#'   \item{`bai`}{Numeric scalar. The (optionally standardized) BAI.}
#'   \item{`gap_start`}{Gap at the first time point.}
#'   \item{`gap_end`}{Gap at the last time point.}
#'   \item{`direction`}{Character. `"amplification"`, `"convergence"`, or
#'     `"stable"`.}
#' }
#'
#' @export
#'
#' @examples
#' # Widening gap over 5 waves
#' gaps <- c(0.10, 0.12, 0.15, 0.18, 0.22)
#' compute_bai(gaps)
#'
#' # Narrowing gap
#' compute_bai(c(0.20, 0.15, 0.10, 0.05))
#'
#' # Standardized
#' compute_bai(gaps, standardize = TRUE)
compute_bai <- function(gap_series, standardize = FALSE, threshold = 0.05) {
  gap_series <- gap_series[!is.na(gap_series)]

  if (length(gap_series) < 2L) {
    stop("`gap_series` must contain at least two non-missing values.",
         call. = FALSE)
  }

  gap_start <- gap_series[1L]
  gap_end   <- gap_series[length(gap_series)]
  raw_bai   <- gap_end - gap_start

  bai <- if (standardize) {
    sd_gap <- stats::sd(gap_series)
    if (sd_gap == 0) 0 else raw_bai / sd_gap
  } else {
    raw_bai
  }

  direction <- if (bai > threshold) {
    "amplification"
  } else if (bai < -threshold) {
    "convergence"
  } else {
    "stable"
  }

  list(
    bai        = round(bai, 6L),
    gap_start  = gap_start,
    gap_end    = gap_end,
    direction  = direction
  )
}
