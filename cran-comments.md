# CRAN resubmission comments — RobustFlow 0.1.1

## Resubmission notes

This is a resubmission addressing reviewer feedback from Benjamin Altmann
(2026-04-21) and Uwe Ligges (2026-04-22).

### Changes made in response to reviewer comments

1. **References added to DESCRIPTION**: Added three citations to the `Description`
   field covering the Frobenius norm (Golub & Van Loan, 2013, ISBN:9781421407944),
   hidden-bias sensitivity analysis (Rosenbaum, 2002, ISBN:9781441912633), and
   disparity trajectory methods (Duncan & Murnane, 2011, ISBN:9780871542731),
   in the format required by CRAN policy.

2. **`\dontrun{}` replaced with `if (interactive()) {}`**: The `run_app()`
   example in `run_app.R` now uses `if (interactive()) {}` to signal that
   the function is intended for interactive use only.

3. **Invalid DOI removed from DESCRIPTION** (per Uwe Ligges): The reference
   `Duncan & Magnuson (2011) <doi:10.1177/0002716210393335>` returned a 404
   and has been replaced with the correct bibliographic entry for the
   published edited volume: Duncan & Murnane (2011, ISBN:9780871542731),
   *Whither Opportunity? Rising Inequality, Schools, and Children's Life
   Chances*, Russell Sage Foundation. No DOI is used for this reference.

---

## Test environments

- Local: Windows 11 x64, R 4.5.1 (2025-06-13 ucrt)
- GitHub Actions: ubuntu-latest, R-release and R-devel
- GitHub Actions: windows-latest, R-release
- GitHub Actions: macOS-latest, R-release
- win-builder: R-devel (via `devtools::check_win_devel()`)
- win-builder: R-release (via `devtools::check_win_release()`)

## R CMD check results
0 errors | 0 warnings | 1 note
### Note explanation
checking for future file timestamps ... NOTE
unable to verify current time
This is a transient network/system issue on the local Windows machine and is
unrelated to the package itself. It does not appear on win-builder, GitHub
Actions, or any other CI environment and will not reproduce on CRAN infrastructure.

---

## Downstream dependencies

There are currently no downstream packages that depend on RobustFlow.

## Notes to CRAN reviewers

- The package includes a Shiny application launched via `run_app()`.
  The example for `run_app()` is now wrapped in `if (interactive()) {}`
  as requested.
- The `inst/report_templates/report.Rmd` file is an internal template used
  only when the user downloads a report from the Shiny app; it is not
  executed during `R CMD check`.
- The package uses `golem` for Shiny application structure, following the
  established golem CRAN submission guidelines.
- The `inst/app/www/` directory is intentionally sparse in v0.1.1. It
  exists to satisfy golem's expected directory structure and will contain
  custom CSS/JS in future versions.
