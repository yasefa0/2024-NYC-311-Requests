# ui.R
library(shiny)
library(shinycssloaders)
library(plotly)

shinyUI(fluidPage(
  titlePanel("NYC 311 Requests Data Dashboard"),
  sidebarLayout(
    sidebarPanel(
      selectInput("plotType", "Select Visualization:", 
                  choices = list(
                    "Agency Performance" = "agency_barchart",
                    "Complaint Count by Hour" = "complaint_count_by_hour",
                    "Submission Methods" = "submission_methods",
                    "Descriptor Word Cloud" = "wordcloud_descriptors",
                    "Complaint Trends Over Time" = "stacked_time_series",
                    "Complaints by Borough" = "stacked_borough_bar",
                    "Agency Resolution Time" = "agency_resolution_time",
                    "Location Complaint Pie Chart" = "location_pie"
                  )),
      br(),
      helpText("Visualizations using the entire dataset (3.4M records) may take some time to load."),
      # Show radio buttons only when the Location Complaint Pie Chart is selected.
      conditionalPanel(
        condition = "input.plotType == 'location_pie'",
        radioButtons("location_group", "Select Location Group:",
                     choices = c("Residential", "Highway", "Subway", "Commercial", "Public", "Other"),
                     inline = TRUE)
      )
    ),
    mainPanel(
      # Display the Plotly pie chart if location_pie is selected...
      conditionalPanel(
        condition = "input.plotType == 'location_pie'",
        withSpinner(plotlyOutput("locationPie", height = "600px"))
      ),
      # ...otherwise display the regular plot.
      conditionalPanel(
        condition = "input.plotType != 'location_pie'",
        withSpinner(plotOutput("selectedPlot", height = "800px"))
      )
    )
  ),
  # Explanatory notes for some visualizations
  fluidRow(
    column(12,
           conditionalPanel(
             condition = "input.plotType == 'stacked_time_series'",
             wellPanel(
               h4("About this Visualization"),
               p("This stacked area chart shows how different complaint types trend over time. Only the top 10 most frequent complaint types are shown for clarity. The y-axis represents the total number of complaints, and each color represents a different complaint type."),
               p("Observe seasonal patterns or trends for specific complaint types.")
             )
           ),
           conditionalPanel(
             condition = "input.plotType == 'stacked_borough_bar'",
             wellPanel(
               h4("About this Visualization"),
               p("This stacked bar chart shows the proportion of different complaint types within each borough. Only complaint types that make up at least 3% of the total in any borough are shown, with the top 10 complaint types highlighted and others grouped as 'Other Complaints'."),
               p("This helps identify which boroughs have higher proportions of specific complaint types.")
             )
           ),
           conditionalPanel(
             condition = "input.plotType == 'agency_resolution_time'",
             wellPanel(
               h4("About this Visualization"),
               p("This bar chart shows the average time (in hours) it takes for each agency to close a request. Only agencies with more than 100 requests are included, and only the top 15 fastest agencies are displayed for clarity."),
               p("Red lines indicate the median resolution time, helping identify agencies with skewed distributions."),
               p("Color intensity represents the number of requests handled by each agency.")
             )
           )
    )
  )
))
