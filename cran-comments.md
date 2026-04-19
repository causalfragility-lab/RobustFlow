# CRAN submission comments — RobustFlow 0.1.0

## Test environments

- Local: macOS 14 (Sonoma), R 4.4.1
- GitHub Actions: ubuntu-latest, R-release and R-devel
- GitHub Actions: windows-latest, R-release
- GitHub Actions: macOS-latest, R-release
- win-builder: R-devel (via `devtools::check_win_devel()`)
- win-builder: R-release (via `devtools::check_win_release()`)

## R CMD check results

```
0 errors | 0 warnings | 0 notes
```

## Downstream dependencies

This is a new submission. There are currently no downstream packages that
depend on RobustFlow.

## Notes to CRAN reviewers

- The package includes a Shiny application launched via `run_app()`.
  All Shiny-dependent examples are wrapped in `\dontrun{}`.

- The `inst/report_templates/report.Rmd` file is an internal template used
  only when the user downloads a report from the Shiny app; it is not
  executed during `R CMD check`.

- The package uses `golem` for Shiny application structure, following the
  established golem CRAN submission guidelines.

- The `inst/app/www/` directory is intentionally sparse in v0.1.0. It
  exists to satisfy golem's expected directory structure and will contain
  custom CSS/JS in future versions.
