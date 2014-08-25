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
             selectizeInput("colorScale", "Choose color:",
                         choices = c("#1f77b4" = 0, "#ff7f0e" = 1, "#2ca02c" = 2, 
                                     "#d62728" = 3, "#9467bd" = 4, "#8c564b" = 5, 
                                     "#e377c2" = 6, "#7f7f7f" = 7, "#bcbd22" = 8, 
                                     "#17becf" = 9), selected = 0)
      ),
      column(2, 
             h4("R properties"),
             htmlOutput("edge"),
             htmlOutput("vertexColor"),
             htmlOutput("vertexRadius"),
             htmlOutput("tooltipAttr")
             ),
      column(8,
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/tipsy.css")),
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/colorpicker.css")),
             tags$head(tags$script(src="js/graph.js")),
             tags$head(tags$script(src="js/jquery.tipsy.js")),
             tags$head(tags$script(src="js/bootstrap-colorpicker.js")),
             tags$head(tags$script(src="http://d3js.org/d3.v3.min.js")),
             div(class = "busy",  
                 p("Calculation in progress.."), 
                 img(src="img/ajax-loader.gif")),
             div(class="span12",
                 div(id = "player", class="span4 btn-group btn-group-justified")),
                 #htmlOutput("timestampSlider")),
             reactiveNetwork(outputId = "mainnet")
             #plotOutput("rplot"),
             #downloadButton("pngDownload","Download plot as .png"),
             #downloadButton("pdfDownload","Download plot as .pdf"))
             )
      )
    )
)
