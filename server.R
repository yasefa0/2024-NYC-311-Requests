# Minimal server.R
library(shiny)
library(DBI)
library(duckdb)
library(dplyr)
library(plotly)

# Connect to DuckDB
con <- dbConnect(duckdb(), dbdir = ":memory:")
file_path <- "/Users/yardo/College/WI 2025/BIS 412/NYC311/311-dataset-POSIXct.parquet"
nyc311_dataset <- tbl(con, paste0("read_parquet('", file_path, "')"))

shinyServer(function(input, output, session) {
  
  # Reactive: Top 5 agencies by request count
  top_agencies <- reactive({
    nyc311_dataset %>%
      group_by(agency) %>%
      summarise(requests = n()) %>%
      arrange(desc(requests)) %>%
      head(5) %>%
      collect()
  })
  
  # Single bar chart for agencies
  output$agencyPlot <- renderPlotly({
    data <- top_agencies()
    plot_ly(data, x = ~agency, y = ~requests, type = "bar")
  })
  
})
