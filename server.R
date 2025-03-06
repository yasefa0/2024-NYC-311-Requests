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

# Function to group location types
get_location_group <- function(location_type) {
  if (grepl("Family|Apartment|Residential|House", location_type, ignore.case = TRUE)) {
    return("Residential")
  } else if (grepl("Commercial|Business|Store|Office", location_type, ignore.case = TRUE)) {
    return("Commercial")
  } else if (grepl("Park|Sidewalk|Vacant|Lot", location_type, ignore.case = TRUE)) {
    return("Public")
  } else if (grepl("Highway", location_type, ignore.case = TRUE)) {
    return("Highway")
  } else if (grepl("Subway", location_type, ignore.case = TRUE)) {
    return("Subway")
  }
  return("Other")
}

shinyServer(function(input, output, session) {
  
  # -- Existing plots from previous versions not repeated here for brevity --
  
  # Location type analysis (pie chart)
  output$locationPie <- renderPlotly({
    req(input$locChoice)
    data <- nyc311_dataset %>%
      select(location_type, complaint_type) %>%
      collect() %>%
      mutate(location_group = sapply(location_type, get_location_group)) %>%
      group_by(location_group, complaint_type) %>%
      summarise(count = n(), .groups="drop") %>%
      filter(location_group == input$locChoice) %>%
      arrange(desc(count)) %>%
      head(5)
    
    plot_ly(data, labels = ~complaint_type, values = ~count, type = "pie",
            textinfo = "label+percent") %>%
      layout(title = paste("Top 5 Complaints -", input$locChoice))
  })
  
})
