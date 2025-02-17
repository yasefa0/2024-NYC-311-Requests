library(shiny)
library(leaflet)
library(leaflet.extras)  # for heatmap support
library(ggplot2)
library(dplyr)
library(DT)
library(shinydashboard)
library(arrow)
library(lubridate)

# Define UI with one tab per visualization
ui <- dashboardPage(
  dashboardHeader(title = "311 Requests Analysis"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Volume of Requests Over Time", tabName = "vol_requests", icon = icon("chart-line")),
      menuItem("Avg Response Time by Complaint Type", tabName = "avg_response", icon = icon("clock")),
      menuItem("Top 10 Most Common Complaints", tabName = "top_complaints", icon = icon("list")),
      menuItem("Complaint Status Breakdown", tabName = "status_breakdown", icon = icon("chart-pie")),
      menuItem("Complaints by Borough", tabName = "complaints_borough", icon = icon("building")),
      menuItem("311 Requests Map", tabName = "requests_map", icon = icon("map")),
      menuItem("Most Common Resolutions", tabName = "common_resolutions", icon = icon("check")),
      menuItem("Complaint Type vs Borough", tabName = "complaint_type_borough", icon = icon("th")),
      menuItem("Requests by Submission Channel", tabName = "submission_channel", icon = icon("mobile-alt")),
      menuItem("Complaints by Facility Type", tabName = "facility_type", icon = icon("warehouse")),
      menuItem("Requests by Community Board", tabName = "community_board", icon = icon("city")),
      menuItem("Spatial Density (Heatmap)", tabName = "spatial_density", icon = icon("fire")),
      menuItem("Open vs Closed Requests Over Time", tabName = "open_closed", icon = icon("exchange-alt")),
      menuItem("Resolution Action Updates Over Time", tabName = "resolution_updates", icon = icon("history"))
    )
  ),
  dashboardBody(
    tabItems(
      # 1. Volume of Requests Over Time
      tabItem(tabName = "vol_requests",
              fluidRow(
                box(width = 24,
                    selectInput("granularity", "Select Time Granularity", 
                                choices = c("Daily", "Weekly", "Monthly")),
                    plotOutput("volume_time_plot")
                )
              )
      ),
      # 2. Average Response Time by Complaint Type
      tabItem(tabName = "avg_response",
              fluidRow(
                box(width = 24,
                    plotOutput("avg_response_plot")
                )
              )
      ),
      # 3. Top 10 Most Common Complaints
      tabItem(tabName = "top_complaints",
              fluidRow(
                box(width = 24,
                    plotOutput("top_complaints_plot")
                )
              )
      ),
      # 4. Complaint Status Breakdown
      tabItem(tabName = "status_breakdown",
              fluidRow(
                box(width = 24,
                    plotOutput("status_breakdown_plot")
                )
              )
      ),
      # 5. Complaints by Borough
      tabItem(tabName = "complaints_borough",
              fluidRow(
                box(width = 24,
                    plotOutput("complaints_borough_plot")
                )
              )
      ),
      # 6. 311 Requests Map
      tabItem(tabName = "requests_map",
              fluidRow(
                box(width = 24,
                    leafletOutput("requests_map")
                )
              )
      ),
      # 7. Most Common Resolutions
      tabItem(tabName = "common_resolutions",
              fluidRow(
                box(width = 24,
                    plotOutput("common_resolutions_plot")
                )
              )
      ),
      # 8. Correlation Between Complaint Type and Borough
      tabItem(tabName = "complaint_type_borough",
              fluidRow(
                box(width = 24,
                    plotOutput("complaint_type_borough_plot")
                )
              )
      ),
      # 9. Requests by Submission Channel
      tabItem(tabName = "submission_channel",
              fluidRow(
                box(width = 24,
                    plotOutput("submission_channel_plot")
                )
              )
      ),
      # 10. Complaints by Facility Type
      tabItem(tabName = "facility_type",
              fluidRow(
                box(width = 24,
                    plotOutput("facility_type_plot")
                )
              )
      ),
      # 11. Requests by Community Board
      tabItem(tabName = "community_board",
              fluidRow(
                box(width = 24,
                    plotOutput("community_board_plot")
                )
              )
      ),
      # 12. Spatial Density of Complaints (Heatmap)
      tabItem(tabName = "spatial_density",
              fluidRow(
                box(width = 24,
                    leafletOutput("spatial_density_map")
                )
              )
      ),
      # 13. Comparison of Open vs Closed Requests Over Time
      tabItem(tabName = "open_closed",
              fluidRow(
                box(width = 24,
                    plotOutput("open_closed_plot")
                )
              )
      ),
      # 14. Resolution Action Updates Over Time
      tabItem(tabName = "resolution_updates",
              fluidRow(
                box(width = 24,
                    plotOutput("resolution_updates_plot")
                )
              )
      )
    )
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  ### 1. Volume of Requests Over Time ###
  output$volume_time_plot <- renderPlot({
    # Ensure created_date is in Date format
    time_data$created_date <- as.Date(time_data$created_date)
    
    # Aggregate based on chosen granularity
    if (input$granularity == "Daily") {
      agg_data <- time_data %>%
        group_by(date = created_date) %>%
        summarise(requests = n())
      xvar <- agg_data$date
    } else if (input$granularity == "Weekly") {
      agg_data <- time_data %>%
        mutate(week = floor_date(created_date, "week")) %>%
        group_by(week) %>%
        summarise(requests = n())
      xvar <- agg_data$week
    } else if (input$granularity == "Monthly") {
      agg_data <- time_data %>%
        mutate(month = floor_date(created_date, "month")) %>%
        group_by(month) %>%
        summarise(requests = n())
      xvar <- agg_data$month
    }
    
    ggplot(agg_data, aes(x = xvar, y = requests)) +
      geom_line(color = "blue") +
      geom_point(color = "blue") +
      labs(title = "Volume of Requests Over Time",
           x = input$granularity, y = "Number of Requests") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  
  ### 2. Average Response Time by Complaint Type ###
  output$avg_response_plot <- renderPlot({
    # Convert dates if necessary
    complaints_data$created_date <- as.Date(complaints_data$created_date)
    complaints_data$closed_date <- as.Date(complaints_data$closed_date)
    
    # Compute response time (in days)
    complaints_data <- complaints_data %>%
      mutate(response_time = as.numeric(closed_date - created_date))
    
    avg_response <- complaints_data %>%
      group_by(complaint_type) %>%
      summarise(avg_response = mean(response_time, na.rm = TRUE)) %>%
      arrange(avg_response)
    
    ggplot(avg_response, aes(x = reorder(complaint_type, avg_response), y = avg_response)) +
      geom_bar(stat = "identity", fill = "orange") +
      coord_flip() +
      labs(title = "Average Response Time by Complaint Type",
           x = "Complaint Type", y = "Average Response Time (days)") +
      theme_minimal()
  })
  
  
  ### 3. Top 10 Most Common Complaints ###
  output$top_complaints_plot <- renderPlot({
    top_complaints <- complaints_data %>%
      count(complaint_type, sort = TRUE) %>%
      top_n(10, n)
    
    ggplot(top_complaints, aes(x = reorder(complaint_type, n), y = n)) +
      geom_bar(stat = "identity", fill = "purple") +
      coord_flip() +
      labs(title = "Top 10 Most Common Complaints",
           x = "Complaint Type", y = "Count") +
      theme_minimal()
  })
  
  
  ### 4. Complaint Status Breakdown ###
  output$status_breakdown_plot <- renderPlot({
    status_data <- complaints_data %>%
      count(status) %>%
      mutate(perc = n / sum(n) * 100)
    
    ggplot(status_data, aes(x = "", y = n, fill = status)) +
      geom_bar(width = 1, stat = "identity") +
      coord_polar("y", start = 0) +
      labs(title = "Complaint Status Breakdown", x = "", y = "") +
      theme_void() +
      theme(legend.title = element_blank())
  })
  
  
  ### 5. Complaints by Borough ###
  output$complaints_borough_plot <- renderPlot({
    # Join on unique_key (assumes both data frames have this column)
    joined_data <- inner_join(complaints_data, geographic_data, by = "unique_key")
    
    borough_data <- joined_data %>%
      count(borough, complaint_type)
    
    ggplot(borough_data, aes(x = borough, y = n, fill = complaint_type)) +
      geom_bar(stat = "identity") +
      labs(title = "Complaints by Borough",
           x = "Borough", y = "Count") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  
  ### 6. 311 Requests Map ###
  output$requests_map <- renderLeaflet({
    leaflet(geographic_data) %>%
      addTiles() %>%
      addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 3,
                       color = "red", opacity = 0.6,
                       popup = ~as.character(unique_key))
  })
  
  
  ### 7. Most Common Resolutions ###
  output$common_resolutions_plot <- renderPlot({
    resolution_data <- complaints_data %>%
      count(resolution_description, sort = TRUE) %>%
      top_n(10, n)
    
    ggplot(resolution_data, aes(x = reorder(resolution_description, n), y = n)) +
      geom_bar(stat = "identity", fill = "darkgreen") +
      coord_flip() +
      labs(title = "Most Common Resolutions",
           x = "Resolution Description", y = "Count") +
      theme_minimal()
  })
  
  
  ### 8. Correlation Between Complaint Type and Borough ###
  output$complaint_type_borough_plot <- renderPlot({
    joined_data <- inner_join(complaints_data, geographic_data, by = "unique_key")
    corr_data <- joined_data %>%
      count(complaint_type, borough)
    
    ggplot(corr_data, aes(x = complaint_type, y = borough, fill = n)) +
      geom_tile() +
      labs(title = "Complaint Type vs Borough",
           x = "Complaint Type", y = "Borough") +
      scale_fill_gradient(low = "white", high = "red") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  
  ### 9. Requests by Submission Channel ###
  output$submission_channel_plot <- renderPlot({
    channel_data <- processing_data %>%
      count(open_data_channel_type, sort = TRUE)
    
    ggplot(channel_data, aes(x = reorder(open_data_channel_type, n), y = n)) +
      geom_bar(stat = "identity", fill = "skyblue") +
      coord_flip() +
      labs(title = "Requests by Submission Channel",
           x = "Submission Channel", y = "Count") +
      theme_minimal()
  })
  
  
  ### 10. Complaints by Facility Type ###
  output$facility_type_plot <- renderPlot({
    facility_data <- processing_data %>%
      count(facility_type, sort = TRUE)
    
    ggplot(facility_data, aes(x = reorder(facility_type, n), y = n)) +
      geom_bar(stat = "identity", fill = "coral") +
      coord_flip() +
      labs(title = "Complaints by Facility Type",
           x = "Facility Type", y = "Count") +
      theme_minimal()
  })
  
  
  ### 11. Requests by Community Board ###
  output$community_board_plot <- renderPlot({
    if ("community_board" %in% names(geographic_data)) {
      community_data <- geographic_data %>%
        count(community_board, sort = TRUE)
      
      ggplot(community_data, aes(x = reorder(community_board, n), y = n)) +
        geom_bar(stat = "identity", fill = "mediumpurple") +
        coord_flip() +
        labs(title = "Requests by Community Board",
             x = "Community Board", y = "Count") +
        theme_minimal()
    } else {
      plot.new()
      text(0.5, 0.5, "Community Board data not available")
    }
  })
  
  
  ### 12. Spatial Density of Complaints (Heatmap) ###
  output$spatial_density_map <- renderLeaflet({
    leaflet(geographic_data) %>%
      addTiles() %>%
      addHeatmap(lng = ~longitude, lat = ~latitude,
                 intensity = 1, blur = 20, max = 0.05, radius = 15)
  })
  
  
  ### 13. Comparison of Open vs Closed Requests Over Time ###
  output$open_closed_plot <- renderPlot({
    # Assume complaints_data has a status column and created_date
    complaints_data$created_date <- as.Date(complaints_data$created_date)
    
    open_closed_data <- complaints_data %>%
      group_by(date = created_date, status) %>%
      summarise(count = n(), .groups = "drop")
    
    ggplot(open_closed_data, aes(x = date, y = count, fill = status)) +
      geom_bar(stat = "identity", position = "stack") +
      labs(title = "Open vs Closed Requests Over Time",
           x = "Date", y = "Count") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  
  ### 14. Resolution Action Updates Over Time ###
  output$resolution_updates_plot <- renderPlot({
    # Ensure resolution_action_updated_date is Date type
    time_data$resolution_action_updated_date <- as.Date(time_data$resolution_action_updated_date)
    
    updates_data <- time_data %>%
      group_by(date = resolution_action_updated_date) %>%
      summarise(count = n(), .groups = "drop")
    
    ggplot(updates_data, aes(x = date, y = count)) +
      geom_line(color = "brown") +
      labs(title = "Resolution Action Updates Over Time",
           x = "Date", y = "Number of Updates") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}

shinyApp(ui, server)
