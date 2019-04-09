#### NMDS plot ####

library(shiny)
library(shinythemes)
library(readxl)
library(openxlsx)
library(tidyverse)
library(dplyr)
library(vegan)
library(tools)
library(shinycssloaders)
library(ggrepel)


#### ui ####
  ui <- fluidPage(
    theme = shinytheme("sandstone"),
    titlePanel("NMDS app"),
    sidebarLayout(
      sidebarPanel(
        h4("1."),
        fileInput('otu', 
                  'Choose OTU table',
                  accept = c('sheetName', 'header'), 
                  multiple = FALSE),
        checkboxInput('header_otu', 
                      'Header',
                      value = TRUE),
        a("example", 
          href = "https://github.com/Vojczech/NMDS_shiny", 
          target="_blank"),
        tags$br(),
        textInput('sheet_otu', 'Exact name of the excel sheet (required)',
                  placeholder = "name of the sheet"),
        downloadButton("downloadData", 
                       "Download OTU table"),
        tags$hr(style = "border-color: black;"),
        h4("2."),
        fileInput('samples', 
                  'Choose sample list',
                  accept = c('sheetName', 'header'), 
                  multiple = FALSE),
        checkboxInput('header_samples', 
                      'Header', 
                      value = TRUE),
        textInput('sheet_samples', 
                  'Exact name of the excel sheet (required)',
                  placeholder = "name of the sheet"),
        tags$hr(style = "border-color: black;"),
        h4("3."),
        sliderInput("percent_treshold", 
                    "Filter OTUs by percentage per sample", 
                    min = 0.5, 
                    max = 100, c(3), 
                    post = "%", 
                    step = 0.5),
        numericInput("no_samples", 
                     "Number of samples with percentage >= upper value", 
                     value = 3, 
                     min = 1, 
                     step = 1),
        helpText("Max number of samples:"),
        textOutput("sample_range"),
        tags$br(),
        tags$hr(style = "border-color: black;"),
        h4("4."),
        uiOutput("grouping_factor"),
        radioButtons("factor_select",
                     "Colours by", 
                     c("Factor" = "Factor", "Numeric" = "Values"), 
                     inline = T,
                     selected = "Factor"),
        checkboxInput("ellipses", 
                      "Display ellipses - grouping by factor only", 
                      value = FALSE),
        checkboxInput("sample_disp", 
                      "Display sample labels", 
                      value = FALSE),
        uiOutput("label_factor"),
        downloadButton("downloadMultivar", 
                       "Table ready for NMDS"),
        tags$hr(style = "border-color: black;"),
        h4("5."),
        checkboxInput("hellinger", 
                      "Hellinger transformation of OTU table", 
                      value = FALSE),
        uiOutput("fitted"),
        tags$br(),
        downloadButton("downloadMultivarFinal", 
                       "Table with NMDS results for external plotting"),
        tags$br(),
        tags$br(),
        downloadButton("downloadPlotFinal", 
                       "Download final plot as PDF"),
        tags$hr(style = "border-color: black;"),
        tags$br(),
        a("Minimal examples of input excel files are available on GitHub", 
          href = "https://github.com/Vojczech/NMDS_shiny", 
          target="_blank")
      ),
      
      mainPanel(
        tabsetPanel(
          tabPanel("NMDS",
                   h5(textOutput("caption1")),
                   tableOutput("contents1") %>% withSpinner(type = getOption("spinner.type", default = 4)),
                   h5(textOutput("caption2")),
                   tableOutput("contents2") %>% withSpinner(type = getOption("spinner.type", default = 4)),
                   plotOutput("contents3") %>% withSpinner(type = getOption("spinner.type", default = 4))
                   ),
          tabPanel("About",
                   h4("Plots for fast insight into community data"),
                   p("Visit", a("this link", href = "https://github.com/Vojczech/NMDS_shiny", target="_blank"), "for brief tutorial."),
                   p("Tested on real data from the paper", a("Tláskal et al., 2017.", href = "https://academic.oup.com/femsec/article-abstract/93/12/fix157/4604780", target = "_blank"), "App is producing same results as metaMDS and envfit functions from the vegan package alone. Bray-Curtis dissimilarity is used. Hellinger transformation of the data is optional."),
                   p("Please note that apps hosted for free on shinyapps.io are limited to 1GB of memory. Therefore loading of larger OTU tables may take a while. If server disconnects after upload try to decrease size of excel file by e.g. deleting of singleton OTUs."),
                   p("packages:", 
                     p(a("tidyverse", href = "https://www.tidyverse.org/", target="_blank")), 
                     p(a("vegan", href = "https://cran.r-project.org/web/packages/vegan/index.html", target="_blank")), 
                     p(a("ggrepel", href = "https://github.com/slowkow/ggrepel", target="_blank")), 
                     p(a("shinycssloaders", href = "https://github.com/andrewsali/shinycssloaders", target="_blank")),
                     p(a("openxlsx", href = "https://github.com/awalker89/openxlsx", target="_blank")))
                   )
          )
        )
      )
  )

  
