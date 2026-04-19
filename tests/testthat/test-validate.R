test_that("validate_panel_data: returns correct structure for balanced panel", {
  df <- data.frame(
    id   = rep(seq_len(5), each = 3),
    time = rep(seq_len(3), times = 5),
    dec  = sample(0:1, 15, replace = TRUE)
  )
  res <- validate_panel_data(df, id = "id", time = "time", decision = "dec")

  expect_type(res, "list")
  expect_named(res, c("data", "n_ids", "n_times", "balanced", "missingness"),
               ignore.order = TRUE)
  expect_equal(res$n_ids,   5L)
  expect_equal(res$n_times, 3L)
  expect_true(res$balanced)
  expect_s3_class(res$data, "data.frame")
})

test_that("validate_panel_data: detects unbalanced panel", {
  df <- data.frame(
    id   = c(1L, 1L, 2L),
    time = c(1L, 2L, 1L),
    dec  = c(0L, 1L, 1L)
  )
  res <- validate_panel_data(df, id = "id", time = "time", decision = "dec")
  expect_false(res$balanced)
})

test_that("validate_panel_data: errors on missing column", {
  df <- data.frame(id = seq_len(3), time = seq_len(3))
  expect_error(
    validate_panel_data(df, id = "id", time = "time", decision = "no_col"),
    "not found"
  )
})

test_that("validate_panel_data: errors on non-data-frame input", {
  expect_error(
    validate_panel_data(list(a = 1), id = "a", time = "b", decision = "c"),
    "data frame"
  )
})

test_that("validate_panel_data: sorts output correctly", {
  df <- data.frame(
    id   = c(2L, 1L, 2L, 1L),
    time = c(2L, 2L, 1L, 1L),
    dec  = c(0L, 1L, 1L, 0L)
  )
  res <- validate_panel_data(df, id = "id", time = "time", decision = "dec")
  expect_equal(res$data$id,   c(1L, 1L, 2L, 2L))
  expect_equal(res$data$time, c(1L, 2L, 1L, 2L))
})

test_that("validate_panel_data: missingness counts are correct", {
  df <- data.frame(
    id   = seq_len(6),
    time = rep(seq_len(2), 3),
    dec  = c(0L, NA, 1L, 0L, NA, 1L)
  )
  res <- validate_panel_data(df, id = "id", time = "time", decision = "dec")
  expect_equal(unname(res$missingness["dec"]), 2L)
})

test_that("validate_panel_data: accepts optional group and cluster args", {
  df <- data.frame(
    id      = rep(seq_len(4), each = 2),
    time    = rep(seq_len(2), 4),
    dec     = sample(0:1, 8, replace = TRUE),
    grp     = rep(c("A", "B"), 4),
    cluster = rep(1:2, each = 4)
  )
  expect_no_error(
    validate_panel_data(df, "id", "time", "dec",
                        group = "grp", cluster = "cluster")
  )
})
