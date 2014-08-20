##########################
#### DYNAMIC NETWORKS ####
##########################
data <- .d3net.dataset

shinyServer(function(input, output) {
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
  
  characterChoices <- list()
  numericChoices <- list()
  
  if (inherits(data, "networkDynamic")) names_vertex_attributes <- network::list.vertex.attributes(data)
  for (i in names_vertex_attributes)
  {
    if (inherits(data, "networkDynamic")) temp_col <- network::get.vertex.attribute(data, paste(i))
    
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
    l <- c("None" = "none")
    selectInput("edge",
                label = "Edges reflect",
                choices =  l)
  })
  
  output$tooltipAttr <- renderUI({
      l <- network::list.vertex.attributes(data)
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
    l <- c("None", numericChoices)
    selectInput("vertexRadius", 
                label = "Vertices radius reflect", 
                choices = l,
                selected = "None")
  })
  
  output$timestampSlider <- renderUI({
    sliderInput("timestampSlider",
                label = "Select timestamp",
                min = get.change.times(data)[1], 
                max = get.change.times(data)[length(get.change.times(data))],
                value=get.change.times(data)[1])
  })
  
  edgesReflection <- reactive({
    if (inherits(data, "networkDynamic"))
      return(rep(NA,length(get.edge.activity(data, as.spellList = TRUE)$tail)))
  })
  
  output$mainnet <- reactive({
    # node activity matrix
    nodesActivity <- get.vertex.activity(data, as.spellList = TRUE)[c("vertex.id", "onset", "terminus")]
    # remove -Inf
    nodesActivity$onset[nodesActivity$onset == -Inf] <- get.change.times(data)[1]
    # remove Inf
    nodesActivity$terminus[nodesActivity$terminus == Inf] <- get.change.times(data)[length(get.change.times(data))]
    
    # node names
    nodes <- as.character(network.vertex.names(data))
    
    # edges acitivity matrix
    connectionsIdx <- get.edge.activity(data, as.spellList = TRUE)[c("onset", "terminus", "tail", "head")]
    
    for (i in 1:nrow(connectionsIdx)) 
    { 
      
      # remove onset -infitiy values
      if (connectionsIdx[i,]$onset == -Inf)
        connectionsIdx[i,]$onset <-
          max(nodesActivity[which(nodesActivity$vertex.id == connectionsIdx[i,]$tail),]$onset, 
            nodesActivity[which(nodesActivity$vertex.id == connectionsIdx[i,]$head),]$onset)
      
      # remove terminus infitiy values
      if (connectionsIdx[i,]$terminus == Inf)
        connectionsIdx[i,]$terminus <-
          min(nodesActivity[which(nodesActivity$vertex.id == connectionsIdx[i,]$tail),]$terminus, 
            nodesActivity[which(nodesActivity$vertex.id == connectionsIdx[i,]$head),]$terminus)
      
      # decrement indexes as javascript counts from 0, not 1
      connectionsIdx[i,]$tail <- connectionsIdx[i,]$tail - 1
      connectionsIdx[i,]$head <- connectionsIdx[i,]$head - 1
    }
    
    
    # what edges should reflect
    edges_property <- matrix(edgesReflection())
    
    # bind edges with edges property
    connectionsIdx <- cbind(connectionsIdx, edges_property)
    colnames(connectionsIdx) <- c("onset", "terminus", "source", "target", "property")
    
    # format data for javascript
    nodesActivity <- as.matrix(nodesActivity)
    connectionsIdx <- as.matrix(connectionsIdx)
    
    v_attributes <- list()
      
    for (i in network::list.vertex.attributes(data))
    {
      v_attributes[[paste(i)]] <- network::get.vertex.attribute(data, paste(i))
      v_attributes[[paste(i)]][v_attributes[[paste(i)]] == Inf] <- 'Inf'
      v_attributes[[paste(i)]][v_attributes[[paste(i)]] == -Inf] <- '-Inf'
    }
    
    # full edges data
    #e_attributes <- edge.attributes(data)
    #e_attributes$Betweenness <- as.vector(edge.betweenness(data))
    
    dir = network::is.directed(data)
    timestamp <- get.change.times(data)[length(get.change.times(data))]
    # d3 graph properties
    d3properties <- matrix(c(input$charge,
                             input$linkDistance, 
                             input$linkStrength,
                             input$vertexSize[1],
                             input$vertexSize[2],
                             input$color,
                             as.numeric(dir),
                             as.numeric(timestamp)), ncol = 8)
    colnames(d3properties) <- c("charge", "linkDistance", "linkStrength", "vertexSizeMin", 
                                "vertexSizeMax", "color", "directed", "timeMax")

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
                      #edgesAttributes = e_attributes, # edges attributes data
                      d3 = d3properties)
    graphData
  })
})
