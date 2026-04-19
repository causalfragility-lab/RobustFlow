# RobustFlow development script — Phase 1: Package setup
# Run these lines manually in order.
# This file is excluded from the built package via .Rbuildignore.

# -----------------------------------------------------------------------
# 0. Prerequisites (run once per machine)
# -----------------------------------------------------------------------
install.packages(c(
  "golem", "devtools", "usethis", "roxygen2",
  "testthat", "knitr", "rmarkdown", "covr",
  "shiny", "bslib", "ggplot2", "dplyr",
  "DT", "plotly", "purrr", "rlang",
  "scales", "htmltools"
))

# -----------------------------------------------------------------------
# 1. Attach packages needed for development
# -----------------------------------------------------------------------
library(golem)
library(devtools)
library(usethis)

# -----------------------------------------------------------------------
# 2. Regenerate documentation (do this after any roxygen change)
# -----------------------------------------------------------------------
devtools::document()

# -----------------------------------------------------------------------
# 3. Run the test suite
# -----------------------------------------------------------------------
devtools::test()

# -----------------------------------------------------------------------
# 4. Full CRAN-style check
# -----------------------------------------------------------------------
devtools::check()

# -----------------------------------------------------------------------
# 5. Install locally and launch the app
# -----------------------------------------------------------------------
devtools::install()
RobustFlow::run_app()

# -----------------------------------------------------------------------
# 6. Build the vignette
# -----------------------------------------------------------------------
devtools::build_vignettes()

# -----------------------------------------------------------------------
# 7. Win-builder checks (results emailed in ~30 min)
# -----------------------------------------------------------------------
devtools::check_win_devel()
devtools::check_win_release()

# -----------------------------------------------------------------------
# 8. Submit to CRAN
# -----------------------------------------------------------------------
devtools::release()
