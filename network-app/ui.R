##########################
#### DYNAMIC NETWORKS ####
##########################

reactiveNetwork <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}

progressBar <- function ()
{
  HTML('<div id = "progressBar" class="span12" style="padding: 0 1em 0 1em;">
       <input id="slider" type ="range" min ="0" max="10" step ="1" value ="0" disabled ="TRUE" style="width: 100%;"/>
       </div>')
}

alert <- function()
{
  HTML('<div class="alert alert-warning alert-dismissible" role="alert">
  <button type="button" class="close" data-dismiss="alert">
    <span aria-hidden="true">&times;</span>
    <span class="sr-only"></span></button>
      <strong>Warning!</strong> Changing settings resets the graph.
    </div>')
}

shinyUI(
  fluidPage(
    fluidRow(h1("d3net")),
    fluidRow(
      column(2, 
             h4("d3 properties"),
             sliderInput("interval", "Time interval (seconds):",
                         min=0.1, max=5, step=0.1, value=1.0),
             htmlOutput("layoutProperties"),
             sliderInput("linkStrength", "Link strength:", 
                         min=0, max=1, value=0.5),
             selectizeInput("colorScale", "Choose color:",
                         choices = c("#1f77b4" = 0, "#ff7f0e" = 1, "#2ca02c" = 2, 
                                     "#d62728" = 3, "#9467bd" = 4, "#8c564b" = 5, 
                                     "#e377c2" = 6, "#7f7f7f" = 7, "#bcbd22" = 8, 
                                     "#17becf" = 9), selected = 0)
      ),
      column(2, 
             h4("R properties"),
             htmlOutput("rProperties")
             ),
      column(8,
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/tipsy.css")),
             tags$head(tags$script(src="js/graph.js")),
             tags$head(tags$script(src="js/jquery.tipsy.js")),
             tags$head(tags$script(src="http://d3js.org/d3.v3.min.js")),
             div(class = "busy",  
                 p("Calculation in progress.."), 
                 img(src="img/ajax-loader.gif")),
             reactiveNetwork(outputId = "mainnet"),
             div(class="span12",
                 progressBar(),
                 div(id = "player", class="span4 btn-group btn-group-justified"),
                 div(id = "timeCount", class="span4"))
             #plotOutput("rplot"),
             #downloadButton("pngDownload","Download plot as .png"),
             #downloadButton("pdfDownload","Download plot as .pdf"))
             )
      )
    )
)
