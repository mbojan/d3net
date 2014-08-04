reactiveNetwork <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}

shinyUI(
  fluidPage(
    fluidRow(h1("d3net")),
    fluidRow(
      column(2, 
             h4("d3 properties"),
             sliderInput("charge", "Charge:", 
                         min=-500, max=0, value=-300),
             sliderInput("linkDistance", "Link distance:", 
                         min=0, max=300, value=150),
             sliderInput("linkStrength", "Link strength:", 
                         min=0, max=1, value=0.5),
             sliderInput("vertexSize", "Vertex size:", 
                         min=1, max=100, value = c(10,50))
             ),
      column(2, 
             h4("R properties"),
             selectInput("outputFormat", 
                         label = "Select output format", 
                         choices = list("Interactive d3.js" = 1, "R rendered" = 2), 
                         selected = 1),
             selectInput("edge",
                         label = "Edges reflect",
                         choices = list("None" = "none","Weight" = "weight", "Betweenness" = "betweenness")),
             htmlOutput("vertexColor"),
             htmlOutput("vertexRadius"),
             htmlOutput("tooltipAttr")
             ),
      column(8,
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "tipsy.css")),
             tags$head(tags$script(src="directed-graph.js")),
             tags$head(tags$script(src="randomColor.js")),
             tags$head(tags$script(src="jquery.tipsy.js")),
             tags$head(tags$script(src="http://d3js.org/d3.v3.min.js")),
             conditionalPanel(
               condition="input.outputFormat == 1",
               reactiveNetwork(outputId = "mainnet")),
             conditionalPanel(
               condition="input.outputFormat == 2")
             #plotOutput("rplot"),
             #downloadButton("pngDownload","Download plot as .png"),
             #downloadButton("pdfDownload","Download plot as .pdf"))
             )
      )
    )
)
