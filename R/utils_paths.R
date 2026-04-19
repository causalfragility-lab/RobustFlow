#' Construct individual decision paths and the aggregate transition matrix
#'
#' For each individual, concatenates their sequence of decisions (or outcomes)
#' over time into a single path string. Returns individual-level paths,
#' aggregate frequency counts, the pooled transition matrix, and path entropy.
#'
#' @param data A data frame in long format, pre-sorted by `id` and `time`
#'   (e.g., the `data` element returned by [validate_panel_data()]).
#' @param id Character scalar. Name of the individual identifier variable.
#' @param time Character scalar. Name of the time variable.
#' @param decision Character scalar. Name of the decision or outcome variable.
#' @param sep Character scalar. Separator inserted between consecutive decision
#'   states in the path string. Default `"->"`.
#'
#' @return A named list with the following elements:
#' \describe{
#'   \item{`individual_paths`}{Data frame with one row per individual and
#'     columns `id` and `path`.}
#'   \item{`path_counts`}{Data frame of unique paths with columns `path`,
#'     `n` (frequency), and `pct` (percentage), sorted in descending order
#'     of frequency.}
#'   \item{`transition_matrix`}{Integer matrix of pooled transition counts
#'     (rows = from-state, columns = to-state).}
#'   \item{`path_entropy`}{Numeric scalar. Shannon entropy (bits) of the path
#'     frequency distribution. Higher values indicate greater diversity of
#'     individual trajectories.}
#' }
#'
#' @export
#'
#' @examples
#' df <- data.frame(
#'   id   = rep(1:4, each = 3),
#'   time = rep(1:3, times = 4),
#'   dec  = c(0L, 1L, 1L, 1L, 1L, 0L, 0L, 0L, 1L, 1L, 0L, 0L)
#' )
#' result <- build_paths(df, id = "id", time = "time", decision = "dec")
#' head(result$path_counts)
#' result$transition_matrix
#' result$path_entropy
build_paths <- function(data, id, time, decision, sep = "->") {
  ids <- unique(data[[id]])

  path_strings <- vapply(ids, function(i) {
    d  <- data[data[[id]] == i, ]
    d  <- d[order(d[[time]]), ]
    paste(as.character(d[[decision]]), collapse = sep)
  }, character(1L))

  path_df <- data.frame(
    id   = ids,
    path = path_strings,
    stringsAsFactors = FALSE
  )

  freq_tab          <- as.data.frame(table(path_df$path), stringsAsFactors = FALSE)
  names(freq_tab)   <- c("path", "n")
  freq_tab$pct      <- round(freq_tab$n / sum(freq_tab$n) * 100, 2)
  freq_tab          <- freq_tab[order(-freq_tab$n), ]
  rownames(freq_tab) <- NULL

  p       <- freq_tab$n / sum(freq_tab$n)
  entropy <- -sum(p * log2(p + .Machine$double.eps))

  trans_mat <- compute_transition_matrix_all(data, id, time, decision)

  list(
    individual_paths  = path_df,
    path_counts       = freq_tab,
    transition_matrix = trans_mat,
    path_entropy      = entropy
  )
}


#' Compute the pooled transition matrix across all individuals
#'
#' Pools all consecutive decision pairs (from time \eqn{t} to \eqn{t+1})
#' across all individuals and returns a matrix of transition counts.
#'
#' @param data A data frame in long format.
#' @param id Character scalar. Individual identifier variable name.
#' @param time Character scalar. Time variable name.
#' @param decision Character scalar. Decision variable name.
#'
#' @return An integer matrix of transition counts with named rows (from-state)
#'   and columns (to-state). Returns a \eqn{0 \times 0} matrix if no
#'   transitions can be extracted.
#'
#' @export
#'
#' @examples
#' df <- data.frame(
#'   id   = rep(1:3, each = 3),
#'   time = rep(1:3, times = 3),
#'   dec  = c(0L, 1L, 1L, 1L, 0L, 1L, 0L, 0L, 1L)
#' )
#' compute_transition_matrix_all(df, "id", "time", "dec")
compute_transition_matrix_all <- function(data, id, time, decision) {
  ids <- unique(data[[id]])

  pairs_list <- lapply(ids, function(i) {
    d  <- data[data[[id]] == i, ]
    d  <- d[order(d[[time]]), ]
    dv <- as.character(d[[decision]])
    if (length(dv) < 2L) return(NULL)
    data.frame(
      from = utils::head(dv, -1L),
      to   = utils::tail(dv, -1L),
      stringsAsFactors = FALSE
    )
  })

  pairs <- do.call(rbind, pairs_list)

  if (is.null(pairs) || nrow(pairs) == 0L) {
    return(matrix(integer(0L), nrow = 0L, ncol = 0L))
  }

  as.matrix(table(pairs$from, pairs$to))
}