#### server ####  
  server <- function(input, output) {
    
    options(shiny.maxRequestSize=30*1024^2)
    
    # OTUs
    dataset_otu <- reactive({
      validate(
        need(input$otu != "", "Please select a file and sheet with OTUs")
      )
      infile = input$otu  
      
      if (is.null(infile))
        return(NULL)
      
      readxl::read_excel(infile$datapath, sheet = input$sheet_otu, col_names = input$header_otu)
      
    })
    
    # samples
    dataset_samples <- reactive({
      validate(
        need(input$samples != "", "Please select a file and sheet with samples")
      )
      infile = input$samples  
      
      if (is.null(infile))
        return(NULL)
      
      readxl::read_excel(infile$datapath, sheet = input$sheet_samples, col_names = input$header_samples)
      
    })
    
    # total number of samples
    samples_count <- reactive({
     number = nrow(dataset_samples())
     })
    
    output$sample_range <- renderText({ 
      samples_count() 
      })
    
    # text and table
    output$caption1 <- renderText({
      "first 5 rows of OTU table are displayed"
    })
    
    output$contents1 <- renderTable({
      head(dataset_otu(), 5)
    })
    
    # text and table
    output$caption2 <- renderText({
      "first 5 rows of sample table are displayed"
    })
    output$contents2 <- renderTable({
      head(dataset_samples(), 5)
    })
    
    # download
    output$downloadData <- downloadHandler(
      filename = function() {
        paste("original_table", input$otu, sep = "_")
      },
      content = function(file) {
        write.xlsx(dataset_otu(), file)
      })
    
    # ggplot grouping factor
    ggplot_factor <- reactive({
      factor <- dataset_samples()[,input$grouping_factor_input, drop = FALSE] 
      colnames(factor)<- "ggplot_factor" 
      factor 
    })
    
    # filtr percentage
    filtered_titles <- reactive({
      otus_percent <- dataset_otu()
      tbl_df(otus_percent) %>% gather(sample, per, (2:ncol(otus_percent))) %>% 
        group_by_at(c(1,2)) %>%  
        filter(per >= input$percent_treshold) %>%
        ungroup() %>% 
        group_by_at(c(1)) %>% 
        dplyr::summarise(treshold_count = n()) %>%
        filter(treshold_count >= input$no_samples) %>% 
        select(c(1))
    })
    
    # filtr multivar OTUs
    otus_multivar <- reactive({
      filtered_titles_list <- filtered_titles()
      otus_percent <- dataset_otu()
      tbl_df(otus_percent) %>% gather(sample, per, (2:ncol(otus_percent))) %>%
        right_join(filtered_titles_list) %>% 
        spread(sample, per) 
    })
    
    # vegan matrix 
    otus_multivar_for_plot <- reactive({
      filtered_titles_list <- filtered_titles()
      otus_multivar <- otus_multivar()
      #cluster <- otus_multivar[,1]
      #rownames(as.data.frame(otus_multivar)) = cluster
      otus_multivar <- t(otus_multivar[ , 2:ncol(otus_multivar)])
    })
     
    # vegan matrix download
    output$downloadMultivar <- downloadHandler(
      filename = function() {
        paste("vegan_ready", input$otu, sep = "_")
      },
      content = function(file) {
        write.xlsx(otus_multivar_for_plot(), file)
    })
    
    # NMDS without envfit
    mdsord <- reactive({
      #otus_multivar_for_plot <- otus_multivar_for_plot()
      if(input$hellinger) {
      set.seed(31)
      mdsord = metaMDS(comm = decostand(otus_multivar_for_plot(), "hellinger"), distance = "bray", trace = FALSE, k = 2, trymax = 200)
      } else {
      set.seed(31)
      mdsord = metaMDS(comm = otus_multivar_for_plot(), distance = "bray", trace = FALSE, k = 2, trymax = 200)
      }
      NMDS_data <- dataset_samples()
      ggplot_factor <- as.data.frame(ggplot_factor())
      NMDS_x <- mdsord$points[ ,1]  
      NMDS_y <- mdsord$points[ ,2]
      nmds_stress <- round(mdsord$stress, digits = 3)
      NMDS_data_final <- cbind(NMDS_data, NMDS_x, NMDS_y, ggplot_factor, data.frame(nmds_stress))
    })
    
    # NMDS envfit included, important are same parametres and set.seed
    mdsord_fitted <- reactive({
      if(input$hellinger) {
        set.seed(31)
        mdsord = metaMDS(comm = decostand(otus_multivar_for_plot(), "hellinger"), distance = "bray", trace = FALSE, k = 2, trymax = 200)
      } else {
        set.seed(31)
        mdsord = metaMDS(comm = otus_multivar_for_plot(), distance = "bray", trace = FALSE, k = 2, trymax = 200)
      }
      if(is.null(input$fitted_factors)){
      } else {
      set.seed(31)
      fitted_plot <- envfit(mdsord, fitted_df(), permutations = 999, arrow.mul = 1) 
      envfit_scores <- as.data.frame(scores(fitted_plot, display = "vectors"))
      envfit_scores <- cbind.data.frame(envfit_scores, env.variables = rownames(envfit_scores), stringsAsFactors = FALSE)
      }
    })
    
    # NMDS final points and variables table download
    output$downloadMultivarFinal <- downloadHandler(
      filename = function() {
        paste("final_positions", input$otu, sep = "_")
      },
      content = function(file) {
        l <- list("nmds_points" = mdsord(), "variables_score" = mdsord_fitted())
        write.xlsx(l, file)
      })
    
    output$grouping_factor <- renderUI({
      selectInput("grouping_factor_input", "Grouping factor",
                  colnames(dataset_samples()),
                  selected = NULL)
    })
    
    # label points
    output$label_factor <- renderUI({
      selectInput("label_factor_input", "Label points",
                  colnames(dataset_samples()),
                  selected = NULL)
    })
    
    label_df <- reactive({
      label_variables <- dataset_samples()[,input$label_factor_input, drop = FALSE] 
      label_variables <- unlist(label_variables) # data.frame to atomic vector which is needed for geom_text 
    })
    
    # env variables for envfit
    output$fitted <- renderUI({
      checkboxGroupInput("fitted_factors",
                         "Choose fitted environmental factors",
                         choices = colnames(dataset_samples()),
                         selected = NULL)
      })
    
    fitted_df <- reactive({
      variables <- dataset_samples()[,input$fitted_factors, drop = FALSE] 
      variables 
    })
      
    
    # ggplot NMDS, points are from NMDS without envfit, arrows for env variables are from NMDS with envfit
    mdsord_final <- reactive({
      mdsord <- mdsord()
      mdsord_fitted <- mdsord_fitted()
      stress <- unique(mdsord$nmds_stress) # for stress value of NMDS
      # coloured by factor or value
      if (input$factor_select == "Factor") {
        mdsord$ggplot_factor <- as.factor(mdsord$ggplot_factor)
      } else {
        mdsord$ggplot_factor <- as.numeric(mdsord$ggplot_factor)
      }
      # if env variables are available
      if(is.null(input$fitted_factors)){
      ggplot(data = mdsord, aes(y = NMDS_y, x = NMDS_x)) +
      geom_point(aes(colour = ggplot_factor), show.legend = TRUE, size = 4.5) +
      {if (is.factor(mdsord$ggplot_factor)== TRUE && (input$ellipses)==TRUE) {
        stat_ellipse(aes(colour = ggplot_factor), type = "t")    # add ellipses for factorial grouping
      }} +
      {if (is.factor(mdsord$ggplot_factor)== TRUE) {
        scale_color_viridis_d() # color in the case of discrete values    
      } else {
        scale_color_viridis_c() # color in the case of continuous values
      }} +
      annotate("text", x = (0+max(mdsord$NMDS_x)), y = (0+min(mdsord$NMDS_y)), label = paste("stress\n", stress), size = 3.5) +
          {if(input$sample_disp)
            geom_text_repel(aes(x = NMDS_x, y = NMDS_y, label = label_df(), color = ggplot_factor), size = 2, segment.color = 'grey50', segment.size = 0.2)} + # display sample names
      theme_bw() + 
      ggtitle("NMDS plot")
      } else {
        ggplot(data = mdsord, aes(y = NMDS_y, x = NMDS_x)) +
          geom_point(aes(colour = ggplot_factor), show.legend = TRUE, size = 4.5) +
          {if (is.factor(mdsord$ggplot_factor)== TRUE) {
            scale_color_viridis_d() # color in the case of discrete values    
          } else {
            scale_color_viridis_c() # color in the case of continuous values
          }} +
          annotate("text", x = (0+max(mdsord$NMDS_x)), y = (0+min(mdsord$NMDS_y)), label = paste("stress\n", stress), size = 3.5) +
          {if(input$sample_disp)
            geom_text_repel(aes(x = NMDS_x, y = NMDS_y, label = label_df(), color = ggplot_factor), size = 2, segment.color = 'grey50', segment.size = 0.2)} + # display sample names
          theme_bw() +
          ggtitle("NMDS plot") +
          geom_segment(data = mdsord_fitted(),
                       aes(x = 0, xend = 1.2*NMDS1, y = 0, yend = 1.2*NMDS2),
                       arrow = arrow(length = unit(0.25, "cm")), colour = "#556b2f", size = 0.7) +
          geom_text(data = mdsord_fitted(),
                    aes(x = 1.2*NMDS1, y = 1.2*NMDS2, label = env.variables),
                    size = 6,
                    hjust = -0.3)
        }
      })
    
    output$contents3 <- renderPlot({
      mdsord_final()
      })
    
    # download NMDS
    output$downloadPlotFinal <- downloadHandler(
      filename = function() { 
        paste(tools::file_path_sans_ext(input$otu), '.pdf', sep='') 
        },
      content = function(file) {
        ggsave(file, plot = mdsord_final(), device = "pdf", dpi = 300, height = 210, width = 297, units = "mm")
      }
    )
    
    }
  
  shinyApp(ui, server)
