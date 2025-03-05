library(shiny)
library(DBI)
library(duckdb)
library(dplyr)
library(plotly)
library(lubridate)
library(wordcloud)
library(RColorBrewer)

con <- dbConnect(duckdb(), dbdir = ":memory:")
file_path <- "/path/to/311-dataset.parquet"
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
    plot_ly(top_agencies(), x = ~agency, y = ~requests, type = "bar")
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
    plot_ly(hour_counts(), x = ~hour_of_day, y = ~request_count, 
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
    plot_ly(submission_methods(), x = ~open_data_channel_type, 
            y = ~request_count, type = "bar")
  })
  
  # Word cloud
  output$wordcloudPlot <- renderPlot({
    plot_data <- nyc311_dataset %>%
      select(descriptor) %>%
      collect() %>%
      filter(!is.na(descriptor) & descriptor != "") %>%
      count(descriptor) %>%
      filter(n > 50) %>%
      arrange(desc(n))
    
    wordcloud(
      words = plot_data$descriptor,
      freq = plot_data$n,
      min.freq = 2,
      max.words = 200,
      colors = brewer.pal(8, "Dark2"),
      scale = c(4, 0.8)
    )
  })
  
})
