# RobustFlow 0.1.1

## CRAN compliance fixes

* Fixed invalid URL in `man/RobustFlow-package.Rd`
  (updated to causalfragility-lab organisation).
* Added `inst/WORDLIST` to register DII, BAI, TFI
  as valid package-specific acronyms.

---

# RobustFlow 0.1.0

## Initial release

### New functions

* `validate_panel_data()` — validates and prepares longitudinal panel data,
  checks balance, and reports missingness.

* `build_paths()` — constructs individual decision paths, computes aggregate
  path frequency counts, the pooled transition matrix, and Shannon path entropy.

* `compute_transition_matrix_all()` — computes the pooled transition matrix
  across all individuals and all time intervals.

* `compute_drift()` — computes the **Drift Intensity Index (DII)** using
  period-specific transition matrices and the Frobenius norm.

* `compute_group_gaps()` — computes group-specific at-event rates and
  pairwise disparity gaps over time.

* `compute_bai()` — computes the **Bias Amplification Index (BAI)**, with
  optional standardization, to quantify whether disparity widens or narrows.

* `compute_tfi_simple()` — computes the **Temporal Fragility Index (TFI)**
  via scalar hidden-bias attenuation along a user-specified perturbation grid.

* `generate_r_script()` — exports a self-contained, reproducible R script
  that replicates the Shiny app analysis.

* `run_app()` — launches the interactive seven-tab Shiny application.

### Interactive application

The Shiny app provides a complete point-and-click workflow with:

- Data upload and validation (CSV or RDS)
- Decision path construction and visualization
- Drift diagnostics (prevalence over time, DII trend)
- Disparity auditing (group trajectories, gap evolution, BAI)
- Robustness auditing (TFI, sensitivity curve)
- Intervention point identification
- Downloadable HTML report, CSV results bundle, and reproducible R script
