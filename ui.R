library(shiny)
library(plotly)

shinyUI(fluidPage(
  titlePanel("NYC 311 Requests - Version 6"),
  
  sidebarLayout(
    sidebarPanel(
      radioButtons("vizChoice", "Choose Visualization:",
                   choices = list("Agencies" = "agency",
                                  "By Hour" = "hour",
                                  "Submission Methods" = "submission",
                                  "Word Cloud" = "wordcloud",
                                  "Time Series" = "time",
                                  "Borough Chart" = "borough",
                                  "Resolution Times" = "resolution"))
    ),
    mainPanel(
      conditionalPanel(condition = "input.vizChoice == 'borough'",
                       plotlyOutput("boroughPlot")
      ),
      conditionalPanel(condition = "input.vizChoice == 'resolution'",
                       plotlyOutput("resolutionPlot")
      ),
      
      # Keep earlier versions' outputs:
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
      )
    )
  )
))
