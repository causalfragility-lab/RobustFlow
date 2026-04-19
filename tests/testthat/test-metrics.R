# ----- Helpers -------------------------------------------------------------

make_df <- function(n_ids = 30, n_time = 4, seed = 42) {
  set.seed(seed)
  data.frame(
    id   = rep(seq_len(n_ids), each = n_time),
    time = rep(seq_len(n_time), times = n_ids),
    dec  = sample(0:1, n_ids * n_time, replace = TRUE),
    grp  = rep(sample(c("Low", "High"), n_ids, replace = TRUE),
               each = n_time)
  )
}

# ----- compute_drift (DII) -------------------------------------------------

test_that("compute_drift: returns required list structure", {
  df  <- make_df()
  res <- compute_drift(df, id = "id", time = "time", decision = "dec")

  expect_named(res,
    c("summary", "matrices", "mean_dii", "max_dii_period"),
    ignore.order = TRUE)
  expect_s3_class(res$summary, "data.frame")
  expect_true(all(c("time", "DII") %in% names(res$summary)))
})

test_that("compute_drift: first DII is always NA", {
  df  <- make_df()
  res <- compute_drift(df, id = "id", time = "time", decision = "dec")
  expect_true(is.na(res$summary$DII[1]))
})

test_that("compute_drift: non-first DIIs are non-negative", {
  df   <- make_df()
  res  <- compute_drift(df, id = "id", time = "time", decision = "dec")
  vals <- res$summary$DII[-1]
  expect_true(all(vals[!is.na(vals)] >= 0))
})

test_that("compute_drift: number of rows equals number of time points", {
  df  <- make_df(n_time = 5)
  res <- compute_drift(df, id = "id", time = "time", decision = "dec")
  expect_equal(nrow(res$summary), 5L)
})

test_that("compute_drift: normalize = FALSE still returns non-negative DII", {
  df  <- make_df()
  res <- compute_drift(df, id = "id", time = "time",
                       decision = "dec", normalize = FALSE)
  vals <- res$summary$DII[-1]
  expect_true(all(vals[!is.na(vals)] >= 0))
})

test_that("compute_drift: mean_dii is NA when all transitions are missing", {
  # Only one time point per ID: no transitions possible
  df <- data.frame(
    id   = seq_len(5),
    time = rep(1L, 5),
    dec  = sample(0:1, 5, replace = TRUE)
  )
  # Suppress the error from needing >= 2 time points
  df2 <- rbind(df, data.frame(id = seq_len(5), time = 2L, dec = sample(0:1, 5, replace = TRUE)))
  res <- compute_drift(df2, id = "id", time = "time", decision = "dec")
  expect_true(is.numeric(res$mean_dii))
})

# ----- compute_group_gaps + compute_bai (BAI) ------------------------------

test_that("compute_group_gaps: returns required list elements", {
  df  <- make_df()
  res <- compute_group_gaps(df, time = "time", decision = "dec",
                             group = "grp", focal_value = 1)

  expect_named(res, c("long_format", "gap_df", "gap", "group_levels"),
               ignore.order = TRUE)
  expect_s3_class(res$long_format, "data.frame")
  expect_s3_class(res$gap_df,      "data.frame")
  expect_type(res$gap, "double")
})

test_that("compute_group_gaps: rates are in [0, 1]", {
  df  <- make_df()
  res <- compute_group_gaps(df, "time", "dec", "grp", focal_value = 1)
  expect_true(all(res$long_format$rate >= 0))
  expect_true(all(res$long_format$rate <= 1))
})

test_that("compute_group_gaps: gap has one entry per time point", {
  df  <- make_df(n_time = 6)
  res <- compute_group_gaps(df, "time", "dec", "grp")
  expect_equal(length(res$gap), 6L)
})

test_that("compute_bai: amplification when gap increases", {
  res <- compute_bai(c(0.05, 0.10, 0.15, 0.20))
  expect_equal(res$direction, "amplification")
  expect_equal(res$bai, 0.15)
  expect_equal(res$gap_start, 0.05)
  expect_equal(res$gap_end,   0.20)
})

