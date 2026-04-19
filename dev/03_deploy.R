# RobustFlow development script — Phase 3: Deployment & CRAN submission
# Run sequentially and fix any issues before proceeding to the next step.

library(devtools)
library(usethis)

# -----------------------------------------------------------------------
# Step 1: Ensure documentation is current
# -----------------------------------------------------------------------
devtools::document()

# -----------------------------------------------------------------------
# Step 2: Full CRAN check — must show 0 errors, 0 warnings, 0 notes
# -----------------------------------------------------------------------
devtools::check(
  cran        = TRUE,
  remote      = TRUE,
  manual      = FALSE,  # skip PDF manual (requires LaTeX)
  vignettes   = TRUE
)

# -----------------------------------------------------------------------
# Step 3: Check spelling in documentation
# -----------------------------------------------------------------------
# install.packages("spelling")
spelling::spell_check_package()

# -----------------------------------------------------------------------
# Step 4: Check URLs in documentation are reachable
# -----------------------------------------------------------------------
urlchecker::url_check()

# -----------------------------------------------------------------------
# Step 5: Windows builder (results emailed to haitsubi@msu.edu)
# -----------------------------------------------------------------------
devtools::check_win_devel()
devtools::check_win_release()

# -----------------------------------------------------------------------
# Step 6: rhub multi-platform check (optional but recommended)
# -----------------------------------------------------------------------
# rhub::check_for_cran()

# -----------------------------------------------------------------------
# Step 7: Build the source tarball manually (inspect before submitting)
# -----------------------------------------------------------------------
devtools::build(path = ".")
# Inspect: tar -tf RobustFlow_0.1.0.tar.gz | sort

# -----------------------------------------------------------------------
# Step 8: Submit to CRAN
# -----------------------------------------------------------------------
# devtools::release() will:
#   - Run the full check
#   - Ask CRAN policy questions
#   - Submit the tarball to https://cran.r-project.org/submit.html
devtools::release()
