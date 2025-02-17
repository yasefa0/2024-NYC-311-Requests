# ui.R
#
# Purpose: User Interface for the NYC 311 Requests Data Dashboard

library(shiny)

shinyUI(fluidPage(
  titlePanel("NYC 311 Requests Data Dashboard"),
  sidebarLayout(
    sidebarPanel(
      selectInput("plotType", "Select Visualization:", 
                  choices = list(
                    "Agency Performance" = "agency_barchart",
                    "Complaint Type Distribution" = "complaint_type_distribution",
                    "Submission Methods" = "submission_methods",
                    "Status Distribution" = "status_distribution",
                    "Borough Distribution" = "borough_distribution",
                    "Top Complaints by Agency" = "top_complaints_by_agency",
                    "Complaints by Hour" = "complaint_by_hour",
                    "Time Series Plot" = "time_series_plot",
                    "Word Cloud (Descriptors)" = "wordcloud_descriptors",
                    "Top 5 Reasons by Location" = "top5_reasons_by_location_type",
                    "Bridge/Highway Complaints" = "bridge_highway_visuals"
                  ))
    ),
    mainPanel(
      plotOutput("selectedPlot")
    )
  )
))