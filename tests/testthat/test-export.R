test_that("generate_r_script: creates a file at output_file path", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  generate_r_script(
    id_var       = "child_id",
    time_var     = "wave",
    decision_var = "risk_math",
    output_file  = tmp
  )
  expect_true(file.exists(tmp))
})

test_that("generate_r_script: returns output_file invisibly", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  result <- generate_r_script(
    id_var       = "id",
    time_var     = "time",
    decision_var = "dec",
    output_file  = tmp
  )
  expect_equal(result, tmp)
})

test_that("generate_r_script: output is valid R syntax", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  generate_r_script(
    id_var       = "child_id",
    time_var     = "wave",
    decision_var = "risk_math",
    group_var    = "ses_group",
    cluster_var  = "school_id",
    focal_value  = 1,
    output_file  = tmp
  )
  lines <- readLines(tmp)
  parsed <- tryCatch(parse(text = lines), error = function(e) e)
  expect_false(inherits(parsed, "error"))
})

test_that("generate_r_script: contains correct variable names", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  generate_r_script(
    id_var       = "my_id",
    time_var     = "my_time",
    decision_var = "my_dec",
    group_var    = "my_group",
    output_file  = tmp
  )
  content <- paste(readLines(tmp), collapse = "\n")
  expect_match(content, "my_id",    fixed = TRUE)
  expect_match(content, "my_time",  fixed = TRUE)
  expect_match(content, "my_dec",   fixed = TRUE)
  expect_match(content, "my_group", fixed = TRUE)
})

test_that("generate_r_script: group_var = NULL writes NULL in script", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  generate_r_script(
    id_var       = "id",
    time_var     = "time",
    decision_var = "dec",
    group_var    = NULL,
    output_file  = tmp
  )
  content <- paste(readLines(tmp), collapse = "\n")
  expect_match(content, "group_var    <- NULL", fixed = TRUE)
})

test_that("generate_r_script: includes all major section headers", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))
  generate_r_script("id", "time", "dec", output_file = tmp)
  content <- paste(readLines(tmp), collapse = "\n")
  expect_match(content, "validate_panel_data", fixed = TRUE)
  expect_match(content, "build_paths",         fixed = TRUE)
  expect_match(content, "compute_drift",        fixed = TRUE)
  expect_match(content, "compute_tfi_simple",   fixed = TRUE)
})
