# ui.R
library(shiny)
library(shinycssloaders)

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
                    "Agency Resolution Time" = "agency_resolution_time"
                  )),
      br(),
      helpText("Visualizations using entire dataset (3.4M records) may take some time to load.")
    ),
    
    mainPanel(
      withSpinner(plotOutput("selectedPlot", height = "800px"))
    )
  ),
  
  # Add explanatory notes below the plot
  fluidRow(
    column(12,
           conditionalPanel(
             condition = "input.plotType == 'stacked_time_series'",
             wellPanel(
               h4("About this Visualization"),
               p("This stacked area chart shows how different complaint types trend over time. Only the top 10 most frequent complaint types are shown for clarity. The y-axis represents the total number of complaints, and each color represents a different complaint type."),
               p("You can observe seasonal patterns or increasing/decreasing trends for specific complaint types.")
             )
           ),
           conditionalPanel(
             condition = "input.plotType == 'stacked_borough_bar'",
             wellPanel(
               h4("About this Visualization"),
               p("This stacked bar chart shows the proportion of different complaint types within each borough. The visualization includes only complaint types that make up at least 3% of the total in any borough, with the top 10 complaint types highlighted and the rest grouped as 'Other Complaints'."),
               p("This helps identify which boroughs have higher proportions of specific complaint types.")
             )
           ),
           conditionalPanel(
             condition = "input.plotType == 'agency_resolution_time'",
             wellPanel(
               h4("About this Visualization"),
               p("This bar chart shows the average time (in hours) it takes for each agency to close a request. Only agencies with more than 100 requests are included, and only the top 15 fastest agencies are displayed for clarity."),
               p("Red lines indicate the median resolution time, which helps identify agencies with skewed distributions (where a few very long cases affect the average)."),
               p("Color intensity represents the number of requests handled by each agency.")
             )
           )
    )
  )
))