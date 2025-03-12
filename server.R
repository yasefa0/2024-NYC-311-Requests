# server.R

# Load Required Libraries
library(shiny)
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(scales)
library(wordcloud)
library(RColorBrewer)
library(tidyr)
library(plotly)
library(memoise)
library(DT)
library(ggplot2)
library(shinyjs)

# IMPORTANT: Move this to global.R instead of loading in server.R
# -------------------------------------------------------------
# Don't load precomputed data here - it should be in global.R

# -------------------------------------------------------------------------
# MAIN SHINY SERVER
# -------------------------------------------------------------------------
shinyServer(function(input, output, session) {
  
  # -----------------------------------------------------------------------
  # (A) SESSION MANAGEMENT
  # -----------------------------------------------------------------------
  session$allowReconnect(TRUE)
  
  # Reduce reconnect frequency - 4 minutes is excessive
  observe({
    invalidateLater(1000 * 60 * 10)  # every 10 minutes
    NULL
  })
  
  # -----------------------------------------------------------------------
  # (B) PROGRESSIVE LOADING
  # -----------------------------------------------------------------------
  # Run this once at startup, not reactively
  isolate({
    shinyjs::hide("loading-content")
    shinyjs::show("app-content")
  })
  
  # -----------------------------------------------------------------------
  # (C) REACTIVE FETCHES - Optimized with memoisation
  # -----------------------------------------------------------------------
  # Memoize expensive plot data retrieval
  get_plot_data <- memoise(function(plot_type) {
    # Use plot_type argument instead of input$plotType for better memoisation
    switch(plot_type,
           "agency_barchart"         = agency_counts,
           "complaint_count_by_hour" = hour_counts,
           "submission_methods"      = submission_methods,
           "wordcloud_descriptors"   = wordcloud_descriptors,
           "stacked_time_series"     = complaints_by_month,
           "stacked_borough_bar"     = complaints_by_borough,
           "agency_resolution_time"  = agency_resolution_times,
           "location_pie"            = location_grouped,
           "status_bar"              = status_counts,
           "geo_map"                 = borough_geo_data,
           NULL
    )
  })
  
  # -----------------------------------------------------------------------
  # (D) RENDER PLOTS - Optimized with caching
  # -----------------------------------------------------------------------
  # Cache plot creation for expensive plots
  generate_plot <- memoise(function(plot_type, plot_data) {
    if (is.null(plot_data)) return(NULL)
    
    switch(plot_type,
           "agency_barchart" = {
             plot_ly(
               data = plot_data,
               x = ~reorder(agency_full_name, -requests),
               y = ~requests,
               type = "bar"
             ) %>%
               layout(
                 title = "Top 10 Agencies by Requests",
                 xaxis = list(title = "Agency", tickangle = 45),
                 yaxis = list(title = "Number of Requests"),
                 margin = list(b = 100, l = 100)
               ) %>%
               config(displayModeBar = TRUE)
           },
           "complaint_count_by_hour" = {
             # Use ggplot and then ggplotly
             p <- ggplot(plot_data, aes(x = hour_of_day, y = request_count)) +
               geom_line(size = 1.2) +
               geom_point(size = 2) +
               labs(title = "Complaint Volume by Hour of Day", 
                    x = "Hour of Day (0-23)", 
                    y = "Number of Requests") +
               scale_x_continuous(breaks = 0:23) +
               theme_minimal()
             ggplotly(p)
           },
           "submission_methods" = {
             max_value  <- max(plot_data$request_count)
             breaks_seq <- seq(0, max_value, length.out = 6)
             p <- ggplot(plot_data, aes(
               x = reorder(open_data_channel_type, request_count),
               y = request_count,
               fill = open_data_channel_type
             )) +
               geom_bar(stat = "identity") +
               coord_flip() +
               labs(
                 title = "Complaints by Submission Method", 
                 x = "Submission Method", 
                 y = "Number of Requests"
               ) +
               theme_minimal() +
               theme(legend.position = "none") +
               scale_y_continuous(labels = comma, breaks = breaks_seq)
             ggplotly(p)
           },
           "stacked_time_series" = {
             # Filter top 10 complaint types
             top_complaints <- plot_data %>%
               group_by(complaint_type) %>%
               summarise(total = sum(n)) %>%
               arrange(desc(total)) %>%
               slice_head(n=10) %>%
               pull(complaint_type)
             
             filtered_data <- plot_data %>% 
               filter(complaint_type %in% top_complaints)
             
             p <- ggplot(filtered_data, aes(x = month, y = n, fill = complaint_type)) +
               geom_area(position = "stack") +
               labs(
                 title = "Trend of Top Complaint Types Over Time", 
                 x = "Month", y = "Number of Complaints",
                 fill = "Complaint Type"
               ) +
               theme_minimal() +
               theme(
                 legend.position = "bottom",
                 axis.text.x = element_text(angle = 45, hjust = 1)
               ) +
               scale_x_datetime(date_labels = "%b %Y", date_breaks = "2 month") +
               scale_y_continuous(labels = comma)
             ggplotly(p)
           },
           "stacked_borough_bar" = {
             # Filter top 10 complaint types
             top_complaints <- plot_data %>%
               group_by(complaint_type) %>%
               summarise(total = sum(n)) %>%
               arrange(desc(total)) %>%
               slice_head(n = 10) %>%
               pull(complaint_type)
             
             filtered_data <- plot_data %>%
               mutate(
                 complaint_type = ifelse(
                   complaint_type %in% top_complaints,
                   complaint_type,
                   "Other Complaints"
                 )
               )
             
             p <- ggplot(filtered_data, aes(x = borough, y = n, fill = complaint_type)) +
               geom_bar(stat = "identity", position = "fill") +
               labs(
                 title = "Proportion of Complaint Types by Borough", 
                 x = "Borough", 
                 y = "Proportion of Complaints", 
                 fill = "Complaint Type"
               ) +
               theme_minimal() +
               theme(
                 legend.position = "bottom",
                 axis.text.x = element_text(angle = 45, hjust = 1)
               ) +
               scale_y_continuous(labels = percent_format())
             ggplotly(p)
           },
           "agency_resolution_time" = {
             p <- ggplot(plot_data, aes(
               x = reorder(agency, -avg_resolution_hours),
               y = avg_resolution_hours,
               fill = requests
             )) +
               geom_bar(stat = "identity") +
               geom_errorbar(aes(
                 ymin = median_resolution_hours,
                 ymax = median_resolution_hours
               ),
               width = 0.5, color = "darkred") +
               labs(
                 title = "Average Resolution Time by Agency (Top 15 Fastest)",
                 subtitle = "Red lines indicate median resolution time",
                 x = "Agency", y = "Average Resolution Time (Hours)",
                 fill = "Requests"
               ) +
               theme_minimal() +
               theme(axis.text.x = element_text(angle = 45, hjust = 1))
             ggplotly(p)
           },
           NULL
    )
  })
  
  # Use cached plot data and rendering
  output$selectedPlot <- renderPlotly({
    req(input$plotType)
    
    # If "location_pie", "geo_map", "status_bar" or "wordcloud_descriptors" is requested, skip
    if (input$plotType %in% c("location_pie", "geo_map", "status_bar", "wordcloud_descriptors")) {
      return(NULL)
    }
    
    # Get cached data
    plot_data <- get_plot_data(input$plotType)
    req(plot_data)
    
    # Generate cached plot
    generate_plot(input$plotType, plot_data)
  })
  
  # -----------------------------------------------------------------------
  # (E) WORDCLOUD PLOT - Optimize with caching
  # -----------------------------------------------------------------------
  # Cache the wordcloud data preparation
  prepare_wordcloud_data <- memoise(function() {
    plot_data <- get_plot_data("wordcloud_descriptors")
    if (nrow(plot_data) == 0) return(NULL)
    return(plot_data)
  })
  
  output$wordcloudPlot <- renderPlot({
    req(input$plotType == "wordcloud_descriptors")
    
    # Get cached wordcloud data
    plot_data <- prepare_wordcloud_data()
    req(plot_data)
    
    par(mar = c(0, 0, 0, 0))
    wordcloud(
      words = plot_data$descriptor,
      freq  = plot_data$n,
      min.freq = 2,
      max.words = 250,
      scale = c(5, 0.8),
      random.order = FALSE,
      rot.per = 0.1,
      colors = brewer.pal(8, "Dark2")
    )
  }, height = 1000, width = 1200)
  
  # -----------------------------------------------------------------------
  # (F) STATUS BAR - Optimized with caching
  # -----------------------------------------------------------------------
  # Cache status bar data and colors
  prepare_status_bar <- memoise(function() {
    plot_data <- get_plot_data("status_bar")
    if (nrow(plot_data) == 0) return(NULL)
    
    # A simple color mapping for statuses - moved outside function for efficiency
    status_colors <- c(
      "Assigned"    = "rgba(255, 99, 132, 0.8)",
      "Closed"      = "rgba(54, 162, 235, 0.8)",
      "In Progress" = "rgba(255, 206, 86, 0.8)",
      "Open"        = "rgba(255, 159, 64, 0.8)",
      "Pending"     = "rgba(153, 102, 255, 0.8)",
      "Started"     = "rgba(75, 192, 75, 0.8)",
      "Unspecified" = "rgba(201, 203, 207, 0.8)"
    )
    color_vector <- status_colors[plot_data$status]
    color_vector[is.na(color_vector)] <- "rgba(201, 203, 207, 0.8)"
    
    return(list(data = plot_data, colors = color_vector))
  })
  
  output$statusBar <- renderPlotly({
    req(input$plotType == "status_bar")
    
    # Get cached data and colors
    prepared_data <- prepare_status_bar()
    req(prepared_data)
    
    plot_ly(
      data = prepared_data$data,
      x = ~status,
      y = ~n,
      type = "bar",
      marker = list(color = prepared_data$colors)
    ) %>%
      layout(
        title = "Complaint Status Distribution",
        xaxis = list(title = "Status"),
        yaxis = list(title = "Count", type = "log"),
        bargap = 0.3
      )
  })
  
  # -----------------------------------------------------------------------
  # (G) LOCATION PIE - Optimized with filtering
  # -----------------------------------------------------------------------
  # Cache location pie data preparation
  prepare_location_pie <- memoise(function(location_group) {
    req(location_group)
    location_data <- get_plot_data("location_pie")
    
    location_data %>%
      filter(location_group == location_group) %>%
      arrange(desc(total_requests)) %>%
      head(5)
  })
  
  output$locationPie <- renderPlotly({
    req(input$plotType == "location_pie")
    req(input$location_group)
    
    # Get cached filtered data for this location group
    df <- prepare_location_pie(input$location_group)
    req(df)
    
    plot_ly(
      df,
      labels = ~complaint_type,
      values = ~total_requests,
      type = "pie",
      textinfo = 'label+percent',
      insidetextorientation = 'radial'
    ) %>%
      layout(
        title = paste("Top 5 Complaint Types for", input$location_group, "Locations")
      )
  })
  
  # -----------------------------------------------------------------------
  # (H) GEO MAP - Optimized with pre-defined values
  # -----------------------------------------------------------------------
  # Move constant values outside reactive context
  borough_colors <- list(
    "BRONX"         = "red",
    "MANHATTAN"     = "blue",
    "BROOKLYN"      = "green",
    "QUEENS"        = "purple",
    "STATEN ISLAND" = "orange"
  )
  
  # These should be moved to global.R since they're static
  # For demo purposes, we include them here but they should be moved
  # borough_centers and zoom_levels are already loaded from the precomputed data
  
  # Cache geo map data preparation
  prepare_geo_map_data <- memoise(function(selected_borough) {
    req(selected_borough)
    all_borough_data <- get_plot_data("geo_map")
    return(all_borough_data[[selected_borough]])
  })
  
  selected_point_data <- reactiveVal(NULL)
  
  output$geoMap <- renderPlotly({
    req(input$plotType == "geo_map")
    req(input$selected_borough)
    
    # Get cached map data for this borough
    plot_data <- prepare_geo_map_data(input$selected_borough)
    req(plot_data)
    
    # Register the click event so we don't get the warning
    plot_ly(
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
      event_register("plotly_click") %>% 
      layout(
        mapbox = list(
          style = 'carto-positron',
          zoom  = zoom_levels[[input$selected_borough]],
          center = borough_centers[[input$selected_borough]]
        ),
        title = paste("NYC 311 Complaints in", input$selected_borough),
        clickmode = 'event+select'
      )
  })
  
  # Listen for click events on the map - optimize with throttle/debounce
  # This helps prevent rapid-fire point selection causing performance issues
  map_click_throttled <- throttle(function(click_data) {
    req(click_data, input$selected_borough)
    
    # Get the data for the current borough
    plot_data <- prepare_geo_map_data(input$selected_borough)
    
    # find the closest lat/lon
    distances <- sqrt((plot_data$latitude - click_data$lat)^2 + 
                        (plot_data$longitude - click_data$lon)^2)
    closest_idx <- which.min(distances)
    
    if (length(closest_idx) > 0) {
      point_info <- plot_data[closest_idx, ]
      selected_point_data(point_info)
    }
  }, 300)  # 300ms throttle
  
  observeEvent(event_data("plotly_click", source = "geoMapClick"), {
    map_click_throttled(event_data("plotly_click", source = "geoMapClick"))
  })
  
  # Example: Show the details in a table
  output$pointDetailTable <- DT::renderDataTable({
    req(selected_point_data())
    df <- selected_point_data()
    DT::datatable(df)
  })
  
})  # end shinyServer