#' Generate a reproducible R analysis script
#'
#' Writes a self-contained R script to `output_file` that replicates the
#' analysis performed in the RobustFlow Shiny application with the given
#' variable mappings. The generated script is intended as a starting point
#' for users who want to reproduce or extend the app analysis programmatically.
#'
#' @param id_var Character scalar. ID variable name.
#' @param time_var Character scalar. Time variable name.
#' @param decision_var Character scalar. Decision variable name.
#' @param group_var Character scalar or `NULL`. Group variable name.
#'   Default `NULL`.
#' @param cluster_var Character scalar or `NULL`. Cluster variable name.
#'   Default `NULL`.
#' @param focal_value Numeric scalar. Focal decision value for gap computation.
#'   Default `1`.
#' @param output_file Character scalar. Path to write the `.R` script.
#'
#' @return Invisibly returns `output_file`.
#' @export
#'
#' @examples
#' tmp <- tempfile(fileext = ".R")
#' generate_r_script(
#'   id_var       = "child_id",
#'   time_var     = "wave",
#'   decision_var = "risk_math",
#'   group_var    = "ses_group",
#'   focal_value  = 1,
#'   output_file  = tmp
#' )
#' # Show first 10 lines
#' cat(readLines(tmp, n = 10), sep = "\n")
#' unlink(tmp)
generate_r_script <- function(id_var,
                               time_var,
                               decision_var,
                               group_var    = NULL,
                               cluster_var  = NULL,
                               focal_value  = 1,
                               output_file) {
  fmt_arg <- function(x) if (!is.null(x)) paste0('"', x, '"') else "NULL"

  ver <- tryCatch(
    as.character(utils::packageVersion("RobustFlow")),
    error = function(e) "unknown"
  )

  script <- paste0(
    "# RobustFlow reproducible analysis script\n",
    "# Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n",
    "# Package version: ", ver, "\n\n",
    'library(RobustFlow)\n\n',

    "# -----------------------------------------------------------------\n",
    "# 1. Load data\n",
    "# -----------------------------------------------------------------\n",
    'data <- read.csv("your_data.csv", stringsAsFactors = FALSE)\n\n',

    "# -----------------------------------------------------------------\n",
    "# 2. Variable mapping\n",
    "# -----------------------------------------------------------------\n",
    'id_var       <- "', id_var,       '"\n',
    'time_var     <- "', time_var,     '"\n',
    'decision_var <- "', decision_var, '"\n',
    'group_var    <- ', fmt_arg(group_var),   '\n',
    'cluster_var  <- ', fmt_arg(cluster_var), '\n',
    'focal_value  <- ', focal_value,          '\n\n',

    "# -----------------------------------------------------------------\n",
    "# 3. Validate panel data\n",
    "# -----------------------------------------------------------------\n",
    "validated <- validate_panel_data(\n",
    "  data     = data,\n",
    "  id       = id_var,\n",
    "  time     = time_var,\n",
    "  decision = decision_var,\n",
    "  group    = group_var,\n",
    "  cluster  = cluster_var\n",
    ")\n",
    'cat("Individuals:", validated$n_ids,  "\\n")\n',
    'cat("Time points:", validated$n_times, "\\n")\n',
    'cat("Balanced:   ", validated$balanced, "\\n")\n\n',

    "# -----------------------------------------------------------------\n",
    "# 4. Build decision paths\n",
    "# -----------------------------------------------------------------\n",
    "paths <- build_paths(\n",
    "  data     = validated$data,\n",
    "  id       = id_var,\n",
    "  time     = time_var,\n",
    "  decision = decision_var\n",
    ")\n",
    "print(head(paths$path_counts, 10))\n",
    'cat("Path entropy:", round(paths$path_entropy, 3), "\\n")\n\n',

    "# -----------------------------------------------------------------\n",
    "# 5. Drift Intensity Index (DII)\n",
    "# -----------------------------------------------------------------\n",
    "drift <- compute_drift(\n",
    "  data     = validated$data,\n",
    "  id       = id_var,\n",
    "  time     = time_var,\n",
    "  decision = decision_var\n",
    ")\n",
    "print(drift$summary)\n",
    'cat("Mean DII:", round(drift$mean_dii, 4), "\\n")\n\n',

    "# -----------------------------------------------------------------\n",
    "# 6. Group gaps and BAI (if group variable provided)\n",
    "# -----------------------------------------------------------------\n",
    "if (!is.null(group_var)) {\n",
    "  gaps <- compute_group_gaps(\n",
    "    data        = validated$data,\n",
    "    time        = time_var,\n",
    "    decision    = decision_var,\n",
    "    group       = group_var,\n",
    "    focal_value = focal_value\n",
    "  )\n",
    "  print(gaps$gap_df)\n",
    "  bai <- compute_bai(gaps$gap)\n",
    '  cat("BAI:", bai$bai, "(", bai$direction, ")\\n")\n',
    "}\n\n",

    "# -----------------------------------------------------------------\n",
    "# 7. Temporal Fragility Index (TFI)\n",
    "# -----------------------------------------------------------------\n",
    "dii_vals <- drift$summary$DII[!is.na(drift$summary$DII)]\n",
    "tfi      <- compute_tfi_simple(dii_vals)\n",
    "print(tfi$summary_table)\n"
  )

  writeLines(script, output_file)
  invisible(output_file)
}
