# global.R
# This file loads data once for all sessions

# Load Required Libraries
library(shiny)
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(scales)
library(wordcloud)
library(RColorBrewer)
library(tidyr)
library(DBI)
library(arrow)
library(plotly)
library(dbplyr)
library(memoise)
library(DT)
library(ggplot2)
library(shinyjs)

# Function to throttle reactive events
throttle <- function(f, delay) {
  last_called <- 0
  force(f)
  force(delay)
  
  function(...) {
    now <- as.numeric(Sys.time()) * 1000
    if (now - last_called > delay) {
      last_called <<- now
      f(...)
    }
  }
}

# ------- Load pre-computed data ONCE -------
message("Loading pre-computed data...")
precomputed_data <- readRDS("data/nyc311_precomputed_data.rds")

# Extract data frames to global environment
hour_counts              <- precomputed_data$hour_counts
agency_full_names        <- precomputed_data$agency_full_names
agency_counts            <- precomputed_data$agency_counts
submission_methods       <- precomputed_data$submission_methods
complaints_by_month      <- precomputed_data$complaints_by_month
complaints_by_borough    <- precomputed_data$complaints_by_borough
agency_resolution_times  <- precomputed_data$agency_resolution_times
status_counts            <- precomputed_data$status_counts
location_summary         <- precomputed_data$location_summary
location_grouped         <- precomputed_data$location_grouped
borough_geo_data         <- precomputed_data$borough_geo_data
borough_centers          <- precomputed_data$borough_centers
zoom_levels              <- precomputed_data$zoom_levels
wordcloud_descriptors    <- precomputed_data$wordcloud_descriptors

# Optional: Pre-process data to optimize memory usage
# For example, convert to data.table for large dataframes
if (require(data.table)) {
  # Convert large dataframes to data.table for better memory efficiency
  if (nrow(complaints_by_month) > 10000) {
    complaints_by_month <- as.data.table(complaints_by_month)
  }
  
  if (nrow(location_grouped) > 10000) {
    location_grouped <- as.data.table(location_grouped)
  }
}

# Clean up to free memory - remove the large list object after extraction
rm(precomputed_data)
gc()  # Force garbage collection