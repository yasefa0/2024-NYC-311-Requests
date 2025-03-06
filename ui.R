library(shiny)
library(plotly)

shinyUI(fluidPage(
  titlePanel("NYC 311 Requests - Version 7"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("vizChoice", "Visualization:",
                  c("Agencies" = "agency",
                    "By Hour" = "hour",
                    "Submission Methods" = "submission",
                    "Word Cloud" = "wordcloud",
                    "Time Series" = "time",
                    "Borough Chart" = "borough",
                    "Resolution Times" = "resolution",
                    "Location Type Analysis" = "location",
                    "About" = "about")),
      
      conditionalPanel(
        condition = "input.vizChoice == 'location'",
        selectInput("locChoice", "Choose Location Group:",
                    c("Residential", "Commercial", "Public", "Highway", "Subway", "Other"))
      ),
      
      conditionalPanel(
        condition = "input.vizChoice == 'about'",
        h4("About This Dashboard"),
        p("Placeholder: Add more details here in the final version.")
      )
    ),
    
    mainPanel(
      conditionalPanel(
        condition = "input.vizChoice == 'location'",
        plotlyOutput("locationPie", height = "500px")
      ),
      
      # Keep other outputs from earlier versions
      conditionalPanel(condition = "input.vizChoice == 'agency'",
                       plotlyOutput("agencyPlot")
      ),
      conditionalPanel(condition = "input.vizChoice == 'hour'",
                       plotlyOutput("hourPlot")
      ),
      conditionalPanel(condition = "input.vizChoice == 'submission'",
                       plotlyOutput("submissionPlot")
      ),
      conditionalPanel(condition = "input.vizChoice == 'wordcloud'",
                       plotOutput("wordcloudPlot", height = "500px")
      ),
      conditionalPanel(condition = "input.vizChoice == 'time'",
                       plotlyOutput("timeSeriesPlot", height = "500px")
      ),
      conditionalPanel(condition = "input.vizChoice == 'borough'",
                       plotlyOutput("boroughPlot")
      ),
      conditionalPanel(condition = "input.vizChoice == 'resolution'",
                       plotlyOutput("resolutionPlot")
      ),
      conditionalPanel(
        condition = "input.vizChoice == 'about'",
        h3("NYC 311 Data Explorer (v7)"),
        p("In this version, we have a placeholder for the About section.")
      )
    )
  )
))
