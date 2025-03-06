# server.R
# Load Required Libraries
library(shiny)
library(duckdb)
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(scales)
library(wordcloud)
library(RColorBrewer)
library(tidyr)
library(DBI)
library(plotly)
library(DT)  # For interactive tables

# Connect to DuckDB (global connection)
con <- dbConnect(duckdb(), dbdir = ":memory:")

# Path to your merged Parquet file
file_path <- '/Users/yardo/College/WI 2025/BIS 412/NYC311/311-dataset-POSIXct-complete.parquet'

# Create a lazy table using dbplyr. Filtering can be done on the lazy table.
nyc311_dataset <- tbl(con, paste0("read_parquet('", file_path, "')")) %>%
  filter(created_date < "2025-01-01")  # Remove incomplete January 2025 data

# --- Pre-computations (global objects) ---
hour_counts <- nyc311_dataset %>%
  select(created_date) %>%
  collect() %>% 
  mutate(hour_of_day = hour(created_date)) %>%
  count(hour_of_day, name = "request_count")

agency_full_names <- c(
  "NYPD" = "New York Police Department",
  "HPD" = "Department of Housing Preservation and Development",
  "DSNY" = "Department of Sanitation",
  "DOT" = "Department of Transportation",
  "DEP" = "Department of Environmental Protection",
  "DPR" = "Department of Parks and Recreation",
  "DOB" = "Department of Buildings",
  "DOHMH" = "Department of Health and Mental Hygiene",
  "DHS" = "Department of Homeless Services",
  "TLC" = "Taxi and Limousine Commission"
)

agency_counts <- nyc311_dataset %>%
  group_by(agency) %>%
  summarise(requests = n()) %>%
  collect() %>% 
  arrange(desc(requests)) %>%
  head(10) %>%
  mutate(agency_full_name = agency_full_names[agency])

submission_methods <- nyc311_dataset %>%
  filter(open_data_channel_type != "OTHER") %>%
  group_by(open_data_channel_type) %>%
  summarise(request_count = n()) %>%
  collect()

complaints_by_month <- nyc311_dataset %>%
  select(created_date, complaint_type) %>%
  collect() %>% 
  mutate(month = floor_date(created_date, "month")) %>%
  count(month, complaint_type) %>%
  group_by(complaint_type) %>%
  filter(sum(n) > 1000) %>%
  ungroup()

complaints_by_borough <- nyc311_dataset %>%
  select(borough, complaint_type) %>%
  filter(borough != "") %>%
  collect() %>%
  count(borough, complaint_type) %>%
  group_by(complaint_type) %>%
  filter(sum(n) > 1000) %>%
  ungroup() %>%
  group_by(borough) %>%
  mutate(total = sum(n)) %>%
  filter(n/total > 0.03) %>%
  ungroup()

agency_resolution_times <- nyc311_dataset %>%
  select(agency, created_date, closed_date) %>%
  filter(!is.na(closed_date)) %>%
  collect() %>% 
  mutate(resolution_time_hours = as.numeric(difftime(closed_date, created_date, units = "hours"))) %>%
  filter(resolution_time_hours >= 0, resolution_time_hours < 720) %>%
  group_by(agency) %>%
  summarise(
    avg_resolution_hours = mean(resolution_time_hours, na.rm = TRUE),
    median_resolution_hours = median(resolution_time_hours, na.rm = TRUE),
    requests = n()
  ) %>%
  filter(requests > 100) %>%
  arrange(avg_resolution_hours) %>%
  head(15)

status_counts <- nyc311_dataset %>%
  select(status) %>%
  collect() %>%
  count(status) %>%
  arrange(desc(n))

location_summary <- nyc311_dataset %>%
  select(location_type, complaint_type) %>%
  collect() %>%
  group_by(location_type, complaint_type) %>%
  summarise(request_count = n(), .groups = "drop")

get_location_group <- function(location_type) {
  if (grepl("Family|Apartment|Residential|House", location_type, ignore.case = TRUE)) {
    return("Residential")
  } else if (grepl("Highway", location_type, ignore.case = TRUE)) {
    return("Highway")
  } else if (grepl("Subway", location_type, ignore.case = TRUE)) {
    return("Subway")
  } else if (grepl("Commercial|Business|Store|Office", location_type, ignore.case = TRUE)) {
    return("Commercial")
  } else if (grepl("Park|Public|Sidewalk|Alley|Lot|Vacant", location_type, ignore.case = TRUE)) {
    return("Public")
  } else {
    return("Other")
  }
}

