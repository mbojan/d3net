############################
#### IGRAPHS & NETWORKS ####
############################

reactiveNetwork <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}

shinyUI(
  fluidPage(
    div(class = "busy",  
        p("Calculation in progress.."), 
        img(src="img/ajax-loader.gif")),
    fluidRow(h1("d3net")),
    fluidRow(
      column(4,
             column(6, 
                    h4("d3 properties"),
                    
                    sliderInput("charge", "Charge:", 
                                min=-500, max=0, value=-300),
                    htmlOutput("layoutProperties"),
                    sliderInput("linkStrength", "Link strength:", 
                                min=0, max=1, value=0.5),
                    selectizeInput("colorScale", "Choose color:",
                                   choices = c("#1f77b4" = 0, "#ff7f0e" = 1, "#2ca02c" = 2, 
                                               "#d62728" = 3, "#9467bd" = 4, "#8c564b" = 5, 
                                               "#e377c2" = 6, "#7f7f7f" = 7, "#bcbd22" = 8, 
                                               "#17becf" = 9), selected = 0)
             ),
             column(6, 
                    h4("R properties"),
                    selectInput("outputFormat", 
                                label = "Select output format", 
                                choices = list("Interactive d3.js" = 1, "R rendered" = 2), 
                                selected = 1),
                    htmlOutput("edge"),
                    htmlOutput("vertexColor"),
                    htmlOutput("vertexRadius"),
                    htmlOutput("tooltipAttr")
             ),
             htmlOutput("footer")
             ),
      column(8,
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/tipsy.css")),
             tags$head(tags$script(src="js/graph.js")),
             tags$head(tags$script(src="js/jquery.tipsy.js")),
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
