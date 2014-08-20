##########################
#### DYNAMIC NETWORKS ####
##########################

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
             sliderInput("interval", "Time interval (seconds):",
                         min=1, max=10, value=3),
             sliderInput("charge", "Charge:", 
                         min=-500, max=0, value=-100),
             sliderInput("linkDistance", "Link distance:", 
                         min=0, max=300, value=50),
             sliderInput("linkStrength", "Link strength:", 
                         min=0, max=1, value=0.5),
             sliderInput("vertexSize", "Vertex size:", 
                         min=1, max=100, value = c(5,20)),
             textInput("color", "Choose color:", value = "#add8e6")
      ),
      column(2, 
             h4("R properties"),
             htmlOutput("edge"),
             htmlOutput("vertexColor"),
             htmlOutput("vertexRadius"),
             htmlOutput("tooltipAttr")
             ),
      column(8,
             div(class = "busy",  
                 p("Calculation in progress.."), 
                 img(src="img/ajax-loader.gif")),
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/tipsy.css")),
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/colorpicker.css")),
             tags$head(tags$script(src="js/graph.js")),
             tags$head(tags$script(src="js/jquery.tipsy.js")),
             tags$head(tags$script(src="js/bootstrap-colorpicker.js")),
             tags$head(tags$script(src="http://d3js.org/d3.v3.min.js")),
             htmlOutput("timestampSlider"),
             reactiveNetwork(outputId = "mainnet")
             #plotOutput("rplot"),
             #downloadButton("pngDownload","Download plot as .png"),
             #downloadButton("pdfDownload","Download plot as .pdf"))
             )
      )
    )
)
