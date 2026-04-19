test_that("build_paths: returns all required list elements", {
  df <- data.frame(
    id   = rep(seq_len(4), each = 3),
    time = rep(seq_len(3), times = 4),
    dec  = c(0L, 1L, 1L, 1L, 1L, 0L, 0L, 0L, 1L, 1L, 0L, 0L)
  )
  res <- build_paths(df, id = "id", time = "time", decision = "dec")

  expect_named(res,
    c("individual_paths", "path_counts", "transition_matrix", "path_entropy"),
    ignore.order = TRUE)
})

test_that("build_paths: individual_paths has one row per individual", {
  df <- data.frame(
    id   = rep(seq_len(10), each = 4),
    time = rep(seq_len(4), times = 10),
    dec  = sample(0:1, 40, replace = TRUE)
  )
  res <- build_paths(df, id = "id", time = "time", decision = "dec")
  expect_equal(nrow(res$individual_paths), 10L)
})

test_that("build_paths: path_counts frequencies sum to n individuals", {
  n <- 20L
  df <- data.frame(
    id   = rep(seq_len(n), each = 3),
    time = rep(seq_len(3), times = n),
    dec  = sample(0:1, n * 3, replace = TRUE)
  )
  res <- build_paths(df, id = "id", time = "time", decision = "dec")
  expect_equal(sum(res$path_counts$n), n)
})

test_that("build_paths: path_counts pct sums to 100", {
  df <- data.frame(
    id   = rep(seq_len(6), each = 2),
    time = rep(seq_len(2), times = 6),
    dec  = c(0L, 1L, 1L, 0L, 0L, 0L, 1L, 1L, 0L, 1L, 1L, 0L)
  )
  res <- build_paths(df, id = "id", time = "time", decision = "dec")
  expect_equal(sum(res$path_counts$pct), 100)
})

test_that("build_paths: path_entropy is non-negative", {
  df <- data.frame(
    id   = rep(seq_len(8), each = 3),
    time = rep(seq_len(3), times = 8),
    dec  = sample(0:1, 24, replace = TRUE)
  )
  res <- build_paths(df, id = "id", time = "time", decision = "dec")
  expect_gte(res$path_entropy, 0)
})

test_that("build_paths: entropy is 0 for identical paths", {
  df <- data.frame(
    id   = rep(seq_len(5), each = 2),
    time = rep(seq_len(2), times = 5),
    dec  = rep(0L, 10)
  )
  res <- build_paths(df, id = "id", time = "time", decision = "dec")
  expect_equal(res$path_entropy, 0)
})

test_that("build_paths: separator is respected", {
  df <- data.frame(
    id   = rep(1L, 3),
    time = seq_len(3),
    dec  = c(0L, 1L, 0L)
  )
  res_arrow <- build_paths(df, "id", "time", "dec", sep = "->")
  res_comma <- build_paths(df, "id", "time", "dec", sep = ",")
  expect_equal(res_arrow$individual_paths$path, "0->1->0")
  expect_equal(res_comma$individual_paths$path, "0,1,0")
})

test_that("compute_transition_matrix_all: returns correct matrix", {
  df <- data.frame(
    id   = rep(seq_len(3), each = 3),
    time = rep(seq_len(3), times = 3),
    dec  = c(0L, 0L, 1L,  # id 1: 0->0->1  => pairs (0,0), (0,1)
             1L, 1L, 0L,  # id 2: 1->1->0  => pairs (1,1), (1,0)
             0L, 1L, 1L)  # id 3: 0->1->1  => pairs (0,1), (1,1)
  )
  mat <- compute_transition_matrix_all(df, "id", "time", "dec")
  expect_true(is.matrix(mat))
  # from=0,to=0 count = 1; from=0,to=1 count = 2; from=1,to=0 count=1; from=1,to=1 count=2
  expect_equal(mat["0", "0"], 1L)
  expect_equal(mat["0", "1"], 2L)
  expect_equal(mat["1", "0"], 1L)
  expect_equal(mat["1", "1"], 2L)
})

test_that("compute_transition_matrix_all: handles single-observation individual", {
  df <- data.frame(
    id   = c(1L, 1L, 2L),
    time = c(1L, 2L, 1L),
    dec  = c(0L, 1L, 0L)
  )
  # id=2 has only one obs, should be skipped
  mat <- compute_transition_matrix_all(df, "id", "time", "dec")
  expect_equal(sum(mat), 1L)
})
