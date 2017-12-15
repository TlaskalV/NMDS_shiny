#### hlavicka pro formatovani header a delimiter v uploadu xlsx file ####

library(shiny)
library(readxl)
library(tidyverse)

  ui <- fluidPage(
    sidebarLayout(
      sidebarPanel(
        fileInput('otu', 'Choose OTU table',
                  accept=c('sheetName', 'header'), multiple=FALSE),
        checkboxInput('header_otu', 'Header', TRUE),
        textInput('sheet_otu', 'Exact name of the excel sheet',
                  placeholder = "name of the sheet"),
        downloadButton("downloadData", "Download OTU table"),
        tags$hr(),
        tags$hr(),
        fileInput('samples', 'Choose sample list',
                  accept=c('sheetName', 'header'), multiple=FALSE),
        checkboxInput('header_samples', 'Header', TRUE),
        textInput('sheet_samples', 'Exact name of the excel sheet',
                  placeholder = "name of the sheet"),
        tags$hr(),
        tags$hr(),
        sliderInput("percent_treshold", "Percent treshold per sample", 0, 100, c(3), post = "%"),
        numericInput("no_samples", "Number of samples with >= of treshold %", value = 3, min = NA, max = NA, step = 1),
        checkboxInput("hellinger", "Hellinger transformation of OTU table", value = FALSE)
      ),
      mainPanel(
        h4(textOutput("caption1")),
        tableOutput("contents1"),
        h4(textOutput("caption2")),
        tableOutput("contents2")
      )
    )
  )
  
  server <- function(input, output) {
    #otu
    dataset_otu = reactive({
      infile = input$otu  
      
      if (is.null(infile))
        return(NULL)
      
      readxl::read_excel(infile$datapath, sheet = input$sheet_otu, col_names = input$header_otu)
      
    })
    
    #samples
    dataset_samples = reactive({
      infile = input$samples  
      
      if (is.null(infile))
        return(NULL)
      
      readxl::read_excel(infile$datapath, sheet = input$sheet_samples, col_names = input$header_samples)
      
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
      }
    )
  }
  
  shinyApp(ui, server)