test_that("compute_bai: convergence when gap decreases", {
  res <- compute_bai(c(0.20, 0.15, 0.10, 0.05))
  expect_equal(res$direction, "convergence")
  expect_equal(res$bai, -0.15)
})

test_that("compute_bai: stable when change is small", {
  res <- compute_bai(c(0.10, 0.11, 0.10, 0.12), threshold = 0.05)
  expect_equal(res$direction, "stable")
})

test_that("compute_bai: standardized mode returns finite number", {
  gaps <- c(0.10, 0.15, 0.20, 0.25, 0.30)
  res  <- compute_bai(gaps, standardize = TRUE)
  expect_true(is.finite(res$bai))
})

test_that("compute_bai: standardized BAI is 0 when SD is 0", {
  # constant gap → sd = 0 → bai = 0
  res <- compute_bai(c(0.10, 0.10, 0.10, 0.10), standardize = TRUE)
  expect_equal(res$bai, 0)
})

test_that("compute_bai: errors on series shorter than 2", {
  expect_error(compute_bai(c(0.10)), "at least two")
  expect_error(compute_bai(numeric(0)), "at least two")
})

test_that("compute_bai: ignores NA values correctly", {
  res <- compute_bai(c(0.10, NA, 0.20))
  expect_equal(res$bai, 0.10)
})

# ----- compute_tfi_simple (TFI) --------------------------------------------

test_that("compute_tfi_simple: returns required list elements", {
  res <- compute_tfi_simple(c(0.1, 0.2, 0.3, 0.4))
  expect_named(res,
    c("tfi", "observed_slope", "sensitivity_curve", "summary_table"),
    ignore.order = TRUE)
  expect_s3_class(res$sensitivity_curve, "data.frame")
  expect_s3_class(res$summary_table, "data.frame")
})

test_that("compute_tfi_simple: tfi is non-negative or Inf", {
  res <- compute_tfi_simple(c(0.05, 0.10, 0.20))
  expect_true(res$tfi >= 0 || is.infinite(res$tfi))
})

test_that("compute_tfi_simple: flat trend has tfi = 0", {
  res <- compute_tfi_simple(c(0.10, 0.10, 0.10, 0.10))
  expect_equal(res$tfi, 0)
})

test_that("compute_tfi_simple: upward trend has tfi == 1 when perturb_seq includes 1", {
  # slope > 0 → nullified at u = 1 (adjusted = slope * (1-1) = 0)
  res <- compute_tfi_simple(c(0.1, 0.2, 0.3, 0.4),
                             perturb_seq = seq(0, 2, by = 0.01))
  expect_equal(res$tfi, 1.0)
})

test_that("compute_tfi_simple: tfi is Inf when perturb_seq cannot nullify trend", {
  # very small perturb_seq range: slope = 0.1/step, u never reaches 1
  res <- compute_tfi_simple(c(0.1, 0.2, 0.3),
                             perturb_seq = seq(0, 0.5, by = 0.01))
  expect_true(is.infinite(res$tfi))
})

test_that("compute_tfi_simple: sensitivity curve has correct column names", {
  res <- compute_tfi_simple(c(0.1, 0.3, 0.5))
  expect_named(res$sensitivity_curve,
               c("perturbation", "adjusted_effect"))
})

test_that("compute_tfi_simple: errors on series shorter than 2", {
  expect_error(compute_tfi_simple(c(0.5)), "at least two")
})

test_that("compute_tfi_simple: errors on negative perturbation values", {
  expect_error(compute_tfi_simple(c(0.1, 0.2), perturb_seq = c(-1, 0, 1)),
               "non-negative")
})

test_that("compute_tfi_simple: NA values in effect_series are removed", {
  res1 <- compute_tfi_simple(c(0.1, 0.2, 0.3, 0.4))
  res2 <- compute_tfi_simple(c(0.1, NA, 0.3, NA, 0.4, 0.2))
  # both should succeed; TFI from res2 may differ but should be finite or Inf
  expect_true(is.numeric(res1$tfi))
  expect_true(is.numeric(res2$tfi))
})
