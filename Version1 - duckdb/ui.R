# ui.R
library(shiny)
library(shinycssloaders)
library(plotly)
library(shinydashboard)

dashboardPage(
  dashboardHeader(title = "NYC 311 Requests Dashboard"),
  dashboardSidebar(
    sidebarMenu(id = "plotType",
                menuItem("About", icon = icon("info-circle"), tabName = "about", selected = TRUE),
                menuItem("Agency Performance", icon = icon("chart-bar"), tabName = "agency_barchart"),
                menuItem("Complaint Count by Hour", icon = icon("clock"), tabName = "complaint_count_by_hour"),
                menuItem("Submission Methods", icon = icon("paper-plane"), tabName = "submission_methods"),
                menuItem("Descriptor Word Cloud", icon = icon("cloud"), tabName = "wordcloud_descriptors"),
                menuItem("Complaint Trends Over Time", icon = icon("chart-line"), tabName = "stacked_time_series"),
                menuItem("Complaints by Borough", icon = icon("map-marker-alt"), tabName = "stacked_borough_bar"),
                menuItem("Agency Resolution Time", icon = icon("hourglass"), tabName = "agency_resolution_time"),
                menuItem("Location Complaint Pie Chart", icon = icon("chart-pie"), tabName = "location_pie")
    )
  ),
  dashboardBody(
    # About section (displayed by default)
    conditionalPanel(
      condition = "input.plotType == 'about'",
      box(width = 12, title = "About This Dashboard", status = "primary",
          h3("NYC 311 Service Requests Analysis Dashboard"),
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
          p("For more information, visit our GitHub repository."),
          h4("Authors:"),
          p("Yared Asefa, Mohamed M, Sakaria Dirie")
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
      # Use a conditional panel for the location pie chart
      conditionalPanel(
        condition = "input.plotType == 'location_pie'",
        box(width = 12, withSpinner(plotlyOutput("locationPie", height = "600px")))
      ),
      # Show the regular plot for other visualizations (except about)
      conditionalPanel(
        condition = "input.plotType != 'location_pie' && input.plotType != 'about'",
        box(width = 12, withSpinner(plotOutput("selectedPlot", height = "600px")))
      )
    ),
    
    # Explanatory notes for specific visualizations
    conditionalPanel(
      condition = "input.plotType == 'stacked_time_series'",
      fluidRow(
        box(width = 12,
            wellPanel(
              h4("About this Visualization"),
              p("This stacked area chart shows how different complaint types trend over time. Only the top 10 most frequent complaint types are shown for clarity. The y-axis represents the total number of complaints, and each color represents a different complaint type."),
              p("Observe seasonal patterns or trends for specific complaint types.")
            )
        )
      )
    ),
    conditionalPanel(
      condition = "input.plotType == 'stacked_borough_bar'",
      fluidRow(
        box(width = 12,
            wellPanel(
              h4("About this Visualization"),
              p("This stacked bar chart shows the proportion of different complaint types within each borough. Only complaint types that make up at least 3% of the total in any borough are shown, with the top 10 complaint types highlighted and others grouped as 'Other Complaints'."),
              p("This helps identify which boroughs have higher proportions of specific complaint types.")
            )
        )
      )
    ),
    conditionalPanel(
      condition = "input.plotType == 'agency_resolution_time'",
      fluidRow(
        box(width = 12,
            wellPanel(
              h4("About this Visualization"),
              p("This bar chart shows the average time (in hours) it takes for each agency to close a request. Only agencies with more than 100 requests are included, and only the top 15 fastest agencies are displayed for clarity."),
              p("Red lines indicate the median resolution time, helping identify agencies with skewed distributions."),
              p("Color intensity represents the number of requests handled by each agency.")
            )
        )
      )
    )
  )
)