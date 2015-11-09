#============================================================================ 
# Here we describe issues specific to the DYNAMIC application
#============================================================================ 
#' @method d3net networkDynamic
#' @rdname d3net
#' @export
#'
#' @details
#' (TODO: Describe dynamic application)
#'
#' For dynamic visualisations, user may also set the time interval between each
#' timepoint.  It is by default 3000ms (3s). To play with the visualisation,
#' use the controls below the graph.  It is also possible to pause a
#' visualisation and freeze the graph by pressing spacebar.
d3net.networkDynamic <- function(dataset, ...)
{
  networkDynamicApp(dataset, ...)
}


networkDynamicApp <- function(data) {
  shinyApp(
    ui = fluidPage(
      div(class = "busy",  
          p("Calculation in progress..")),
      fluidRow(h1("d3net")),
      fluidRow(
        column(4,
               column(6, id = "layoutd3",
                      h4("d3 properties"),
                      sliderInput("interval", "Time interval (seconds):",
                                  min=0.1, max=5, step=0.1, value=3.0),
                      htmlOutput("layoutProperties"),
                      sliderInput("linkStrength", "Link strength:", 
                                  min=0, max=1, value=0.1),
                      selectizeInput("colorScale", "Choose color:",
                                     choices = c("#1f77b4" = 0, "#ff7f0e" = 1, "#2ca02c" = 2, 
                                                 "#d62728" = 3, "#9467bd" = 4, "#8c564b" = 5, 
                                                 "#e377c2" = 6, "#7f7f7f" = 7, "#bcbd22" = 8, 
                                                 "#17becf" = 9), selected = 0)
               ),
               column(6, id = "layoutR",
                      h4("R properties"),
                      htmlOutput("rProperties")
               ),
               HTML('<div class="span12"><hr/><h4>Info</h4></div>'),
               div(class="span12",
                   htmlOutput("footer"),
                   div(class="span6",imageOutput("logo")))
        ),
        column(8,
               tags$head(includeScript(system.file('www', 'network-graph.js', package = 'd3net'))),
               tags$head(includeScript(system.file('www', 'd3.min.js', package = 'd3net'))),
               tags$head(includeScript(system.file('www', 'jquery.tipsy.js', package = 'd3net'))),
               tags$head(includeCSS(system.file('www', 'tipsy.css', package = 'd3net'))),
               reactiveNetwork(outputId = "mainnet"),
               div(progressBar(),
                   div(id = "player", class="btn-group"),
                   div(id = "timeInfo", class="span3"),
                   div(id = "timeCount", class="span3"))
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
    
    names_vertex_attributes <- network::list.vertex.attributes(data)
    for (i in names_vertex_attributes)
    {
      temp_col <- network::get.vertex.attribute(data, paste(i))
      
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
    
    # calculate predefined values for layout properties
    no_nodes <- length(network::network.vertex.names(data))
    chargeValue <- min(-1, round(0.12 * no_nodes - 125))
    linkDistanceValue <- max(1, round(-0.04 * no_nodes + 54))
    vertexSizeMinValue <- max(1, round(-0.008 * no_nodes + 10.5))
    
    output$layoutProperties <- renderUI({
      list(
        sliderInput("linkDistance", "Link distance:", 
                    min=0, max=300, value = linkDistanceValue ),
        sliderInput("charge", "Charge:", 
                    min=-500, max=0, value = chargeValue ),
        sliderInput("vertexSize", "Vertex size:", 
                    min=1, max=100, value = c(vertexSizeMinValue, 3*vertexSizeMinValue)))
    })
    
    output$rProperties <- renderUI({
      list(
        selectInput("edge", label = "Edges reflect",
                    choices =  c("None" = "none")),
        selectInput("vertexColor", label = "Vertices color reflect", 
                    choices = c("None", characterChoices),
                    selected = "None"),
        selectInput("vertexRadius", label = "Vertices radius reflect", 
                    choices = c("None", numericChoices),
                    selected = "None"),
        selectInput("tooltipAttr",label = "Tooltip information",
                    choices = network::list.vertex.attributes(data),
                    multiple = TRUE)
      )
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
    
    edgesReflection <- reactive({
      return(rep(NA,length(networkDynamic::get.edge.activity(data, as.spellList = TRUE)$tail)))
    })
    
    output$mainnet <- reactive({
      # node activity matrix
      nodesActivity <- networkDynamic::get.vertex.activity(data, as.spellList = TRUE)[c("vertex.id", "onset", "terminus")]
      # remove -Inf
      nodesActivity$onset[nodesActivity$onset == -Inf] <- range(network::get.network.attribute(data,'net.obs.period')$observations)[1]
      # remove Inf
      nodesActivity$terminus[nodesActivity$terminus == Inf] <- range(network::get.network.attribute(data,'net.obs.period')$observations)[2]
      
      # node names
      nodes <- as.character(network::network.vertex.names(data))
      
      # edges acitivity matrix
      connectionsIdx <- networkDynamic::get.edge.activity(data, as.spellList = TRUE)[c("onset", "terminus", "tail", "head")]
      # remove onset -Inf values
      i <- which( connectionsIdx$onset == -Inf )
      mv.tail <- match( connectionsIdx$tail[i], nodesActivity$vertex.id )
      mv.head <- match( connectionsIdx$head[i], nodesActivity$vertex.id )
      connectionsIdx$onset[i] <- with(nodesActivity, pmax( onset[mv.tail], onset[mv.head]))
      # remove terminus Inf values
      i <- which( connectionsIdx$terminus == Inf )
      mv.tail <- match( connectionsIdx$tail[i], nodesActivity$vertex.id )
      mv.head <- match( connectionsIdx$head[i], nodesActivity$vertex.id )
      connectionsIdx$terminus[i] <- with(nodesActivity, pmin( terminus[mv.tail], terminus[mv.head]))
      # decrement indexes as javascript counts from 0, not 1
      connectionsIdx$tail <- connectionsIdx$tail - 1
      connectionsIdx$head <- connectionsIdx$head - 1
      # clean-up
      rm(i, mv.head, mv.tail)
      
      # what edges should reflect
      edges_property <- matrix(edgesReflection())
      
      # bind edges with edges property
      connectionsIdx <- cbind(connectionsIdx, edges_property)
      colnames(connectionsIdx) <- c("onset", "terminus", "source", "target", "property")
      
      # format data for javascript
      nodesActivity <- apply(nodesActivity, 1:2, as.character)
      nodesActivity <- as.matrix(nodesActivity)
      
      connectionsIdx <- apply(connectionsIdx, 1:2, as.character)
      connectionsIdx <- as.matrix(connectionsIdx)

      # vertices attributes list
      v_attributes <- list()
      
      for (i in network::list.vertex.attributes(data))
      {
        v_attributes[[paste(i)]] <- network::get.vertex.attribute(data, paste(i))
        v_attributes[[paste(i)]][v_attributes[[paste(i)]] == Inf] <- 'Inf'
        v_attributes[[paste(i)]][v_attributes[[paste(i)]] == -Inf] <- '-Inf'
      }
      
      # is network directed
      dir = network::is.directed(data)
      
      # time ranges
      timeRangeMin <- range(network::get.network.attribute(data,'net.obs.period')$observations)[1]
      timeRangeMax <- range(network::get.network.attribute(data,'net.obs.period')$observations)[2]
      
      # d3 graph properties
      if (is.null(input$charge)) charge <- chargeValue 
      else charge <- input$charge
      if (is.null(input$linkDistance)) 
        linkDist <- linkDistanceValue 
      else linkDist <- input$linkDistance
      if (is.null(input$vertexSize[1])) 
        vertexMin <- vertexSizeMinValue 
      else vertexMin <- input$vertexSize[1]
      if (is.null(input$vertexSize[2])) 
        vertexMax <- vertexSizeMinValue*3 
      else vertexMax <- input$vertexSize[2]

      d3properties <- list("charge" = charge,
                           "linkDistance" = linkDist,
                           "vertexSizeMin" = vertexMin,
                           "vertexSizeMax" = vertexMax,
                           "linkStrength" = input$linkStrength,
                           "color" = as.numeric(input$colorScale),
                           "directed" = as.numeric(dir),
                           "timeMin" = as.numeric(timeRangeMin),
                           "timeMax" = as.numeric(timeRangeMax)
      )
    
      type <- "networkDynamic"
      graphData <- list(vertices = nodes, # vertices
                        verticesActivity = nodesActivity, # vertices time stamps
                        links = connectionsIdx, # edges
                        graphType = type, # what type of graph it is
                        tooltipInfo = as.list(input$tooltipAttr), # list of attributes' names for tooltip
                        vertexRadius = input$vertexRadius, # attribute that vertex radius should reflect
                        vertexColor = input$vertexColor, # attribute that vertex color should reflect
                        edgeThickness = input$edge, # attribute that edge thickness should reflect
                        verticesAttributes = v_attributes, # vertex attributes data
                        d3 = d3properties
                        )
      
      graphData
    })
    }
  )
}
