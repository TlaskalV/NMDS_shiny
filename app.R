#### hlavicka pro formatovani header a delimiter v uploadu xlsx file ####

library(shiny)
library(readxl)
library(tidyverse)
library(dplyr)
library(vegan)

  ui <- fluidPage(
    sidebarLayout(
      sidebarPanel(
        fileInput('otu', 'Choose OTU table',
                  accept=c('sheetName', 'header'), multiple=FALSE),
        checkboxInput('header_otu', 'Header', TRUE),
        textInput('sheet_otu', 'Exact name of the excel sheet',
                  placeholder = "name of the sheet"),
        downloadButton("downloadData", "Download OTU table"),
        tags$hr(style="border-color: black;"),
        fileInput('samples', 'Choose sample list',
                  accept=c('sheetName', 'header'), multiple=FALSE),
        checkboxInput('header_samples', 'Header', TRUE),
        textInput('sheet_samples', 'Exact name of the excel sheet',
                  placeholder = "name of the sheet"),
        tags$hr(style="border-color: black;"),
        sliderInput("percent_treshold", "Percent treshold per sample", 0.5, 100, c(3), post = "%", step = 0.5),
        numericInput("no_samples", "Number of samples with >= of treshold %", value = 3, min = 1, step = 1),
        h6("Max number of samples:"),
        verbatimTextOutput("sample_range"),
        uiOutput("grouping_factor"),
        downloadButton("downloadMultivar", "Download table ready for NMDS"),
        tags$hr(style="border-color: black;"),
        checkboxInput("hellinger", "Hellinger transformation of OTU table", value = FALSE),
        downloadButton("downloadMultivarFinal", "Download final NMDS points as .csv"),
        tags$br(),
        tags$br(),
        downloadButton("downloadPlotFinal", "Download final plot as .pdf")
      ),
      mainPanel(
        h4(textOutput("caption1")),
        tableOutput("contents1"),
        h4(textOutput("caption2")),
        tableOutput("contents2"),
        tableOutput("contents3"),
        tableOutput("contents4"),
        plotOutput("contents5"),
        tableOutput("contents6")
      )
    )
  )
  
  server <- function(input, output) {
    
    options(shiny.maxRequestSize=30*1024^2)
    
    #otu
    dataset_otu <- reactive({
      infile = input$otu  
      
      if (is.null(infile))
        return(NULL)
      
      readxl::read_excel(infile$datapath, sheet = input$sheet_otu, col_names = input$header_otu)
      
    })
    
    #samples
    dataset_samples <- reactive({
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
    
    #text a tabulka
    output$caption1 <- renderText({
      "first 5 rows of OTU table"
    })
    
    output$contents1 <- renderTable({
      head(dataset_otu(), 5)
    })
    
    #text a tabulka
    output$caption2 <- renderText({
      "first 5 rows of sample table"
    })
    output$contents2 <- renderTable({
      head(dataset_samples(), 5)
    })
    
    #download
    output$downloadData <- downloadHandler(
      filename = function() {
        paste(input$otu, ".csv", sep = "")
      },
      content = function(file) {
        write.csv(dataset_otu(), file, row.names = FALSE, sep = ";")
      })
    
    #filtr procent
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
    
    output$contents3 <- renderTable({
      filtered_titles()
      
    })
    
    #filtr multivar OTUs
    otus_multivar <- reactive({
      filtered_titles_list <- filtered_titles()
      otus_percent <- dataset_otu()
      tbl_df(otus_percent) %>% gather(sample, per, (2:ncol(otus_percent))) %>%
        right_join(filtered_titles_list) %>% 
        spread(sample, per) 
    })
    
    output$contents4 <- renderTable({
      otus_multivar()
    })
    
    #vegan matrix 
    otus_multivar_for_plot <- reactive({
      filtered_titles_list <- filtered_titles()
      otus_multivar <- otus_multivar()
      #cluster <- otus_multivar[,1]
      #rownames(as.data.frame(otus_multivar)) = cluster
      otus_multivar <- t(otus_multivar[ , 2:ncol(otus_multivar)])
    })
     
    #vegan matrix download
    output$downloadMultivar <- downloadHandler(
      filename = function() {
        paste(input$otu, ".csv", sep = "")
      },
      content = function(file) {
        write.csv(otus_multivar_for_plot(), file, row.names = TRUE, sep = ";")
    })
    
    output$contents5 <- renderTable({
      otus_multivar_for_plot()
    })
    
    #NMDS
    mdsord <- reactive({
      otus_multivar_for_plot <- otus_multivar_for_plot()
      set.seed(31)
      mdsord = metaMDS(comm = otus_multivar_for_plot, distance = "bray", trace = FALSE, k = 2, trymax = 200)
      if(input$hellinger) {
      set.seed(31)
      mdsord = metaMDS(comm = decostand(otus_multivar_for_plot, "hellinger"), distance = "bray", trace = FALSE, k = 2, trymax = 200)
      }
      #plot(mdsord, disp = "sites", type = "p")
      NMDS_data <- dataset_samples()
      NMDS_x <- mdsord$points[ ,1]  
      NMDS_y <- mdsord$points[ ,2]
      NMDS_data_final <- cbind(NMDS_data, NMDS_x, NMDS_y)
    })
    
    output$contents6 <- renderTable({
      mdsord()
    })
    
    #NMDS final matrix download
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
    
    #ggplot NMDS
    mdsord_final <- reactive({
      NMDS_data_final <- mdsord()
      ggplot(data = mdsord(), aes(y = NMDS_y, x = NMDS_x)) + 
        geom_point(aes_string(colour = input$grouping_factor_input), show.legend = TRUE, size = 4.5) +
        theme_bw() +
        ggtitle("NMDS plot")
      })
    
    output$contents5 <- renderPlot({
      mdsord_final()
      })
    
    #download NMDS
    output$downloadPlotFinal <- downloadHandler(
      filename = function() { paste(input$otu, '.pdf', sep='') },
      content = function(file) {
        ggsave(file, plot = mdsord_final(), device = "pdf", dpi = 300, height = 210, width = 297, units = "mm")
      }
    )
    
    }
  
  shinyApp(ui, server)