location_summary <- location_summary %>%
  mutate(location_group = sapply(location_type, get_location_group))

location_grouped <- location_summary %>%
  group_by(location_group, complaint_type) %>%
  summarise(total_requests = sum(request_count), .groups = "drop")

borough_geo_data <- list()
for (b in c("BRONX", "MANHATTAN", "BROOKLYN", "QUEENS", "STATEN ISLAND")) {
  borough_df <- nyc311_dataset %>% 
    filter(toupper(borough) == b) %>% 
    collect()
  
  if (nrow(borough_df) > 0) {
    borough_geo_data[[b]] <- borough_df %>%
      group_by(latitude, longitude) %>%
      summarise(
        complaint_types = paste(unique(complaint_type), collapse = ", "),
        unique_keys = paste(unique(unique_key), collapse = ", "),
        complaint_count = n(),
        first_unique_key = first(unique_key),
        .groups = "drop"
      )
  } else {
    borough_geo_data[[b]] <- data.frame(
      latitude = numeric(0),
      longitude = numeric(0),
      complaint_types = character(0),
      unique_keys = character(0),
      complaint_count = integer(0),
      first_unique_key = character(0)
    )
  }
}

shinyServer(function(input, output, session) {
  session$onFlushed(function() {
    session$sendCustomMessage(type = "register-event", 
                              message = list(source = "geoMapClick", event = "plotly_click"))
  })
  
  observeEvent(input$plotType, {
    if (input$plotType == "about") {
      return(NULL)
    }
  }, priority = 10)
  
  get_plot_data <- reactive({
    switch(input$plotType,
           "agency_barchart" = agency_counts,
           "complaint_count_by_hour" = hour_counts,
           "submission_methods" = submission_methods,
           "wordcloud_descriptors" = {
             nyc311_dataset %>%
               select(descriptor) %>%
               head(100000) %>%
               collect() %>%
               mutate(descriptor = ifelse(is.na(descriptor), "", descriptor)) %>%
               count(descriptor) %>%
               filter(n > 50) %>%
               arrange(desc(n))
           },
           "stacked_time_series" = complaints_by_month,
           "stacked_borough_bar" = complaints_by_borough,
           "agency_resolution_time" = agency_resolution_times,
           "location_pie" = NULL,
           NULL
    )
  }) %>% bindCache(input$plotType)
  
  output$selectedPlot <- renderPlotly({
    req(input$plotType)
    if (input$plotType == "location_pie") return(NULL)
    plot_data <- get_plot_data()
    
    switch(input$plotType,
           "agency_barchart" = {
             plot_ly(data = plot_data, 
                     x = ~reorder(agency_full_name, -requests), 
                     y = ~requests, 
                     type = "bar",
                     marker = list(color = '#1f77b4')) %>%
               layout(title = "Top 10 Agencies by Requests",
                      xaxis = list(title = "Agency", tickangle = 45),
                      yaxis = list(title = "Number of Requests"),
                      margin = list(b = 100, l = 100)) %>%
               config(displayModeBar = TRUE)
           },
           "complaint_count_by_hour" = {
             ggplot(plot_data, aes(x = hour_of_day, y = request_count)) +
               geom_line(color = "blue", size = 1.2) +
               geom_point(color = "red", size = 2) +
               labs(title = "Complaint Volume by Hour of Day", 
                    x = "Hour of Day (0-23)", y = "Number of Requests") +
               scale_x_continuous(breaks = 0:23) +
               theme_minimal()
           },
           "submission_methods" = {
             max_value <- max(plot_data$request_count)
             breaks_seq <- seq(0, max_value, length.out = 6)
             ggplot(plot_data, aes(x = reorder(open_data_channel_type, request_count), 
                                   y = request_count, fill = open_data_channel_type)) +
               geom_bar(stat = "identity") +
               coord_flip() +
               labs(title = "Complaints by Submission Method", 
                    x = "Submission Method", y = "Number of Requests") +
               theme_minimal() +
               theme(legend.position = "none") +
               scale_y_continuous(labels = comma, breaks = breaks_seq)
           },
           "stacked_time_series" = {
             top_complaints <- plot_data %>%
               group_by(complaint_type) %>%
               summarise(total = sum(n)) %>%
               arrange(desc(total)) %>%
               head(10) %>%
               pull(complaint_type)
             filtered_data <- plot_data %>% filter(complaint_type %in% top_complaints)
             ggplot(filtered_data, aes(x = month, y = n, fill = complaint_type)) +
               geom_area(position = "stack") +
               labs(title = "Trend of Top Complaint Types Over Time", 
                    x = "Month", y = "Number of Complaints", fill = "Complaint Type") +
               theme_minimal() +
               theme(legend.position = "bottom",
                     legend.title = element_text(size = 10),
                     legend.text = element_text(size = 8),
                     axis.text.x = element_text(angle = 45, hjust = 1)) +
               scale_x_datetime(date_labels = "%b %Y", date_breaks = "2 month") +
               scale_y_continuous(labels = comma)
           },
           "stacked_borough_bar" = {
             top_complaints <- plot_data %>%
               group_by(complaint_type) %>%
               summarise(total = sum(n)) %>%
               arrange(desc(total)) %>%
               head(10) %>%
               pull(complaint_type)
             filtered_data <- plot_data %>%
               mutate(complaint_type = ifelse(complaint_type %in% top_complaints, 
                                              complaint_type, "Other Complaints"))
             ggplot(filtered_data, aes(x = borough, y = n, fill = complaint_type)) +
               geom_bar(stat = "identity", position = "fill") +
               labs(title = "Proportion of Complaint Types by Borough", 
                    x = "Borough", y = "Proportion of Complaints", fill = "Complaint Type") +
               theme_minimal() +
               theme(legend.position = "bottom",
                     legend.title = element_text(size = 10),
                     legend.text = element_text(size = 8),
                     axis.text.x = element_text(angle = 45, hjust = 1)) +
               scale_y_continuous(labels = percent_format())
           },
           "agency_resolution_time" = {
             ggplot(plot_data, aes(x = reorder(agency, -avg_resolution_hours), 
                                   y = avg_resolution_hours, fill = requests)) +
               geom_bar(stat = "identity") +
               geom_errorbar(aes(ymin = median_resolution_hours, ymax = median_resolution_hours), 
                             width = 0.5, color = "darkred") +
               labs(title = "Average Resolution Time by Agency (Top 15 Fastest)",
                    subtitle = "Red lines indicate median resolution time",
                    x = "Agency", y = "Average Resolution Time (Hours)",
                    fill = "Number of\nRequests") +
               theme_minimal() +
               theme(axis.text.x = element_text(angle = 45, hjust = 1),
                     legend.position = "right") +
               scale_fill_gradient(low = "lightblue", high = "darkblue")
           },
           NULL
    )
  })
  
  selected_point_data <- reactiveVal(NULL)
  
  output$geoMap <- renderPlotly({
    req(input$plotType == "geo_map")
    req(input$selected_borough)
    
    borough_colors <- c(
      "BRONX" = "red",
      "MANHATTAN" = "blue",
      "BROOKLYN" = "green",
      "QUEENS" = "purple",
      "STATEN ISLAND" = "orange"
    )
    
    plot_data <- borough_geo_data[[input$selected_borough]]
    
    borough_centers <- list(
      "BRONX" = list(lat = 40.8448, lon = -73.8648),
      "MANHATTAN" = list(lat = 40.7831, lon = -73.9712),
      "BROOKLYN" = list(lat = 40.6782, lon = -73.9442),
      "QUEENS" = list(lat = 40.7282, lon = -73.7949),
      "STATEN ISLAND" = list(lat = 40.5795, lon = -74.1502)
    )
    
    zoom_levels <- list(
      "BRONX" = 11,
      "MANHATTAN" = 12,
      "BROOKLYN" = 11,
      "QUEENS" = 10,
      "STATEN ISLAND" = 11
    )
    
    p <- plot_ly(
      data = plot_data,
      lat = ~latitude,
      lon = ~longitude,
      type = 'scattermapbox',
      mode = 'markers',
      marker = list(
        size = ~pmin(10, 3 + 0.5 * complaint_count),
        color = borough_colors[[input$selected_borough]],
        opacity = 0.7
      ),
      text = ~paste0("Complaints: ", complaint_count, "<br>",
                     "Types: ", complaint_types),
      hoverinfo = 'text',
      source = "geoMapClick"
    ) %>%
      layout(
        mapbox = list(
          style = 'carto-positron',
          zoom = zoom_levels[[input$selected_borough]],
          center = borough_centers[[input$selected_borough]]
        ),
        title = paste("NYC 311 Complaints in", input$selected_borough),
        clickmode = 'event+select'
      )
    
    return(p)
  })
  
  observeEvent(event_data("plotly_click", source = "geoMapClick"), {
    click_data <- event_data("plotly_click", source = "geoMapClick")
    req(click_data)
    req(input$selected_borough)
    
    plot_data <- borough_geo_data[[input$selected_borough]]
    distances <- sqrt((plot_data$latitude - click_data$lat)^2 + (plot_data$longitude - click_data$lon)^2)
    closest_idx <- which.min(distances)
    
    if (length(closest_idx) > 0) {
      point_info <- plot_data[closest_idx, ]
      detail_data <- nyc311_dataset %>%
        filter(
          latitude == point_info$latitude,
          longitude == point_info$longitude
        ) %>%
        select(
          unique_key,
          created_date,
          closed_date,
          agency,
          complaint_type,
          descriptor,
          location_type,
          status
        ) %>%
        collect()
      
      if (nrow(detail_data) > 0) {
        detail_data <- detail_data %>%
          mutate(
            created_date = format(created_date, "%Y-%m-%d %H:%M"),
            closed_date = format(closed_date, "%Y-%m-%d %H:%M")
          ) %>%
          head(25)
        selected_point_data(detail_data)
      } else {
        selected_point_data(data.frame(Message = "No detailed information available for this point"))
      }
    }
  })
  
  output$locationPie <- renderPlotly({
    req(input$plotType)
    if (input$plotType != "location_pie") return(NULL)
    req(input$location_group)
    df <- location_grouped %>%
      filter(location_group == input$location_group) %>%
      arrange(desc(total_requests)) %>%
      head(5)
    plot_ly(df, labels = ~complaint_type, values = ~total_requests, type = 'pie',
            textinfo = 'label+percent', insidetextorientation = 'radial') %>%
      layout(title = paste("Top 5 Complaint Types for", input$location_group, "Locations"),
             showlegend = TRUE)
  })
  
  output$wordcloudPlot <- renderPlot({
    req(input$plotType == "wordcloud_descriptors")
    plot_data <- nyc311_dataset %>%
      select(descriptor) %>%
      collect() %>%
      filter(!is.na(descriptor) & descriptor != "") %>%
      count(descriptor) %>%
      filter(n > 50) %>%
      arrange(desc(n))
    
    req(nrow(plot_data) > 0)
    par(mar = c(0, 0, 0, 0))
    wordcloud(
      words = plot_data$descriptor,
      freq = plot_data$n,
      min.freq = 2,
      max.words = 250,
      scale = c(5, 0.8),
      random.order = FALSE,
      rot.per = 0.1,
      colors = brewer.pal(8, "Dark2")
    )
  }, height = 1000, width = 1200)
  
  output$statusBar <- renderPlotly({
    req(input$plotType == "status_bar")
    plot_data <- nyc311_dataset %>%
      select(status) %>%
      collect() %>%
      count(status) %>%
      arrange(desc(n))
    
    status_colors <- c(
      "Assigned" = "rgba(255, 99, 132, 0.8)",
      "Closed" = "rgba(54, 162, 235, 0.8)",
      "In Progress" = "rgba(255, 206, 86, 0.8)",
      "Open" = "rgba(255, 159, 64, 0.8)",
      "Pending" = "rgba(153, 102, 255, 0.8)",
      "Started" = "rgba(75, 192, 75, 0.8)",
      "Unspecified" = "rgba(201, 203, 207, 0.8)"
    )
    
    plot_ly(
      data = plot_data, 
      x = ~status, 
      y = ~n, 
      type = "bar", 
      marker = list(color = unname(status_colors[plot_data$status]))
    ) %>%
      layout(
        title = "Complaint Status Distribution",
        xaxis = list(title = "Status", tickangle = 0),
        yaxis = list(title = "Count", type = "log"),
        bargap = 0.3
      )
  })
})
