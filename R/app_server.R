#' Application Server
#' @param input,output,session Standard Shiny server arguments.
#' @noRd
app_server <- function(input, output, session) {

  # -------------------------------------------------------------------
  # 1. Raw data
  # -------------------------------------------------------------------
  raw_data <- shiny::reactive({
    shiny::req(input$data_file)
    ext <- tools::file_ext(input$data_file$name)
    switch(
      tolower(ext),
      csv = read.csv(input$data_file$datapath, stringsAsFactors = FALSE),
      rds = readRDS(input$data_file$datapath),
      shiny::validate(shiny::need(FALSE, "Upload a .csv or .rds file."))
    )
  })

  # -------------------------------------------------------------------
  # 2. Populate variable selectors
  # -------------------------------------------------------------------
  shiny::observeEvent(raw_data(), {
    vars <- names(raw_data())
    output$id_ui <- shiny::renderUI(
      shiny::selectInput("id_var", "ID variable", choices = vars)
    )
    output$time_ui <- shiny::renderUI(
      shiny::selectInput("time_var", "Time variable", choices = vars)
    )
    output$decision_ui <- shiny::renderUI(
      shiny::selectInput("decision_var", "Decision variable", choices = vars)
    )
    output$group_ui <- shiny::renderUI(
      shiny::selectInput("group_var", "Group variable (optional)",
                         choices = c("None", vars))
    )
    output$cluster_ui <- shiny::renderUI(
      shiny::selectInput("cluster_var", "Cluster variable (optional)",
                         choices = c("None", vars))
    )
  })

  # -------------------------------------------------------------------
  # 3. Validation
  # -------------------------------------------------------------------
  validated <- shiny::eventReactive(input$validate_data, {
    shiny::req(raw_data(), input$id_var, input$time_var, input$decision_var)
    tryCatch(
      validate_panel_data(
        data     = raw_data(),
        id       = input$id_var,
        time     = input$time_var,
        decision = input$decision_var,
        group    = .nullify(input$group_var),
        cluster  = .nullify(input$cluster_var)
      ),
      error = function(e) {
        shiny::validate(shiny::need(FALSE, conditionMessage(e)))
      }
    )
  })

  output$validation_status <- shiny::renderUI({
    shiny::req(validated())
    shiny::div(
      class = "alert alert-success p-2 small mt-2",
      shiny::icon("circle-check"), " Data validated successfully."
    )
  })

  # -------------------------------------------------------------------
  # 4. Tab: Data
  # -------------------------------------------------------------------
  output$n_ids    <- shiny::renderText({
    shiny::req(validated()); as.character(validated()$n_ids)
  })
  output$n_times  <- shiny::renderText({
    shiny::req(validated()); as.character(validated()$n_times)
  })
  output$balanced <- shiny::renderText({
    shiny::req(validated())
    if (validated()$balanced) "Yes" else "No"
  })

  output$data_preview <- DT::renderDT({
    shiny::req(validated())
    DT::datatable(
      utils::head(validated()$data, 50L),
      options  = list(pageLength = 10L, scrollX = TRUE),
      rownames = FALSE
    )
  })

  output$missing_summary <- DT::renderDT({
    shiny::req(validated())
    d  <- validated()$data
    ms <- data.frame(
      Variable    = names(d),
      N_Missing   = vapply(d, function(x) sum(is.na(x)), integer(1L)),
      Pct_Missing = vapply(d, function(x) round(mean(is.na(x)) * 100, 1), numeric(1L)),
      stringsAsFactors = FALSE
    )
    DT::datatable(ms, rownames = FALSE,
                  options = list(pageLength = 15L, dom = "t"))
  })

  # -------------------------------------------------------------------
  # 5. Core computations
  # -------------------------------------------------------------------
  paths_obj <- shiny::reactive({
    shiny::req(validated())
    build_paths(
      data     = validated()$data,
      id       = input$id_var,
      time     = input$time_var,
      decision = input$decision_var,
      sep      = input$path_sep
    )
  })

  drift_obj <- shiny::reactive({
    shiny::req(validated())
    compute_drift(
      data     = validated()$data,
      id       = input$id_var,
      time     = input$time_var,
      decision = input$decision_var
    )
  })

  gap_obj <- shiny::reactive({
    shiny::req(validated())
    gv <- .nullify(input$group_var)
    shiny::req(!is.null(gv))
    compute_group_gaps(
      data        = validated()$data,
      time        = input$time_var,
      decision    = input$decision_var,
      group       = gv,
      focal_value = input$focal_value
    )
  })

  bai_obj <- shiny::reactive({
    shiny::req(gap_obj())
    g <- gap_obj()$gap
    g <- g[!is.na(g)]
    shiny::req(length(g) >= 2L)
    compute_bai(g)
  })

  tfi_obj <- shiny::reactive({
    shiny::req(drift_obj())
    dii <- drift_obj()$summary$DII
    dii <- dii[!is.na(dii)]
    shiny::req(length(dii) >= 2L)
    compute_tfi_simple(dii)
  })

  # -------------------------------------------------------------------
  # 6. Tab: Paths
  # -------------------------------------------------------------------
  output$path_bar <- plotly::renderPlotly({
    shiny::req(paths_obj())
    df      <- utils::head(paths_obj()$path_counts, 15L)
    df$path <- factor(df$path, levels = rev(df$path))
    p <- ggplot2::ggplot(df, ggplot2::aes(x = path, y = n)) +
      ggplot2::geom_col(fill = "#2c7bb6") +
      ggplot2::coord_flip() +
      ggplot2::labs(x = "Decision Path", y = "Frequency",
                    title = "Top 15 Decision Paths") +
      ggplot2::theme_minimal()
    plotly::ggplotly(p)
  })

  output$path_table <- DT::renderDT({
    shiny::req(paths_obj())
    DT::datatable(paths_obj()$path_counts, rownames = FALSE,
                  options = list(pageLength = 10L, scrollX = TRUE))
  })

  output$transition_table <- DT::renderDT({
    shiny::req(paths_obj())
    mat <- paths_obj()$transition_matrix
    shiny::req(nrow(mat) > 0L)
    DT::datatable(as.data.frame(mat),
                  options = list(dom = "t", scrollX = TRUE))
  })

  # -------------------------------------------------------------------
  # 7. Tab: Drift
  # -------------------------------------------------------------------
  output$prevalence_plot <- plotly::renderPlotly({
    shiny::req(validated())
    d   <- validated()$data
    agg <- aggregate(
      as.numeric(d[[input$decision_var]] == input$focal_value),
      by  = list(time = d[[input$time_var]]),
      FUN = function(x) mean(x, na.rm = TRUE)
    )
    names(agg)[2L] <- "prevalence"
    p <- ggplot2::ggplot(agg, ggplot2::aes(x = time, y = prevalence,
                                            group = 1)) +
      ggplot2::geom_line(color = "#d7191c", linewidth = 1) +
      ggplot2::geom_point(size = 2) +
      ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
      ggplot2::labs(x = "Time", y = "Prevalence",
                    title = "Decision Prevalence Over Time") +
      ggplot2::theme_minimal()
    plotly::ggplotly(p)
  })

  output$dii_plot <- plotly::renderPlotly({
    shiny::req(drift_obj())
    df <- drift_obj()$summary
    p <- ggplot2::ggplot(df, ggplot2::aes(x = time, y = DII, group = 1)) +
      ggplot2::geom_line(color = "#1a9641", linewidth = 1) +
      ggplot2::geom_point(size = 2) +
      ggplot2::labs(x = "Time", y = "DII",
                    title = "Drift Intensity Index Over Time") +
      ggplot2::theme_minimal()
    plotly::ggplotly(p)
  })

  output$drift_table <- DT::renderDT({
    shiny::req(drift_obj())
    DT::datatable(drift_obj()$summary, rownames = FALSE,
                  options = list(pageLength = 10L))
  })

  # -------------------------------------------------------------------
  # 8. Tab: Disparities
  # -------------------------------------------------------------------
  output$group_traj_plot <- plotly::renderPlotly({
    shiny::req(gap_obj())
    df <- gap_obj()$long_format
    p <- ggplot2::ggplot(df, ggplot2::aes(x = time, y = rate,
                                           color = group, group = group)) +
      ggplot2::geom_line(linewidth = 1) +
      ggplot2::geom_point(size = 2) +
      ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
      ggplot2::labs(x = "Time", y = "Rate", color = "Group",
                    title = "Group Trajectories") +
      ggplot2::theme_minimal()
    plotly::ggplotly(p)
  })

  output$gap_plot <- plotly::renderPlotly({
    shiny::req(gap_obj())
    df <- gap_obj()$gap_df
    p <- ggplot2::ggplot(df, ggplot2::aes(x = time, y = gap, group = 1)) +
      ggplot2::geom_line(color = "#762a83", linewidth = 1) +
      ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                           color = "grey40") +
      ggplot2::geom_point(size = 2) +
      ggplot2::labs(x = "Time", y = "Gap (Group 1 \u2212 Group 2)",
                    title = "Disparity Gap Over Time") +
      ggplot2::theme_minimal()
    plotly::ggplotly(p)
  })

  output$bai_val <- shiny::renderText({
    shiny::req(bai_obj()); as.character(bai_obj()$bai)
  })
  output$bai_dir <- shiny::renderText({
    shiny::req(bai_obj()); bai_obj()$direction
  })

  output$gap_table <- DT::renderDT({
    shiny::req(gap_obj())
    DT::datatable(gap_obj()$gap_df, rownames = FALSE,
                  options = list(pageLength = 10L))
  })

  # -------------------------------------------------------------------
  # 9. Tab: Robustness
  # -------------------------------------------------------------------
  output$tfi_val <- shiny::renderText({
    shiny::req(tfi_obj())
    t <- tfi_obj()$tfi
    if (is.infinite(t)) "Inf" else as.character(round(t, 4L))
  })
  output$tfi_interp <- shiny::renderText({
    shiny::req(tfi_obj())
    t <- tfi_obj()$tfi
    if (is.infinite(t))  "Highly robust"
    else if (t > 0.5)    "Moderately robust"
    else                 "Fragile"
  })

  output$tfi_plot <- plotly::renderPlotly({
    shiny::req(tfi_obj())
    df <- tfi_obj()$sensitivity_curve
    p <- ggplot2::ggplot(
      df, ggplot2::aes(x = perturbation, y = adjusted_effect)) +
      ggplot2::geom_line(color = "#4575b4", linewidth = 1) +
      ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                           color = "#d73027") +
      ggplot2::labs(x = "Hidden Bias Parameter (u)",
                    y = "Adjusted Effect",
                    title = "TFI Sensitivity Curve") +
      ggplot2::theme_minimal()
    plotly::ggplotly(p)
  })

  output$robust_table <- DT::renderDT({
    shiny::req(tfi_obj())
    DT::datatable(tfi_obj()$summary_table, rownames = FALSE,
                  options = list(dom = "t"))
  })

  # -------------------------------------------------------------------
  # 10. Tab: Intervention
  # -------------------------------------------------------------------
  output$transition_risk_table <- DT::renderDT({
    shiny::req(paths_obj())
    mat <- paths_obj()$transition_matrix
    shiny::req(nrow(mat) > 0L)
    df <- as.data.frame(as.table(mat), stringsAsFactors = FALSE)
    names(df) <- c("From", "To", "Count")
    df <- df[order(-df$Count), ]
    rownames(df) <- NULL
    DT::datatable(df, rownames = FALSE,
                  options = list(pageLength = 10L))
  })

  output$disparity_steps_table <- DT::renderDT({
    shiny::req(gap_obj())
    df <- gap_obj()$gap_df
    df$AbsGap <- abs(df$gap)
    df <- df[order(-df$AbsGap), ]
    rownames(df) <- NULL
    DT::datatable(df, rownames = FALSE,
                  options = list(pageLength = 10L))
  })

  # -------------------------------------------------------------------
  # 11. Tab: Report
  # -------------------------------------------------------------------
  output$download_html <- shiny::downloadHandler(
    filename = function() {
      paste0("RobustFlow_Report_", format(Sys.Date(), "%Y%m%d"), ".html")
    },
    content = function(file) {
      template <- system.file("report_templates", "report.Rmd", package = "RobustFlow")
      rmarkdown::render(
        input       = template,
        output_file = file,
        params      = list(
          validated = validated(),
          paths_obj = paths_obj(),
          drift_obj = drift_obj(),
          gap_obj   = if (!is.null(.nullify(input$group_var))) gap_obj() else NULL,
          bai_obj   = if (!is.null(.nullify(input$group_var))) bai_obj() else NULL,
          tfi_obj   = tfi_obj(),
          run_date  = Sys.time()
        ),
        envir = new.env(parent = globalenv())
      )
    }
  )

  output$download_csv <- shiny::downloadHandler(
    filename = function() {
      paste0("RobustFlow_Results_", format(Sys.Date(), "%Y%m%d"), ".zip")
    },
    content = function(file) {
      tmp <- tempdir()
      utils::write.csv(paths_obj()$path_counts,
                       file.path(tmp, "path_counts.csv"),
                       row.names = FALSE)
      utils::write.csv(drift_obj()$summary,
                       file.path(tmp, "drift_summary.csv"),
                       row.names = FALSE)
      if (!is.null(.nullify(shiny::isolate(input$group_var)))) {
        utils::write.csv(gap_obj()$gap_df,
                         file.path(tmp, "gap_summary.csv"),
                         row.names = FALSE)
      }
      csvs <- list.files(tmp, pattern = "\\.csv$", full.names = TRUE)
      utils::zip(file, files = csvs, flags = "-j")
    }
  )

  output$download_rscript <- shiny::downloadHandler(
    filename = function() {
      paste0("RobustFlow_Script_", format(Sys.Date(), "%Y%m%d"), ".R")
    },
    content = function(file) {
      generate_r_script(
        id_var       = input$id_var,
        time_var     = input$time_var,
        decision_var = input$decision_var,
        group_var    = .nullify(input$group_var),
        cluster_var  = .nullify(input$cluster_var),
        focal_value  = input$focal_value,
        output_file  = file
      )
    }
  )
}

# Internal helper: convert "None" selector value to NULL
.nullify <- function(x) if (is.null(x) || x == "None") NULL else x
