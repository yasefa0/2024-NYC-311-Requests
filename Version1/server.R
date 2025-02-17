# server.R

# Load Required Libraries
library(shiny)
library(arrow)      # For reading Parquet files
library(dplyr)      # Data manipulation
library(ggplot2)    # Visualization
library(wordcloud)  # For word cloud visualizations
library(scales)     # For formatting numbers with commas

# Load dataset
file_path <- "/Users/yardo/College/WI 2025/BIS 412/NYC311/311-dataset.parquet"
df <- read_parquet(file_path)

# Define server logic
shinyServer(function(input, output) {
  
  output$selectedPlot <- renderPlot({
    
    plot_script <- switch(input$plotType,
                          "agency_barchart" = "agency_barchart.R",
                          "complaint_type_distribution" = "complaint_type_distribution.R",
                          "submission_methods" = "submission_methods.R",
                          "status_distribution" = "status_distribution.R",
                          "borough_distribution" = "borough_distribution.R",
                          "top_complaints_by_agency" = "top_complaints_by_agency.R",
                          "complaint_by_hour" = "complaint_by_hour.R",
                          "time_series_plot" = "time_series_plot.R",
                          "wordcloud_descriptors" = "wordcloud_descriptors.R",
                          "top5_reasons_by_location_type" = "top5_reasons_by_location_type.R",
                          "bridge_highway_visuals" = "bridge_highway_visuals.R")
    
    if (!is.null(plot_script)) {
      source(paste0("/Users/yardo/College/WI 2025/BIS 412/NYC311/", plot_script), local = TRUE)
    }
  })
})
