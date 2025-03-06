# ui.R
library(shiny)
library(plotly)
library(shinycssloaders)
library(DT)

shinyUI(fluidPage(
  
  titlePanel("NYC 311 Requests Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      wellPanel(
        selectInput("plotType", "Select Visualization:",
                    c("Agency Request Volumes" = "agency_barchart",
                      "Complaint Volume by Hour" = "complaint_count_by_hour",
                      "Submission Methods" = "submission_methods",
                      "Complaint Word Cloud" = "wordcloud_descriptors",
                      "Complaint Trends Over Time" = "stacked_time_series",
                      "Complaint Types by Borough" = "stacked_borough_bar",
                      "Agency Resolution Times" = "agency_resolution_time",
                      "Geographic Map" = "geo_map",
                      "Location Type Analysis" = "location_pie",
                      "Complaint Status" = "status_bar",
                      "About This Dashboard" = "about"))
      ),
      
      conditionalPanel(
        condition = "input.plotType == 'geo_map'",
        selectInput("selected_borough", "Select Borough:",
                    c("BRONX", "MANHATTAN", "BROOKLYN", "QUEENS", "STATEN ISLAND"),
                    selected = "MANHATTAN")
      ),
      conditionalPanel(
        condition = "input.plotType == 'location_pie'",
        selectInput("location_group", "Select Location Type:",
                    c("Residential", "Commercial", "Public", "Highway", "Subway", "Other"),
                    selected = "Residential")
      ),
      conditionalPanel(
        condition = "input.plotType == 'about'",
        h4("About This Dashboard"),
        p("This dashboard explores NYC 311 service request data to identify patterns and insights."),
        p("Data source: NYC Open Data 311 Service Requests"),
        p("Created using R Shiny, DuckDB, and various visualization libraries.")
      )
    ),
    
    mainPanel(
      conditionalPanel(
        condition = "input.plotType != 'geo_map' && input.plotType != 'wordcloud_descriptors' && input.plotType != 'location_pie' && input.plotType != 'status_bar' && input.plotType != 'about'",
        withSpinner(plotlyOutput("selectedPlot", height = "600px"))
      ),
      conditionalPanel(
        condition = "input.plotType == 'geo_map'",
        withSpinner(plotlyOutput("geoMap", height = "600px")),
        br(),
        dataTableOutput("pointDetailTable")
      ),
      conditionalPanel(
        condition = "input.plotType == 'location_pie'",
        withSpinner(plotlyOutput("locationPie", height = "600px"))
      ),
      conditionalPanel(
        condition = "input.plotType == 'wordcloud_descriptors'",
        withSpinner(plotOutput("wordcloudPlot", height = "600px"))
      ),
      conditionalPanel(
        condition = "input.plotType == 'status_bar'",
        withSpinner(plotlyOutput("statusBar", height = "600px"))
      ),
      conditionalPanel(
        condition = "input.plotType == 'geo_map'",
        div(
          DT::dataTableOutput("pointDetailTable"),
          style = "margin-top: 20px;"
        )
      ),
      conditionalPanel(
        condition = "input.plotType == 'about'",
        h3("NYC 311 Data Explorer"),
        p("This dashboard provides visualizations of NYC's 311 service request data."),
        p("The data includes service requests from various agencies, complaint types, and locations."),
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
          tags$li(strong("Complaint Status:"), " Distribution of request statuses")
        ),
        hr(),
        p("Data Source: NYC Open Data 311 Service Requests")
      )
    )
  )
))
