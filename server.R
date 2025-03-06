library(shiny)
library(DBI)
library(duckdb)
library(dplyr)
library(plotly)
library(lubridate)
library(wordcloud)
library(RColorBrewer)
library(tidyr)

con <- dbConnect(duckdb(), dbdir = ":memory:")
file_path <- "/path/to/311-dataset.parquet"
nyc311_dataset <- tbl(con, paste0("read_parquet('", file_path, "')"))

shinyServer(function(input, output, session) {
  
  # -- Other previous outputs (agencyPlot, hourPlot, submissionPlot, wordcloudPlot, timeSeriesPlot) omitted for brevity --
  # Assume they remain the same as in Version 5
  
  # 1) Borough bar chart
  output$boroughPlot <- renderPlotly({
    data <- nyc311_dataset %>%
      select(borough, complaint_type) %>%
      filter(borough != "") %>%
      collect() %>%
      count(borough, complaint_type)
    
    # We'll keep top complaint types
    top_types <- data %>%
      group_by(complaint_type) %>%
      summarise(total = sum(n)) %>%
      arrange(desc(total)) %>%
      head(5) %>%
      pull(complaint_type)
    
    data_filtered <- data %>%
      mutate(complaint_type = ifelse(complaint_type %in% top_types, complaint_type, "Other")) 
    
    p <- ggplot(data_filtered, aes(x = borough, y = n, fill = complaint_type)) +
      geom_bar(stat = "identity", position = "fill") +
      labs(title = "Complaint Types by Borough", y = "Proportion", x = "Borough") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # 2) Agency resolution times
  output$resolutionPlot <- renderPlotly({
    data <- nyc311_dataset %>%
      select(agency, created_date, closed_date) %>%
      filter(!is.na(closed_date)) %>%
      collect() %>%
      mutate(hours = as.numeric(difftime(closed_date, created_date, units = "hours"))) %>%
      filter(hours >= 0, hours < 720) %>%
      group_by(agency) %>%
      summarise(
        avg_hours = mean(hours, na.rm = TRUE),
        median_hours = median(hours, na.rm = TRUE),
        requests = n()
      ) %>%
      filter(requests > 100) %>%
      arrange(avg_hours)
    
    p <- ggplot(data, aes(x = reorder(agency, -avg_hours), y = avg_hours, fill = requests)) +
      geom_bar(stat = "identity") +
      geom_errorbar(aes(ymin = median_hours, ymax = median_hours), width = 0.5, color = "red") +
      labs(title = "Agency Resolution Time", x = "Agency", y = "Average Hours") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle=45, hjust=1))
    
    ggplotly(p)
  })
  
})
