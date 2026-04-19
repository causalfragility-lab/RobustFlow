#' Application UI
#' @param request Internal Shiny bookmarking parameter.
#' @noRd
app_ui <- function(request) {
  htmltools::tagList(
    .add_external_resources(),
    shiny::fluidPage(
      theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
      shiny::titlePanel(
        shiny::div(
          shiny::h2("RobustFlow",
                    style = "display:inline; margin-right:12px;"),
          shiny::span(
            "Robustness & Drift Auditing for Longitudinal Decision Systems",
            style = "font-size:14px; color:#6c757d;"
          )
        )
      ),
      shiny::sidebarLayout(
        shiny::sidebarPanel(
          width = 3,
          shiny::h5("1. Upload Data", class = "text-primary fw-bold"),
          shiny::fileInput("data_file", label = NULL,
                           accept      = c(".csv", ".rds"),
                           buttonLabel = "Browse...",
                           placeholder = "No file selected"),
          shiny::hr(),
          shiny::h5("2. Map Variables", class = "text-primary fw-bold"),
          shiny::uiOutput("id_ui"),
          shiny::uiOutput("time_ui"),
          shiny::uiOutput("decision_ui"),
          shiny::uiOutput("group_ui"),
          shiny::uiOutput("cluster_ui"),
          shiny::hr(),
          shiny::h5("3. Options", class = "text-primary fw-bold"),
          shiny::selectInput(
            "path_sep", "Path separator",
            choices  = c("Arrow" = "->", "Comma" = ",", "Pipe" = "|"),
            selected = "->"
          ),
          shiny::numericInput(
            "focal_value", "Focal event value (for gap/rates)",
            value = 1, min = 0, step = 1
          ),
          shiny::hr(),
          shiny::actionButton("validate_data", "Validate & Load",
                              class = "btn-primary w-100"),
          shiny::br(),
          shiny::br(),
          shiny::uiOutput("validation_status")
        ),
        shiny::mainPanel(
          width = 9,
          shiny::tabsetPanel(
            id   = "main_tabs",
            type = "tabs",

            # Tab 1: Data
            shiny::tabPanel(
              title = htmltools::tagList(shiny::icon("table"), " Data"),
              value = "tab_data",
              shiny::br(),
              shiny::fluidRow(
                shiny::column(4, .value_box_ui("n_ids",    "Individuals")),
                shiny::column(4, .value_box_ui("n_times",  "Time Points")),
                shiny::column(4, .value_box_ui("balanced", "Balanced Panel"))
              ),
              shiny::br(),
              shiny::h5("Data Preview (first 50 rows)"),
              DT::DTOutput("data_preview"),
              shiny::br(),
              shiny::h5("Missingness Summary"),
              DT::DTOutput("missing_summary")
            ),

            # Tab 2: Paths
            shiny::tabPanel(
              title = htmltools::tagList(
                shiny::icon("diagram-project"), " Paths"),
              value = "tab_paths",
              shiny::br(),
              shiny::h5("Top 15 Decision Paths"),
              plotly::plotlyOutput("path_bar", height = "360px"),
              shiny::br(),
              shiny::h5("Path Frequency Table"),
              DT::DTOutput("path_table"),
              shiny::br(),
              shiny::h5("Aggregate Transition Matrix"),
              DT::DTOutput("transition_table")
            ),

            # Tab 3: Drift
            shiny::tabPanel(
              title = htmltools::tagList(
                shiny::icon("chart-line"), " Drift"),
              value = "tab_drift",
              shiny::br(),
              shiny::fluidRow(
                shiny::column(6,
                  shiny::h5("Prevalence Over Time"),
                  plotly::plotlyOutput("prevalence_plot", height = "300px")
                ),
                shiny::column(6,
                  shiny::h5("Drift Intensity Index (DII)"),
                  plotly::plotlyOutput("dii_plot", height = "300px")
                )
              ),
              shiny::br(),
              shiny::h5("Drift Summary Table"),
              DT::DTOutput("drift_table")
            ),

            # Tab 4: Disparities
            shiny::tabPanel(
              title = htmltools::tagList(
                shiny::icon("scale-balanced"), " Disparities"),
              value = "tab_disparities",
              shiny::br(),
              shiny::fluidRow(
                shiny::column(6,
                  shiny::h5("Group Trajectories"),
                  plotly::plotlyOutput("group_traj_plot", height = "300px")
                ),
                shiny::column(6,
                  shiny::h5("Disparity Gap Over Time"),
                  plotly::plotlyOutput("gap_plot", height = "300px")
                )
              ),
              shiny::br(),
              shiny::fluidRow(
                shiny::column(6, .value_box_ui("bai_val", "BAI")),
                shiny::column(6, .value_box_ui("bai_dir", "Direction"))
              ),
              shiny::br(),
              shiny::h5("Gap Table"),
              DT::DTOutput("gap_table")
            ),

            # Tab 5: Robustness
            shiny::tabPanel(
              title = htmltools::tagList(
                shiny::icon("shield-halved"), " Robustness"),
              value = "tab_robust",
              shiny::br(),
              shiny::fluidRow(
                shiny::column(6, .value_box_ui("tfi_val",    "TFI")),
                shiny::column(6, .value_box_ui("tfi_interp", "Interpretation"))
              ),
              shiny::br(),
              shiny::h5("Sensitivity Curve"),
              plotly::plotlyOutput("tfi_plot", height = "360px"),
              shiny::br(),
              shiny::h5("Robustness Summary"),
              DT::DTOutput("robust_table")
            ),

            # Tab 6: Intervention
            shiny::tabPanel(
              title = htmltools::tagList(
                shiny::icon("bullseye"), " Intervention"),
              value = "tab_intervention",
              shiny::br(),
              shiny::h5("Highest-Risk Transitions"),
              DT::DTOutput("transition_risk_table"),
              shiny::br(),
              shiny::h5("Disparity-Generating Steps (by |Gap|)"),
              DT::DTOutput("disparity_steps_table")
            ),

            # Tab 7: Report
            shiny::tabPanel(
              title = htmltools::tagList(
                shiny::icon("file-export"), " Report"),
              value = "tab_report",
              shiny::br(),
              shiny::h5("Export Options"),
              shiny::fluidRow(
                shiny::column(4,
                  shiny::wellPanel(
                    shiny::h6("HTML Report"),
                    shiny::p("Full analysis with all metrics and figures."),
                    shiny::downloadButton(
                      "download_html", "Download HTML",
                      class = "btn-success w-100")
                  )
                ),
                shiny::column(4,
                  shiny::wellPanel(
                    shiny::h6("Results Bundle (CSV)"),
                    shiny::p("All computed tables as a zipped CSV bundle."),
                    shiny::downloadButton(
                      "download_csv", "Download CSVs",
                      class = "btn-info w-100")
                  )
                ),
                shiny::column(4,
                  shiny::wellPanel(
                    shiny::h6("Reproducible R Script"),
                    shiny::p("Self-contained R code for all computations."),
                    shiny::downloadButton(
                      "download_rscript", "Download .R",
                      class = "btn-warning w-100")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

# Internal: add static resources from inst/app/www/
.add_external_resources <- function() {
  www_path <- system.file("app/www", package = "RobustFlow")
  if (nzchar(www_path)) {
    golem::add_resource_path("www", www_path)
  }
  htmltools::tags$head(
    htmltools::tags$title("RobustFlow")
  )
}

# Internal: simple value-display card (no shinydashboard dependency)
.value_box_ui <- function(id, label) {
  shiny::div(
    class = "card text-center p-3 mb-2",
    shiny::div(
      class = "card-body p-1",
      shiny::p(class = "card-title text-muted small mb-1", label),
      shiny::h4(class = "card-text fw-bold",
                shiny::textOutput(id, inline = TRUE))
    )
  )
}
