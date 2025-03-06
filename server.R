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
  output$agencyPlot <- renderPlotly({
    data <- nyc311_dataset %>%
      group_by(agency) %>%
      summarise(requests = n()) %>%
      arrange(desc(requests)) %>%
      head(5) %>%
      collect()
    plot_ly(data, x = ~agency, y = ~requests, type = "bar")
  })
  
  # Hourly complaints
  output$hourPlot <- renderPlotly({
    data <- nyc311_dataset %>%
      select(created_date) %>%
      collect() %>%
      mutate(hour_of_day = hour(created_date)) %>%
      group_by(hour_of_day) %>%
      summarise(request_count = n())
    plot_ly(data, x = ~hour_of_day, y = ~request_count, 
            type = "scatter", mode = "lines+markers")
  })
  
  # Submission methods
  output$submissionPlot <- renderPlotly({
    data <- nyc311_dataset %>%
      filter(open_data_channel_type != "OTHER") %>%
      group_by(open_data_channel_type) %>%
      summarise(request_count = n()) %>%
      arrange(desc(request_count)) %>%
      collect()
    plot_ly(data, x = ~open_data_channel_type, 
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
      scale = c(4, 0.8),
      colors = brewer.pal(8, "Dark2")
    )
  })
  
  # Stacked time series of complaints
  output$timeSeriesPlot <- renderPlotly({
    data <- nyc311_dataset %>%
      select(created_date, complaint_type) %>%
      collect() %>%
      mutate(month = floor_date(created_date, "month")) %>%
      group_by(month, complaint_type) %>%
      summarise(n = n(), .groups="drop")
    
    # Filter to top complaint types overall
    top_types <- data %>%
      group_by(complaint_type) %>%
      summarise(total = sum(n)) %>%
      arrange(desc(total)) %>%
      head(5) %>%
      pull(complaint_type)
    
    data_filtered <- data %>%
      filter(complaint_type %in% top_types)
    
    # We'll use ggplot style in Plotly:
    # Convert to a stacked area
    # Note: We can do either ggplotly or direct plot_ly; we'll do ggplotly for speed
    p <- ggplot(data_filtered, aes(x = month, y = n, fill = complaint_type)) +
      geom_area(position = "stack") +
      labs(title = "Complaint Types Over Time", x = "Month", y = "Count") +
      theme_minimal()
    
    ggplotly(p)
  })
  
})
