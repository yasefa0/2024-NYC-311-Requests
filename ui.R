library(shiny)
library(plotly)

shinyUI(fluidPage(
  
  titlePanel("NYC 311 Requests - Version 1"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Barebones App"),
      p("One bar chart showcasing top agencies.")
    ),
    mainPanel(
      plotlyOutput("agencyPlot")
    )
  )
))
