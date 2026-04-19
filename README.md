# RobustFlow <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/subirhait/RobustFlow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/subirhait/RobustFlow/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/RobustFlow)](https://CRAN.R-project.org/package=RobustFlow)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

**RobustFlow** is an R package for auditing temporal drift, subgroup
disparities, and robustness in longitudinal decision systems. It implements
three new metrics and provides an interactive Shiny application for
exploratory analysis and reproducible reporting.

---

## Motivation

Researchers who study repeated decisions — risk classifications, tracking
placements, intervention assignments — face three questions that existing
tools do not address together:

1. **Is the decision structure stable over time?** (Drift)
2. **Are group disparities widening?** (Amplification)
3. **How fragile are these conclusions to hidden bias?** (Robustness)

RobustFlow answers all three in a single, coherent workflow.

---

## Signature metrics

| Metric | Symbol | Definition |
|--------|--------|-----------|
| **Drift Intensity Index** | DII | Frobenius norm of consecutive transition matrix differences |
| **Bias Amplification Index** | BAI | Gap_T − Gap_1 (change in disparity from first to last wave) |
| **Temporal Fragility Index** | TFI | Minimum hidden-bias attenuation to nullify a longitudinal trend |

---

## Installation

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("subirhait/RobustFlow")
```

Once on CRAN:

```r
install.packages("RobustFlow")
```

---

## Quick start

```r
library(RobustFlow)

# 1. Validate panel data
validated <- validate_panel_data(
  data     = my_data,
  id       = "child_id",
  time     = "wave",
  decision = "risk_math",
  group    = "ses_group"
)

# 2. Build decision paths
paths <- build_paths(
  data     = validated$data,
  id       = "child_id",
  time     = "wave",
  decision = "risk_math"
)
paths$path_counts       # frequency table
paths$transition_matrix # pooled transition matrix
paths$path_entropy      # Shannon entropy

# 3. Drift Intensity Index
drift <- compute_drift(validated$data, "child_id", "wave", "risk_math")
drift$summary           # DII per wave
drift$mean_dii          # mean DII across all periods

# 4. Group gaps and BAI
gaps <- compute_group_gaps(validated$data, "wave", "risk_math", "ses_group")
bai  <- compute_bai(gaps$gap)
bai$bai                 # e.g. 0.12
bai$direction           # "amplification"

# 5. TFI
tfi <- compute_tfi_simple(drift$summary$DII[!is.na(drift$summary$DII)])
tfi$tfi                 # minimum attenuation to nullify trend

# 6. Interactive app
run_app()
```

---

## The Shiny application

`run_app()` opens a browser-based interface with seven tabs:

| Tab | Content |
|-----|---------|
| **Data** | Upload (CSV/RDS), variable mapping, balance diagnostics, missingness |
| **Paths** | Path bar chart, frequency table, transition matrix |
| **Drift** | Prevalence over time, DII trend plot, drift summary table |
| **Disparities** | Group trajectories, gap plot, BAI summary |
| **Robustness** | TFI value, sensitivity curve, robustness summary |
| **Intervention** | Highest-risk transitions, disparity-generating steps |
| **Report** | HTML report download, CSV bundle, reproducible R script |

---

## Example dataset

The package vignette demonstrates a simulated longitudinal study of
mathematics risk status across five elementary school waves for 200
children, with three SES groups. This mimics the structure of the
Early Childhood Longitudinal Study, Kindergarten Class of 2010–11
(ECLS-K:2011).

```r
vignette("introduction", package = "RobustFlow")
```

---

## Citation

```bibtex
@Manual{RobustFlow2025,
  title  = {{RobustFlow}: Robustness and Drift Auditing for Longitudinal
            Decision Systems},
  author = {Subir Hait},
  year   = {2025},
  note   = {R package version 0.1.0},
  url    = {https://github.com/subirhait/RobustFlow}
}
```

---

## License

GPL (>= 3) — see [LICENSE](LICENSE) for details.
