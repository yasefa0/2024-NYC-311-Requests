library(shiny)
library(DBI)
library(duckdb)
library(dplyr)
library(plotly)
library(lubridate)

con <- dbConnect(duckdb(), dbdir = ":memory:")
file_path <- "C:/Users/muhmi/Github re/311 Data/311-dataset-POSIXct.parquet"
nyc311_dataset <- tbl(con, paste0("read_parquet('", file_path, "')"))

shinyServer(function(input, output, session) {
  
  # Top 5 agencies
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
    plot_ly(data, x = ~agency, y = ~requests, type = "bar")
  })
  
  # Hourly complaints
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
            type = "scatter", mode = "lines+markers")
  })
  
  # Submission methods
  submission_methods <- reactive({
    nyc311_dataset %>%
      filter(open_data_channel_type != "OTHER") %>%
      group_by(open_data_channel_type) %>%
      summarise(request_count = n()) %>%
      arrange(desc(request_count)) %>%
      collect()
  })
  output$submissionPlot <- renderPlotly({
    data <- submission_methods()
    plot_ly(data, x = ~open_data_channel_type, y = ~request_count, 
            type = "bar") %>%
      layout(title = "Submission Methods")
  })
  
})