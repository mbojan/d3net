##########################
#### DYNAMIC NETWORKS ####
##########################
data <- .d3net.dataset

shinyServer(function(input, output, session) {
  output$rplot <- renderPlot({
    plot(data)
  })
  
  output$pngDownload <- downloadHandler(
    filename = function() {
      paste('data-', Sys.Date(), '.png', sep='')
    },
    content = function(file) {
      png(file)
      plot(data)
      dev.off()
    }
  )
  
  output$pdfDownload <- downloadHandler(
    filename = function() {
      paste('data-', Sys.Date(), '.pdf', sep='')
    },
    content = function(file) {
      pdf(file)
      plot(data)
      dev.off()
    }
  )
  
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
  no_nodes <- length(network.vertex.names(data))
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
  
  output$footer <- renderUI({
    HTML('<div class="span12"><hr/><h4>Info</h4></div>
        <div class="span12">
            <div class="span6">
              Package: d3net<br/>
              Version: 0<br/>
              Authors: Michał Bojanowski, Monika Pawluczuk<br/>
            </div>
  
            <div class="span6">
            <a href="http://www.icm.edu.pl">
              <img src="img/icm-logo.png" class="img-responsive"/>
            </a>
            </div>
         </div>')
  })
  
  edgesReflection <- reactive({
    return(rep(NA,length(get.edge.activity(data, as.spellList = TRUE)$tail)))
  })
  
  output$mainnet <- reactive({
    # node activity matrix
    nodesActivity <- get.vertex.activity(data, as.spellList = TRUE)[c("vertex.id", "onset", "terminus")]
    # remove -Inf
    nodesActivity$onset[nodesActivity$onset == -Inf] <- range(get.network.attribute(data,'net.obs.period')$observations)[1]
    # remove Inf
    nodesActivity$terminus[nodesActivity$terminus == Inf] <- range(get.network.attribute(data,'net.obs.period')$observations)[2]
    
    # node names
    nodes <- as.character(network.vertex.names(data))
    
    # edges acitivity matrix
    connectionsIdx <- get.edge.activity(data, as.spellList = TRUE)[c("onset", "terminus", "tail", "head")]
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
    v_attributes <- list()
      
    for (i in network::list.vertex.attributes(data))
    {
      v_attributes[[paste(i)]] <- network::get.vertex.attribute(data, paste(i))
      v_attributes[[paste(i)]][v_attributes[[paste(i)]] == Inf] <- 'Inf'
      v_attributes[[paste(i)]][v_attributes[[paste(i)]] == -Inf] <- '-Inf'
    }
    
    # full edges data
    dir = network::is.directed(data)
    timeRangeMin <- range(get.network.attribute(data,'net.obs.period')$observations)[1]
    timeRangeMax <- range(get.network.attribute(data,'net.obs.period')$observations)[2]
    
    # d3 graph properties
    if (is.null(input$charge)) charge <- chargeValue else charge <- input$charge
    if (is.null(input$linkDistance)) linkDist <- linkDistanceValue else linkDist <- input$linkDistance
    if (is.null(input$vertexSize[1])) vertexMin <- vertexSizeMinValue else vertexMin <- input$vertexSize[1]
    if (is.null(input$vertexSize[2])) vertexMax <- vertexSizeMinValue*3 else vertexMax <- input$vertexSize[2]
    d3properties <- matrix(c(charge,
                             linkDist,
                             vertexMin,
                             vertexMax,
                             input$linkStrength,
                             input$colorScale,
                             as.numeric(dir),
                             as.numeric(timeRangeMin),
                             as.numeric(timeRangeMax)), ncol = 9)
    colnames(d3properties) <- c("charge", "linkDistance", "vertexSizeMin", "vertexSizeMax", 
                                "linkStrength", "color", "directed", "timeMin", "timeMax")
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
                      d3 = d3properties)
    
    graphData
  })
})
