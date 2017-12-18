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
        uiOutput("no_samples"),
        #numericInput("no_samples", "Number of samples with >= of treshold %", value = 3, min = 1, max = , step = 1),
        h6("Total number of samples"),
        verbatimTextOutput("sample_range"),
        downloadButton("downloadMultivar", "Download table ready for NMDS"),
        tags$hr(style="border-color: black;"),
        checkboxInput("hellinger", "Hellinger transformation of OTU table", value = FALSE)
      ),
      mainPanel(
        h4(textOutput("caption1")),
        tableOutput("contents1"),
        h4(textOutput("caption2")),
        tableOutput("contents2"),
        tableOutput("contents3"),
        tableOutput("contents4"),
        plotOutput("contents6"),
        textOutput("contents8")
      )
    )
  )
  
  server <- function(input, output) {
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
    
    samples_count <- reactive({
     number = nrow(dataset_samples())
      
    })
    
    output$contents8 <- renderText({
      samples_count()
    })
    
    output$no_samples <- renderUI({
      numericInput("inNumeric", "Number of samples with >= of treshold %", min = 1, max = samples_count(), value = 3, step = 1)
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
      plot(mdsord, disp = "sites", type = "p")
      #zof.NMDS.data <- dataset_samples()
      #zof.NMDS.data$NMDS1<-mdsord$points[ ,1]
      #zof.NMDS.data$NMDS2<-mdsord$points[ ,2]
    })
    
    output$contents6 <- renderPlot({
      mdsord()
    })
    
  }
  
  shinyApp(ui, server)
