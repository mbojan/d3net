#' @rdname d3net
#' @method d3net igraph
#' @export
#'
#' @details
#' All vertex and edge attributes are imported and available through the interface.
#' (Describe what can be done)
d3net.igraph <- function(dataset)
{
  igraphApp(dataset)
}

#' @method d3net network
#'
#' @details
#' Describe method for "network" objects
#'
#' @rdname d3net
#' @importFrom intergraph asIgraph
#' @export
d3net.network <- function(dataset)
{
  dataset <- asIgraph(dataset)
  igraphApp(dataset)
}



#' @importFrom igraph vertex.attributes is.weighted get.adjacency E get.edgelist closeness betweenness degree is.directed ecount edge.betweenness
igraphApp <- function(data)
{
    shinyApp(
    ui = fluidPage(
      div(class = "busy",  
          p("Calculation in progress..")),
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
               HTML('<div class="span12"><hr/><h4>Info</h4></div>'),
               div(class="span12",
                   htmlOutput("footer"),
                   div(class="span6",imageOutput("logo")))
        ),
      column(8,
        tags$head(includeScript(system.file('www', 'igraph-graph.js', package = 'd3net'))),
        tags$head(includeScript(system.file('www', 'd3.min.js', package = 'd3net'))),
        tags$head(includeScript(system.file('www', 'jquery.tipsy.js', package = 'd3net'))),
        tags$head(includeCSS(system.file('www', 'tipsy.css', package = 'd3net'))),
        reactiveNetwork(outputId = "mainnet"),
        div(id = "player", class="span4 btn-group btn-group-justified")
      )
      )
    ), 
    server = function(input, output, session) {
      
      updateSelectizeInput(
        session, 'colorScale', server = FALSE,
        options = list(create = TRUE, render = I(sprintf(
          "{
          option: function(item, escape) {
          return '<div><span style=\"color: ' 
          + escape(item.label) + '\">' + '&#11044 </span>' + escape(item.label) + '</div>';
          },
          item: function(item, escape) {
          return '<div><span style=\"color: ' 
          + escape(item.label) + '\">' + '&#11044 </span>' + escape(item.label) + '</div>';
          }
    }"
    )))
        )
    
    characterChoices <- list()
    numericChoices <- list()
    
    names_vertex_attributes <- names(igraph::vertex.attributes(data))
    for (i in names_vertex_attributes)
    {
      temp_col <- igraph::vertex.attributes(data)[[paste(i)]]
      
      if (class(temp_col) == "character" || class(temp_col) == "logical")
      {
        # if this attribute is distinct to every vertex there's no point grouping it
        characterChoices <- append(characterChoices, i)
      }
      if (class(temp_col) == "numeric" || class(temp_col) == "integer")
      {
        numericChoices <- append(numericChoices, i)
      }
    }
    
    output$edge <- renderUI({
      if (igraph::is.weighted(data))
        l <- c("None" = "none","Betweenness" = "betweenness", "Weight" = "weight")
      else
        l <- c("None" = "none","Betweenness" = "betweenness")
      selectInput("edge",
                  label = "Edges reflect",
                  choices =  l)
    })
    
    output$tooltipAttr <- renderUI({
      l <- c("Degree", "Betweenness", "Closeness", names(igraph::vertex.attributes(data)))  
      selectInput("tooltipAttr",
                  label = "Tooltip information",
                  choices = l,
                  multiple = TRUE
      )
    })
    
    output$vertexColor <- renderUI({
      selectInput("vertexColor", 
                  label = "Vertices color reflect", 
                  choices = c("None", characterChoices),
                  selected = "None")
    })
    
    output$vertexRadius <- renderUI({
      selectInput("vertexRadius", 
                  label = "Vertices radius reflect", 
                  choices = c("None", "Degree", "Betweenness", "Closeness", numericChoices),
                  selected = "None")
    })
    
    output$logo <- renderImage({
      list(src = system.file('www', 'img', 'icm-logo.png', package = 'd3net'))
    }, deleteFile = FALSE)
    
    output$footer <- renderUI({
      HTML(paste('<div class="span6">
                 Package: ', packageDescription("d3net")$Package[1], '<br/>
                 Version: ', packageDescription("d3net")$Version[1], '<br/>
                 Authors: ', packageDescription("d3net")$Author[1], '<br/>
                 </div>'))
    })
    
    # calculate predefined values for layout properties
    no_nodes <- nrow(igraph::get.adjacency(data))
    chargeValue <- min(-1, round(0.12 * no_nodes - 125))
    linkDistanceValue <- max(1, round(-0.04 * no_nodes + 54))
    vertexSizeMinValue <- max(1, round(-0.008 * no_nodes + 10.5))
    
    output$layoutProperties <- renderUI({
      list(
        sliderInput("linkDistance", "Link distance:", 
                    min=0, max=300, value = linkDistanceValue ),
        sliderInput("chargeSlider", "Charge:", 
                    min=-500, max=0, value = chargeValue ),
        sliderInput("vertexSize", "Vertex size:", 
                    min=1, max=100, value = c(vertexSizeMinValue, 3*vertexSizeMinValue)))
    })
    
    edgesReflection <- reactive({
      
      if (is.null(input$edge) || input$edge == "None")
        return(rep(NA, igraph::ecount(data)))
      
      if (input$edge == "weight")
        return(igraph::E(data)$weight)
      
      if (input$edge == "betweenness")
        return(igraph::edge.betweenness(data))
      
      return(rep(NA, igraph::ecount(data)))
    })
    
    output$mainnet <- reactive({
      if (is.null(rownames(igraph::get.adjacency(data))))
        nodes <- seq(1, nrow(igraph::get.adjacency(data)))
      else 
        nodes <- rownames(igraph::get.adjacency(data))
      connections <- igraph::get.edgelist(data)
      connectionsIdx <- matrix(nrow = nrow(connections), ncol = ncol(connections))
      
      for (i in 1 : nrow(connections))
      {
        # replace names with indexex [required by d3.js]
        sourceIdx <- which(nodes == connections[i,1])
        destIdx <- which(nodes == connections[i,2])
        
        # decrement indexes as javascript counts from 0, not 1
        connectionsIdx[i,1] <- sourceIdx - 1
        connectionsIdx[i,2] <- destIdx - 1
      }
      
      # what edges should reflect
      edges_property <- matrix(edgesReflection())
      
      # bind edges with edges property
      connectionsIdx <- cbind(connectionsIdx, edges_property)
      colnames(connectionsIdx) <- c("source","target", "property")
      # full vertices data for tooltips
      v_attributes <- igraph::vertex.attributes(data)
      v_attributes$Closeness <- as.vector(igraph::closeness(data))
      v_attributes$Betweenness <- as.vector(igraph::betweenness(data))
      v_attributes$Degree <- as.vector(igraph::degree(data))
      
      dir = igraph::is.directed(data)
      # d3 graph properties
      if (is.null(input$chargeSlider)) charge <- chargeValue else charge <- input$chargeSlider
      if (is.null(input$linkDistance)) linkDist <- linkDistanceValue else linkDist <- input$linkDistance
      if (is.null(input$vertexSize[1])) vertexMin <- vertexSizeMinValue else vertexMin <- input$vertexSize[1]
      if (is.null(input$vertexSize[2])) vertexMax <- vertexSizeMinValue*3 else vertexMax <- input$vertexSize[2]
      d3properties <- matrix(c(charge,
                               linkDist,
                               vertexMin,
                               vertexMax,
                               input$linkStrength,
                               input$colorScale,
                               as.numeric(dir)), ncol = 7)
      colnames(d3properties) <- c("charge", "linkDistance", "vertexSizeMin", 
                                  "vertexSizeMax", "linkStrength", "color", "directed")
      
      type <- "igraph"
      graphData <- list(vertices = nodes, # vertices
                        links = connectionsIdx, # edges
                        graphType = type, # what type of graph it is
                        tooltipInfo = as.list(input$tooltipAttr), # list of attributes' names for tooltip
                        vertexRadius = input$vertexRadius, # attribute that vertex radius should reflect
                        vertexColor = input$vertexColor, # attribute that vertex color should reflect
                        edgeThickness = input$edge, # attribute that edge thickness should reflect
                        verticesAttributes = v_attributes, # vertex attributes data
                        #edgesAttributes = e_attributes, # edges attributes data
                        d3 = d3properties)
      graphData
    })
    }
  )
}
