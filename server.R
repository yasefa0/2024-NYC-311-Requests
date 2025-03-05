library(shiny)
library(DBI)
library(duckdb)
library(dplyr)
library(plotly)
library(lubridate)  # For hour() function

con <- dbConnect(duckdb(), dbdir = ":memory:")
file_path <- "/Users/sakaria/Desktop/BIS 412/DataVis1/NYC 311/311-dataset-POSIXct.parquet"
nyc311_dataset <- tbl(con, paste0("read_parquet('", file_path, "')"))

shinyServer(function(input, output, session) {
  
  # 1) Top 5 agencies
  top_agencies <- reactive({
    nyc311_dataset %>%
      group_by(agency) %>%
      summarise(requests = n()) %>%
      arrange(desc(requests)) %>%
      head(5) %>%
      collect()
  })
  
  output$agencyPlot <- renderPlotly({
    data <- top_agencies()
    plot_ly(data, x = ~agency, y = ~requests, type = "bar") %>%
      layout(title = "Top 5 Agencies")
  })
  
  # 2) Hourly complaints
  hour_counts <- reactive({
    nyc311_dataset %>%
      select(created_date) %>%
      collect() %>%
      mutate(hour_of_day = hour(created_date)) %>%
      group_by(hour_of_day) %>%
      summarise(request_count = n())
  })
  
  output$hourPlot <- renderPlotly({
    data <- hour_counts()
    plot_ly(data, x = ~hour_of_day, y = ~request_count,
            type = "scatter", mode = "lines+markers") %>%
      layout(title = "Complaints by Hour of Day")
  })
  
})
