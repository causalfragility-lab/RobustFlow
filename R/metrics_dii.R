#' Compute the Drift Intensity Index (DII) over time
#'
#' The DII quantifies structural instability in the decision transition system
#' between consecutive time periods. For each pair of adjacent time points
#' \eqn{(t-1, t)}, a period-specific transition matrix \eqn{P_t} is estimated
#' from observed consecutive-state pairs, and the DII is defined as the
#' Frobenius norm of their difference:
#'
#' \deqn{DII_t = \| P_t - P_{t-1} \|_F = \sqrt{\sum_{i,j}(P_t^{ij} - P_{t-1}^{ij})^2}}
#'
#' When `normalize = TRUE` (default), each matrix is row-normalized before
#' computing the norm, so DII is scale-free and comparable across datasets.
#'
#' @details
#' The period-specific transition matrix \eqn{P_t} is constructed from
#' transitions observed *between* time \eqn{t-1} and time \eqn{t} only
#' (not cumulatively). Individuals present at both \eqn{t-1} and \eqn{t}
#' contribute one transition pair. Individuals missing at either wave are
#' excluded from that period's matrix.
#'
#' @param data A data frame in long format.
#' @param id Character scalar. Name of the individual identifier variable.
#' @param time Character scalar. Name of the time variable.
#' @param decision Character scalar. Name of the decision or outcome variable.
#' @param normalize Logical. If `TRUE` (default), each transition matrix is
#'   row-normalized to proportions before computing the Frobenius norm. If
#'   `FALSE`, raw counts are used.
#'
#' @return A named list with the following elements:
#' \describe{
#'   \item{`summary`}{Data frame with columns `time` and `DII`. The first
#'     time point always has `DII = NA` (no preceding period).}
#'   \item{`matrices`}{Named list of period-specific transition matrices
#'     (one per time interval).}
#'   \item{`mean_dii`}{Numeric scalar. Mean DII across all non-missing
#'     periods.}
#'   \item{`max_dii_period`}{The time value at which DII is largest.}
#' }
#'
#' @export
#'
#' @references
#' Hait, S. (2025). *RobustFlow: Robustness and drift auditing for
#' longitudinal decision systems*. R package version 0.1.0.
#'
#' @examples
#' set.seed(42)
#' df <- data.frame(
#'   id   = rep(seq_len(50), each = 4),
#'   time = rep(seq_len(4), times = 50),
#'   dec  = sample(0:1, 200, replace = TRUE)
#' )
#' result <- compute_drift(df, id = "id", time = "time", decision = "dec")
#' result$summary
#' result$mean_dii
compute_drift <- function(data, id, time, decision, normalize = TRUE) {
  times  <- sort(unique(data[[time]]))
  states <- sort(unique(as.character(data[[decision]])))

  n_t  <- length(times)
  mats <- vector("list", n_t)
  names(mats) <- as.character(times)

  for (i in seq_len(n_t)) {
    if (i == 1L) {
      mats[[i]] <- NULL
      next
    }

    d_from <- data[data[[time]] == times[i - 1L], c(id, decision), drop = FALSE]
    d_to   <- data[data[[time]] == times[i],      c(id, decision), drop = FALSE]
    merged <- merge(d_from, d_to, by = id, suffixes = c("_from", "_to"))

    if (nrow(merged) == 0L) {
      mats[[i]] <- NULL
      next
    }

    col_from <- paste0(decision, "_from")
    col_to   <- paste0(decision, "_to")

    tab <- table(
      from = factor(as.character(merged[[col_from]]), levels = states),
      to   = factor(as.character(merged[[col_to]]),   levels = states)
    )
    mat <- as.matrix(tab)

    if (normalize) {
      rs <- rowSums(mat)
      rs[rs == 0] <- 1
      mat <- mat / rs
    }
    mats[[i]] <- mat
  }

  dii <- rep(NA_real_, n_t)
  for (i in seq_len(n_t)) {
    if (i < 2L || is.null(mats[[i]]) || is.null(mats[[i - 1L]])) next
    d    <- mats[[i]] - mats[[i - 1L]]
    dii[i] <- sqrt(sum(d^2))
  }

  summary_df <- data.frame(
    time = times,
    DII  = round(dii, 6L),
    stringsAsFactors = FALSE
  )

  valid <- dii[!is.na(dii)]

  list(
    summary        = summary_df,
    matrices       = mats,
    mean_dii       = if (length(valid) > 0L) mean(valid) else NA_real_,
    max_dii_period = if (length(valid) > 0L) times[which.max(dii)] else NA
  )
}
