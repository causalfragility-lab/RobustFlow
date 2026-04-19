#' Validate and prepare longitudinal panel data
#'
#' Checks that required variables exist in `data`, sorts the data by
#' individual and time, and returns a structured list with diagnostic
#' information about the panel.
#'
#' @param data A data frame in long format (one row per individual per time
#'   point).
#' @param id Character scalar. Name of the individual identifier variable.
#' @param time Character scalar. Name of the time variable.
#' @param decision Character scalar. Name of the decision or outcome variable.
#' @param group Character scalar or `NULL`. Optional name of the subgroup
#'   variable (e.g., SES group, race/ethnicity). Default `NULL`.
#' @param cluster Character scalar or `NULL`. Optional name of a cluster
#'   variable (e.g., school, site). Default `NULL`.
#'
#' @return A named list with the following elements:
#' \describe{
#'   \item{`data`}{Sorted data frame (by `id`, then `time`).}
#'   \item{`n_ids`}{Integer. Number of unique individuals.}
#'   \item{`n_times`}{Integer. Number of unique time points.}
#'   \item{`balanced`}{Logical. `TRUE` if every individual appears at every
#'     time point (balanced panel).}
#'   \item{`missingness`}{Named integer vector. Count of `NA` values for each
#'     required variable.}
#' }
#'
#' @export
#'
#' @examples
#' df <- data.frame(
#'   child_id = rep(1:5, each = 3),
#'   wave     = rep(1:3, times = 5),
#'   outcome  = sample(0:1, 15, replace = TRUE)
#' )
#' result <- validate_panel_data(
#'   data     = df,
#'   id       = "child_id",
#'   time     = "wave",
#'   decision = "outcome"
#' )
#' result$n_ids
#' result$balanced
validate_panel_data <- function(data, id, time, decision,
                                group   = NULL,
                                cluster = NULL) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  needed      <- c(id, time, decision, group, cluster)
  needed      <- needed[lengths(list(id, time, decision, group, cluster)) > 0]
  needed      <- unique(needed)
  missing_col <- setdiff(needed, names(data))

  if (length(missing_col) > 0L) {
    stop(
      "The following variables were not found in `data`: ",
      paste(missing_col, collapse = ", "),
      call. = FALSE
    )
  }

  data <- data[order(data[[id]], data[[time]]), ]
  rownames(data) <- NULL

  counts_per_id <- table(data[[id]])
  n_times       <- length(unique(data[[time]]))
  balanced      <- all(counts_per_id == n_times)
  missingness   <- vapply(data[, needed, drop = FALSE],
                          function(x) sum(is.na(x)),
                          integer(1L))

  list(
    data        = data,
    n_ids       = length(unique(data[[id]])),
    n_times     = n_times,
    balanced    = balanced,
    missingness = missingness
  )
}
