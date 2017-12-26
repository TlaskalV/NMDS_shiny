#### NMDS plot ####

library(shiny)
library(readxl)
library(tidyverse)
library(dplyr)
library(vegan)
library(shinycssloaders)


#### ui ####
  ui <- fluidPage(
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
        tags$br(),
        uiOutput("grouping_factor"),
        radioButtons("factor_select",
                     "Colours by", 
                     c("Factor" = "Factor", "Numeric" = "Values"), 
                     inline = T,
                     selected = "Factor"), 
        downloadButton("downloadMultivar", 
                       "Download table ready for NMDS"),
        tags$hr(style = "border-color: black;"),
        h4("4."),
        checkboxInput("hellinger", 
                      "Hellinger transformation of OTU table", 
                      value = FALSE),
        downloadButton("downloadMultivarFinal", 
                       "Download final NMDS points as .csv"),
        tags$br(),
        tags$br(),
        downloadButton("downloadPlotFinal", 
                       "Download final plot as .pdf"),
        tags$hr(style = "border-color: black;"),
        tags$br(),
        a("Minimal examples of input excel files are available here", 
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
                   p("Created in 2017."),
                   p("packages:", a("tidyverse", href = "https://www.tidyverse.org/", target="_blank"), a("vegan", href = "https://cran.r-project.org/web/packages/vegan/index.html", target="_blank"), a("shinycssloaders", href = "https://github.com/andrewsali/shinycssloaders", target="_blank"))
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
        paste(input$otu, ".csv", sep = "")
      },
      content = function(file) {
        write.csv(dataset_otu(), file, row.names = FALSE, sep = ";")
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
        paste(input$otu, ".csv", sep = "")
      },
      content = function(file) {
        write.csv(otus_multivar_for_plot(), file, row.names = TRUE, sep = ";")
    })
    
    # NMDS
    mdsord <- reactive({
      #otus_multivar_for_plot <- otus_multivar_for_plot()
      if(input$hellinger) {
      set.seed(31)
      mdsord = metaMDS(comm = decostand(otus_multivar_for_plot(), "hellinger"), distance = "bray", trace = FALSE, k = 2, trymax = 200)
      } else {
      set.seed(31)
      mdsord = metaMDS(comm = otus_multivar_for_plot(), distance = "bray", trace = FALSE, k = 2, trymax = 200)
      }
      #plot(mdsord, disp = "sites", type = "p")
      NMDS_data <- dataset_samples()
      ggplot_factor <- as.data.frame(ggplot_factor())
      NMDS_x <- mdsord$points[ ,1]  
      NMDS_y <- mdsord$points[ ,2]
      NMDS_data_final <- cbind(NMDS_data, NMDS_x, NMDS_y, ggplot_factor)
    })
    
    # NMDS final matrix download
    output$downloadMultivarFinal <- downloadHandler(
      filename = function() {
        paste(input$otu, ".csv", sep = "")
      },
      content = function(file) {
        write.csv(mdsord(), file, row.names = TRUE, sep = ";")
      })
    
    output$grouping_factor <- renderUI({
      selectInput("grouping_factor_input", "Grouping factor",
                  sort(colnames(dataset_samples())),
                  selected = NULL)
    })
    
    # ggplot NMDS
    mdsord_final <- reactive({
      mdsord <- mdsord()
      if (input$factor_select == "Factor") {
        mdsord$ggplot_factor <- as.factor(mdsord$ggplot_factor)
      } else {
        mdsord$ggplot_factor <- as.numeric(mdsord$ggplot_factor)
      }
      ggplot(data = mdsord, aes(y = NMDS_y, x = NMDS_x)) + 
        geom_point(aes(colour = ggplot_factor), show.legend = TRUE, size = 4.5) +
        theme_bw() +
        ggtitle("NMDS plot")
      })
    
    output$contents3 <- renderPlot({
      mdsord_final()
      })
    
    # download NMDS
    output$downloadPlotFinal <- downloadHandler(
      filename = function() { paste(input$otu, '.pdf', sep='') },
      content = function(file) {
        ggsave(file, plot = mdsord_final(), device = "pdf", dpi = 300, height = 210, width = 297, units = "mm")
      }
    )
    
    }
  
  shinyApp(ui, server)
