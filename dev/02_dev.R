# RobustFlow development script — Phase 2: Ongoing development
# Source individual sections as needed during active development.

library(golem)
library(devtools)

# -----------------------------------------------------------------------
# Load the package in dev mode (faster than install)
# -----------------------------------------------------------------------
devtools::load_all()

# -----------------------------------------------------------------------
# Test individual functions interactively
# -----------------------------------------------------------------------

# Simulate a small ECLS-K-style panel
set.seed(42)
demo <- data.frame(
  child_id  = rep(seq_len(50), each = 5),
  wave      = rep(seq_len(5), times = 50),
  risk_math = sample(0:1, 250, replace = TRUE, prob = c(0.6, 0.4)),
  ses_group = rep(sample(c("Low SES", "Mid SES", "High SES"), 50,
                         replace = TRUE, prob = c(0.35, 0.40, 0.25)),
                  each = 5),
  school_id = rep(sample(seq_len(10), 50, replace = TRUE), each = 5)
)

# Validate
v <- validate_panel_data(demo, "child_id", "wave", "risk_math",
                         group = "ses_group", cluster = "school_id")
str(v)

# Paths
p <- build_paths(v$data, "child_id", "wave", "risk_math")
head(p$path_counts)
p$transition_matrix
p$path_entropy

# DII
d <- compute_drift(v$data, "child_id", "wave", "risk_math")
d$summary
d$mean_dii

# Group gaps + BAI
g   <- compute_group_gaps(v$data, "wave", "risk_math", "ses_group")
bai <- compute_bai(g$gap)
bai

# TFI
tfi <- compute_tfi_simple(d$summary$DII[!is.na(d$summary$DII)])
tfi$tfi
tfi$summary_table

# Export script
tmp <- tempfile(fileext = ".R")
generate_r_script("child_id", "wave", "risk_math", "ses_group",
                  output_file = tmp)
file.show(tmp)

# -----------------------------------------------------------------------
# Run tests with live output
# -----------------------------------------------------------------------
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-metrics.R")

# -----------------------------------------------------------------------
# Check coverage
# -----------------------------------------------------------------------
covr::package_coverage()
covr::report()

# -----------------------------------------------------------------------
# Launch app in dev mode
# -----------------------------------------------------------------------
run_app()
