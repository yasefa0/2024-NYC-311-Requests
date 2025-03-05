library(shiny)
library(plotly)

shinyUI(fluidPage(
  titlePanel("NYC 311 Requests - Version 4"),
  
  sidebarLayout(
    sidebarPanel(
      radioButtons("vizChoice", "Choose Visualization:",
                   choices = list("Top Agencies" = "agency",
                                  "By Hour" = "hour",
                                  "Submission Methods" = "submission",
                                  "Word Cloud" = "wordcloud"))
    ),
    mainPanel(
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
      )
    )
  )
))
