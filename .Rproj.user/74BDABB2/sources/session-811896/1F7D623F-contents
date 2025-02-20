library(shiny)
library(arrow)
library(DT)

# Increase file upload limit to 100MB
options(shiny.maxRequestSize = 100 * 1024^2)

ui <- fluidPage(
  titlePanel("Upload Large Parquet File"),
  fileInput("file", "Upload a Parquet File", accept = ".parquet"),
  DTOutput("table")
)

server <- function(input, output) {
  data <- reactive({
    req(input$file)
    df <- read_parquet(input$file$datapath)
    return(df)
  })
  
  output$table <- renderDT({
    datatable(data())
  })
}

shinyApp(ui, server)
