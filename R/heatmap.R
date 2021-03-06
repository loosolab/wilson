#' heatmap module UI representation
#'
#' @param id The ID of the modules namespace.
#' @param row.label Boolean Value set initial Value for rowlabel checkbox (Default = TRUE).
#'
#' @return A list with HTML tags from \code{\link[shiny]{tag}}.
#'
#' @export
heatmapUI <- function(id, row.label = TRUE) {
  ns <- shiny::NS(id)

  shiny::tagList(shiny::fluidPage(
    rintrojs::introjsUI(),
    shinyjs::useShinyjs(),
    shiny::fluidRow(shinydashboard::box(width = 12,
                                        shiny::div(style = "overflow-y: scroll; overflow-x: scroll; height: 800px; text-align: center",
                                                   shiny::uiOutput(ns("heatmap"))))),
    shiny::fluidRow(
      shinydashboard::box(
        width = 12,
        collapsible = TRUE,
        shiny::fluidRow(
          shiny::column(
            width = 3,
            shiny::div(id = ns("guide_selection"),
                       columnSelectorUI(id = ns("select")))),
          shiny::column(
            width = 3,
            shiny::div(id = ns("guide_cluster"),
                       shiny::selectInput(
                         ns("clustering"),
                         label = "Choose clustering",
                         choices = c("columns and rows" = "both", "only columns" = "column", "only rows" = "row", "no clustering" = "none"),
                         multiple = FALSE
                       ),
                       shiny::selectInput(
                         ns("cluster_distance"),
                         label = "Cluster distance",
                         choices = c("euclidean", "maximum", "manhattan", "canberra", "binary", "minkowski", "pearson", "spearman", "kendall"),
                         multiple = FALSE
                       ),
                       shiny::selectInput(
                         ns("cluster_method"),
                         label = "Cluster method",
                         choices = c("average", "ward.D", "ward.D2", "single", "complete", "mcquitty"),
                         multiple = FALSE))
          ),
          shiny::column(
            width = 3,
            shiny::div(id = ns("guide_transformation"),
                       transformationUI(id = ns("transform"), choices = list(`None` = "raw", `log2` = "log2", `-log2` = "-log2", `log10` = "log10", `-log10` = "-log10", `Z score` = "zscore"), transposeOptions = TRUE)
            ),
            shiny::div(id = ns("guide_coloring"),
                       shiny::selectInput(
                         ns("distribution"),
                         label = "Data distribution",
                         choices = c("Sequential", "Diverging"),
                         multiple = FALSE
                       ),
                       colorPickerUI(ns("color"), show.transparency = FALSE)
            )
          ),
          shiny::column(
            width = 3,
            shiny::div(id = ns("guide_options"),
                       shiny::textInput(ns("label"), label = "Unit label", placeholder = "Enter unit..."),
                       shiny::checkboxInput(ns("row_label"), label = "Row label", value = row.label),
                       labelUI(ns("labeller")),
                       shiny::checkboxInput(ns("column_label"), label = "Column label", value = TRUE)
            )
          )
        ),
        shiny::fluidRow(
          shiny::column(
            width = 12,
            shiny::div(id = ns("guide_buttons"),
                shiny::actionButton(ns("plot"), "Plot", style = "color: #fff; background-color: #3c8dbc"),
                shiny::actionButton(ns("reset"), "Reset", style = "color: #fff; background-color: #3c8dbc"),
                shiny::actionButton(ns("guide"), "Launch guide", style = "color: #fff; background-color: #3c8dbc", icon = shiny::icon("question-circle")),
                shiny::downloadButton(outputId = ns("download"), label = "Download")
            )
          )
        )
      )
    )
  ))
}

