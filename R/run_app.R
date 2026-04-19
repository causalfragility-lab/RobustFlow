#' Launch the RobustFlow Shiny Application
#'
#' Opens the interactive RobustFlow application in a browser window. The app
#' provides a seven-tab workflow for uploading panel data, constructing
#' decision paths, diagnosing temporal drift, tracking subgroup disparities,
#' auditing robustness, identifying intervention points, and exporting
#' reproducible reports.
#'
#' @param onStart A function to call before the app is started. Passed to
#'   [shiny::shinyApp()].
#' @param options Named list of options passed to [shiny::shinyApp()].
#' @param enableBookmarking Enable bookmarking. See [shiny::shinyApp()].
#' @param uiPattern A regular expression matching the URL paths for which the
#'   Shiny UI is rendered.
#' @param ... Additional arguments passed to [golem::with_golem_options()].
#'
#' @return Invisibly returns the Shiny app object (class `"shiny.appobj"`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#'   run_app()
#' }
run_app <- function(onStart         = NULL,
                    options         = list(),
                    enableBookmarking = NULL,
                    uiPattern       = "/",
                    ...) {
  golem::with_golem_options(
    app = shiny::shinyApp(
      ui               = app_ui,
      server           = app_server,
      onStart          = onStart,
      options          = options,
      enableBookmarking = enableBookmarking,
      uiPattern        = uiPattern
    ),
    golem_opts = list(...)
  )
}
