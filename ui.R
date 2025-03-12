library(shiny)
library(shinycssloaders)
library(plotly)
library(shinydashboard)

dashboardPage(
  dashboardHeader(title = "NYC 311 Requests Dashboard"),
  dashboardSidebar(
    sidebarMenu(id = "plotType",
                menuItem("About", icon = icon("info-circle"), tabName = "about", selected = TRUE),
                menuItem("Agency Requests Volumes", icon = icon("chart-bar"), tabName = "agency_barchart"),
                menuItem("Complaint Volume by Hour", icon = icon("clock"), tabName = "complaint_count_by_hour"),
                menuItem("Submission Methods", icon = icon("paper-plane"), tabName = "submission_methods"),
                menuItem("Complaint Word Cloud", icon = icon("cloud"), tabName = "wordcloud_descriptors"),
                menuItem("Complaint Trends Over Time", icon = icon("chart-line"), tabName = "stacked_time_series"),
                menuItem("Complaints by Borough", icon = icon("map-marker-alt"), tabName = "stacked_borough_bar"),
                menuItem("Agency Resolution Time", icon = icon("hourglass"), tabName = "agency_resolution_time"),
                menuItem("Location Type Analysis", icon = icon("chart-pie"), tabName = "location_pie"),
                menuItem("Complaint Status", icon = icon("bar-chart"), tabName = "status_bar"),
                menuItem("Geographic Map", icon = icon("map"), tabName = 'geo_map')
    )
  ),
  dashboardBody(
    # About section (displayed by default)
    conditionalPanel(
      condition = "input.plotType == 'about'",
      box(width = 12, title = "About This Dashboard", status = "primary",
          h3("NYC 311 Service Requests Analysis Dashboard"),
          p("Updated 02/18/25"),
          p("This project analyzes NYC 311 service requests in 2024 through an interactive data dashboard. Using data provided by NYC OpenData, the dashboard explores patterns in service requests, including complaint trends, agency involvement, response times, submission methods, and temporal patterns. The goal is to provide stakeholders with actionable insights into city services and response efficiency."),
          h4("Statistical Analysis"),
          p("Statistical analysis was conducted to examine key trends and insights within the dataset. This includes:"),
          tags$ul(
            tags$li("Identifying the most common complaints across NYC, as well as trends by borough and month."),
            tags$li("Analyzing response times by comparing request creation and closure dates."),
            tags$li("Determining the agencies that handle the highest volume of complaints."),
            tags$li("Evaluating the primary methods residents use to submit 311 requests."),
            tags$li("Exploring peak hours when complaints are reported.")
          ),
          h4("Interpretation"),
          p("The analysis highlights service bottlenecks, high-volume complaint areas, and agency efficiency in resolving requests. This information can help optimize city resource allocation and enhance public services."),
          h4("Limitations"),
          p("The analysis relies on reported 311 requests, which may not fully capture all service-related issues due to potential reporting biases or missing data. Additionally, external factors such as weather conditions, seasonal demand, and operational constraints may influence response times and complaint frequency."),
          h4("Challenges and Goals"),
          p("The primary challenge of this dashboard is to efficiently process and visualize large-scale 311 request data in real time. The goals of the dashboard include:"),
          tags$ul(
            tags$li("Providing an intuitive and interactive tool for analyzing 311 service request patterns."),
            tags$li("Helping city officials, community leaders, and the public identify recurring service issues."),
            tags$li("Enhancing transparency by making complaint trends and agency performance data more accessible."),
            tags$li("Supporting data-driven decision-making to improve response times and resource distribution.")
          ),
          h4("Visualizations Available:"),
          tags$ul(
            tags$li(strong("Agency Request Volumes:"), " Top agencies by number of requests"),
            tags$li(strong("Complaint Volume by Hour:"), " How request volume varies throughout the day"),
            tags$li(strong("Submission Methods:"), " How citizens submit their 311 requests"),
            tags$li(strong("Complaint Word Cloud:"), " Common descriptors used in complaints"),
            tags$li(strong("Complaint Trends Over Time:"), " How complaint types change over months"),
            tags$li(strong("Complaint Types by Borough:"), " Proportion of complaints by borough"),
            tags$li(strong("Agency Resolution Times:"), " How quickly agencies resolve complaints"),
            tags$li(strong("Geographic Map:"), " Spatial distribution of complaints by borough"),
            tags$li(strong("Location Type Analysis:"), " Most common complaints by location category"),
            tags$li(strong("Complaint Status:"), " Distribution of request statuses") # Removed extra comma
          ),
          p("For more information, visit our GitHub repository."),
          h4("Authors:"),
          p("Yared Asefa, Mohamed M, Sakaria Dirie")
      )
    ),
    
    conditionalPanel(
      condition = "input.plotType == 'geo_map'",
      selectInput("selected_borough", "Select Borough:",
                  choices = c("BRONX", "MANHATTAN", "BROOKLYN", "QUEENS", "STATEN ISLAND")
      )
    ),
    
    # Location group radio buttons (only shown when location_pie is selected)
    conditionalPanel(
      condition = "input.plotType == 'location_pie'",
      box(width = 12, title = "Select Location Group", status = "primary",
          radioButtons("location_group", NULL,
                       choices = c("Residential", "Highway", "Subway", "Commercial", "Public", "Other"),
                       selected = "Residential", inline = TRUE)
      )
    ),
    
    # Plots
    fluidRow(
      conditionalPanel(
        condition = "input.plotType == 'geo_map'",
        plotlyOutput("geoMap", height = "1000px")
      ),
      # Use a conditional panel for the location pie chart
      conditionalPanel(
        condition = "input.plotType == 'location_pie'",
        box(width = 12, withSpinner(plotlyOutput("locationPie", height = "700px")))
      ),
      # Special handling for wordcloud
      conditionalPanel(
        condition = "input.plotType == 'wordcloud_descriptors'",
        box(width = 12, style = "text-align: center;",  # Center the word cloud box
            withSpinner(plotOutput("wordcloudPlot", height = "1000px", width = "1000px"))
        )
      ),
      # Show the regular plot for other visualizations (except about and wordcloud)
      conditionalPanel(
        condition = "input.plotType != 'location_pie' && input.plotType != 'about' && input.plotType != 'wordcloud_descriptors' && input.plotType != 'status_bar'",
        box(width = 12, withSpinner(plotlyOutput("selectedPlot", height = "700px")))
      ),
      # Complaint Status Bar Chart
      conditionalPanel(
        condition = "input.plotType == 'status_bar'",
        box(width = 12, withSpinner(plotlyOutput("statusBar", height = "700px")))
      )
    )
  )
)