#' heatmap module server logic
#'
#' @param input Shiny's input object
#' @param output Shiny's output object
#' @param session Shiny's session object
#' @param clarion A clarion object. See \code{\link[wilson]{Clarion}}. (Supports reactive)
#' @param plot.method Choose which method is used for plotting. Either "static" or "interactive" (Default = "static").
#' @param label.sep Separator used for label merging (Default = ", ").
#' @param width Width of the plot in cm. Defaults to minimal size for readable labels and supports reactive.
#' @param height Height of the plot in cm. Defaults to minimal size for readable labels and supports reactive.
#' @param ppi Pixel per inch. Defaults to 72 and supports reactive.
#' @param scale Scale plot size. Defaults to 1, supports reactive.
#'
#' @return Reactive containing data used for plotting.
#'
#' @export
heatmap <- function(input, output, session, clarion, plot.method = "static", label.sep = ", ", width = "auto", height = "auto", ppi = 72, scale = 1) {
  # globals/ initialization #####
  # cluster limitation
  static <- 11000
  interactive <- 3000
  # clear plot
  clear_plot <- shiny::reactiveVal(FALSE)
  # disable downloadButton on init
  shinyjs::disable("download")

  # input preparation #####
  object <- shiny::reactive({
    # support reactive
    if (shiny::is.reactive(clarion)) {
      if (!methods::is(clarion(), "Clarion")) shiny::stopApp("Object of class 'Clarion' needed!")

      clarion()$clone(deep = TRUE)
    } else {
      if (!methods::is(clarion, "Clarion")) shiny::stopApp("Object of class 'Clarion' needed!")

      clarion$clone(deep = TRUE)
    }
  })

  # handle reactive sizes
  size <- shiny::reactive({
    width <- ifelse(shiny::is.reactive(width), width(), width)
    height <- ifelse(shiny::is.reactive(height), height(), height)
    ppi <- ifelse(shiny::is.reactive(ppi), ppi(), ppi)
    scale <- ifelse(shiny::is.reactive(scale), scale(), scale)

    if (!is.numeric(width) || width <= 0) {
      width <- "auto"
    }
    if (!is.numeric(height) || height <= 0) {
      if (plot.method == "interactive") {
        height <- 28
      } else {
        height <- "auto"
      }
    }
    if (!is.numeric(ppi) || ppi <= 0) {
      ppi <- 72
    }

    list(width = width,
         height = height,
         ppi = ppi,
         scale = scale)
  })

  # modules/ ui #####
  columns <- shiny::callModule(columnSelector, "select", type.columns = shiny::reactive(object()$metadata[level != "feature", intersect(names(object()$metadata), c("key", "level", "label", "sub_label")), with = FALSE]), column.type.label = "Column types to choose from")
  transform <- shiny::callModule(transformation, "transform", data = shiny::reactive(as.matrix(object()$data[, columns$selected_columns(), with = FALSE])), pseudocount = shiny::reactive(ifelse(object()$metadata[key == columns$selected_columns()[1]][["level"]] == "contrast", 0, 1)), replaceNA = FALSE)
  color <- shiny::callModule(colorPicker, "color", distribution = shiny::reactive(tolower(input$distribution)), winsorize = shiny::reactive(equalize(transform$data())))
  custom_label <- shiny::callModule(label, "labeller", data = shiny::reactive(object()$data), label = "Select row label", sep = label.sep, disable = shiny::reactive(!input$row_label))

  # automatic unitlabel
  shiny::observe({
    shiny::updateTextInput(session = session, inputId = "label", value = transform$method())
  })

  # functionality/ plotting #####
  # reset ui
  shiny::observeEvent(input$reset, {
    log_message("Heatmap: reset", "INFO", token = session$token)

    shinyjs::reset("cluster_distance")
    shinyjs::reset("cluster_method")
    shinyjs::reset("clustering")
    shinyjs::reset("distribution")
    shinyjs::reset("label")
    shinyjs::reset("row_label")
    shinyjs::reset("column_label")
    columns <<- shiny::callModule(columnSelector, "select", type.columns = shiny::reactive(object()$metadata[level != "feature", intersect(names(object()$metadata), c("key", "level", "label", "sub_label")), with = FALSE]), column.type.label = "Column types to choose from")
    transform <<- shiny::callModule(transformation, "transform", data = shiny::reactive(as.matrix(object()$data[, columns$selected_columns(), with = FALSE])), pseudocount = shiny::reactive(ifelse(object()$metadata[key == columns$selected_columns()[1]][["level"]] == "contrast", 0, 1)), replaceNA = FALSE)
    color <<- shiny::callModule(colorPicker, "color", distribution = shiny::reactive(tolower(input$distribution)), winsorize = shiny::reactive(equalize(transform$data())))
    custom_label <<- shiny::callModule(label, "labeller", data = shiny::reactive(object()$data), label = "Select row label", sep = label.sep, disable = shiny::reactive(!input$row_label))
    clear_plot(TRUE)
  })

  result_data <- shiny::eventReactive(input$plot, {
    # new progress indicator
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(0.2, message = "Compute data")

    processed_data <- data.table::data.table(object()$data[, object()$get_id(), with = FALSE], transform$data())

    progress$set(1)
    return(processed_data)
  })

  plot <- shiny::eventReactive(input$plot, {
    log_message("Heatmap: computing plot...", "INFO", token = session$token)

    # enable downloadButton
    shinyjs::enable("download")
    clear_plot(FALSE)

    # new progress indicator
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(0.2, message = "Compute plot")

    plot <- create_heatmap(
      data = result_data(),
      unitlabel = input$label,
      row.label = input$row_label,
      row.custom.label = custom_label()$label,
      column.label = input$column_label,
      column.custom.label = make.unique(columns$label()),
      clustering = input$clustering,
      clustdist = input$cluster_distance,
      clustmethod = input$cluster_method,
      colors = color()$palette,
      width = size()$width,
      height = size()$height,
      ppi = size()$ppi,
      scale = size()$scale,
      plot.method = plot.method,
      winsorize.colors = color()$winsorize
    )

    progress$set(1)

    log_message("Heatmap: done.", "INFO", token = session$token)
    return(plot)
  })

  # render plot #####
  if (plot.method == "interactive") {
    output$heatmap <- shiny::renderUI({
      shinycssloaders::withSpinner(plotly::plotlyOutput(session$ns("interactive")), proxy.height = "800px")
    })

    output$interactive <- plotly::renderPlotly({
      if (clear_plot()) {
        return()
      } else {
        log_message("Heatmap: render plot interactive", "INFO", token = session$token)

        # new progress indicator
        progress <- shiny::Progress$new()
        on.exit(progress$close())
        progress$set(0.2, message = "Render plot")

        plot <- plot()$plot

        progress$set(1)

        return(plot)
      }
    })
  } else {
    output$heatmap <- shiny::renderUI({
      shinycssloaders::withSpinner(shiny::plotOutput(session$ns("static")), proxy.height = "800px")
    })

    output$static <- shiny::renderPlot(
      width = shiny::reactive(plot()$width * (plot()$ppi / 2.54)),
      height = shiny::reactive(plot()$height * (plot()$ppi / 2.54)),
      {
        if (clear_plot()) {
          return()
        } else {
          log_message("Heatmap: render plot static", "INFO", token = session$token)

          # new progress indicator
          progress <- shiny::Progress$new()
          on.exit(progress$close())
          progress$set(0.2, message = "Render plot")

          plot <- plot()$plot

          # handle error
          if (methods::is(plot, "try-error")) {
            # TODO add logging
            stop("An error occured! Please try a different dataset.")
          }

          progress$set(1)
          return(ComplexHeatmap::draw(plot, heatmap_legend_side = "bottom"))
        }
    })
  }


  # download #####
  output$download <- shiny::downloadHandler(filename = "heatmap.zip",
                                            content = function(file) {
                                              log_message("Heatmap: download", "INFO", token = session$token)

                                              download(file = file, filename = "heatmap.zip", plot = plot()$plot, width = plot()$width, height = plot()$height, ppi = plot()$ppi, ui = user_input())
                                            })

  user_input <- shiny::reactive({
    # format selection
    selection <- list(type = columns$type(), selectedColumns = columns$selected_columns())

    # format clustering
    clustering <- list(
      clustering = input$clustering,
      distance = input$cluster_distance,
      method = input$cluster_method
    )

    # format options
    options <- list(
      transformation = list(method = transform$method(), applied = transform$transpose()),
      color = list(distribution = input$distribution, scheme = color()$name, reverse = color()$reverse, winsorize = color()$winsorize),
      unit_label = input$label,
      row_label = input$row_label,
      custom_row_label = custom_label()$selected,
      column_label = input$column_label
    )

    # merge all
    list(selection = selection, clustering = clustering, options = options)
  })

  # notifications #####
  # enable/ disable plot button
  # show warning if disabled
  shiny::observe({
    shinyjs::disable("plot")
    show_warning <- TRUE

    # are columns selected?
    if (shiny::isTruthy(columns$selected_columns())) {
      row_num <- nrow(shiny::isolate(object()$data))
      col_num <- length(columns$selected_columns())

      # minimal heatmap possible (greater 1x1)?
      if (row_num > 1 || col_num > 1) {
        # no clustering for single rows or columns
        if (row_num == 1 && !is.element(input$clustering, c("both", "row"))) {
          show_warning <- FALSE
          shinyjs::enable("plot")
        } else if (col_num == 1 && !is.element(input$clustering, c("both", "column"))) {
          show_warning <- FALSE
          shinyjs::enable("plot")
        } else if (row_num > 1 && col_num > 1) { # no border case heatmaps
          show_warning <- FALSE
          shinyjs::enable("plot")
        }
      }

      if (show_warning) {
        shiny::showNotification(
          ui = "Warning! Insufficient columns/ rows. Either disable the respective clustering or expand the dataset.",
          id = session$ns("insuf_data"),
          type = "warning"
        )
      } else {
        shiny::removeNotification(session$ns("insuf_data"))
      }

      # maximum heatmap reached?
      if (plot.method == "static" && row_num > static || plot.method == "interactive" && row_num > interactive) {
        shinyjs::disable("plot")
      }
    }
  })

  # cluster limitation
  shiny::observe({
    shiny::req(object())

    if (shiny::isTruthy(columns$selected_columns())) {
      if (input$clustering != "none") { # clustering
        if (plot.method == "static" && nrow(object()$data) > static) { # cluster limitation (static)
          shiny::showNotification(
            paste("Clustering limited to", static, "genes! Please disable clustering or select less genes."),
            duration = NULL,
            type = "error",
            id = session$ns("notification")
          )
        } else if (plot.method == "interactive" && nrow(object()$data) > interactive) { # cluster limitation (interactive)
          shiny::showNotification(
            paste("Clustering limited to", interactive, "genes! Please disable clustering or select less genes."),
            duration = NULL,
            type = "error",
            id = session$ns("notification")
          )
        } else {
          shiny::removeNotification(session$ns("notification"))
        }
      } else if (nrow(object()$data) > 200) { # computation warning
        shiny::showNotification(
          paste("Caution! You selected", nrow(object()$data), "genes. This will take a while to compute."),
          duration = 5,
          type = "warning",
          id = session$ns("notification")
        )
      } else {
        shiny::removeNotification(session$ns("notification"))
      }
    } else {
      shiny::removeNotification(session$ns("notification"))
    }
  })

  # warning if plot size exceeds limits
  shiny::observe({
    if (plot()$exceed_size) {
      shiny::showNotification(
        ui = "Width and/ or height exceed limit. Using 500 cm instead.",
        id = session$ns("limit"),
        type = "warning"
      )
    } else {
      shiny::removeNotification(session$ns("limit"))
    }
  })

  # Fetch the reactive guide for this module
  guide <- heatmapGuide(session)
  shiny::observeEvent(input$guide, {
    rintrojs::introjs(session, options = list(steps = guide()))
  })

  return(result_data)
}

