reactiveNetwork <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}

shinyUI(pageWithSidebar(    
  headerPanel("d3net"),
  
  sidebarPanel(
    h3("Sample data:"),
    h4("igraphdata-karate"),
    helpText("Network visualization in R"),
    # output format
    selectInput("outputFormat", 
                label = h3("Select output format"), 
                choices = list("Interactive d3.js" = 1, "R rendered" = 2), 
                selected = 1),
    selectInput("vertex", 
                label = h3("Vertices reflect"), 
                choices = list("Degree" = "degree", "Betweenness" = "betweenness", "Closeness" = "closeness")),
    selectInput("edge",
                label = h3("Edges reflect"),
                choices = list("Weight" = "weight", "Betweenness" = "betweenness")),
   helpText("Work in progress")
  ),
  
  mainPanel(
    tags$head(tags$script(src="graph.js")),
    tags$head(tags$script(src="http://d3js.org/d3.v3.min.js")),
    conditionalPanel(
      condition="input.outputFormat == 1",
      reactiveNetwork(outputId = "mainnet")),
    conditionalPanel(
      condition="input.outputFormat == 2",
      plotOutput("rplot"),
      downloadButton("pngDownload","Download plot as .png"),
      downloadButton("pdfDownload","Download plot as .pdf"))
  )

))