#' heatmap module guide
#'
#' @param session The shiny session
#'
#' @return A shiny reactive that contains the texts for the Guide steps.
#'
heatmapGuide <- function(session) {
  steps <- list(
    "guide_selection" = "<h4>Data selection</h4>
      Select a column type for visualization, then select individual columns based on the chosen type.",
    "guide_cluster" = "<h4>Row/Column clustering</h4>
      Choose where the clustering is applied, then select a clustering distance and method.",
    "guide_transformation" = "<h4>Data transformation</h4>
      Pick a transformation that you want to apply to your data or leave it as 'None' if no transformation is needed.<br/>
      In case of the Z-score transformation, you can additionally choose to apply it to either rows or columns.",
    "guide_coloring" = "<h4>Color palettes</h4>
      Based on the selected data distribution, available color palettes are either sequential or diverging.<br/>
      The selected palette can additionally be reversed.<br/>
      Set the limits of the color palette with 'Winsorize to upper/lower'. Out of bounds values will be mapped to the nearest color.",
    "guide_options" = "<h4>Additional options</h4>
      You can set a label for the color legend that describes the underlying data unit. Furthermore, you can enable/disable row and column labels.
      Use the input to generate custom row-labels. The selected columns will be merged and used as label.",
    "guide_buttons" = "<h4>Create the plot</h4>
      As a final step click, a click on the 'Plot' button will render the plot, while a click on the 'Reset' button will reset the parameters to default."
  )

  shiny::reactive(data.frame(element = paste0("#", session$ns(names(steps))), intro = unlist(steps)))
}
