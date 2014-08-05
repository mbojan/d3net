data <- .d3net.dataset

shinyServer(function(input, output) {
  #if ((class(data) != 'igraph') && (class(data) != 'networkDynamic')) stop()
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
  
  if (inherits(data, "igraph")) names_vertex_attributes <- names(igraph::vertex.attributes(data))
  if (inherits(data, "networkDynamic")) names_vertex_attributes <- network::list.vertex.attributes(data)
  for (i in names_vertex_attributes)
  {
    if (inherits(data, "igraph")) temp_col <- igraph::vertex.attributes(data)[[paste(i)]]
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
    if (inherits(data, "igraph") && is.weighted(data))
      l <- c("None" = "none","Betweenness" = "betweenness", "Weight" = "weight")
    else
      l <- c("None" = "none","Betweenness" = "betweenness")
    selectInput("edge",
                label = "Edges reflect",
                choices =  l)
  })
  
  output$tooltipAttr <- renderUI({
      if (inherits(data, "igraph"))
      {
        selectInput("tooltipAttr",
                    label = "Tooltip information",
                    choices = c("Degree", "Betweenness", "Closeness", names(igraph::vertex.attributes(data))),
                    multiple = TRUE
        )
      }
      if (inherits(data, "networkDynamic"))
      {
        selectInput("tooltipAttr",
                    label = "Tooltip information",
                    choices = network::list.vertex.attributes(data),
                    multiple = TRUE
        )
      }
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
  
  output$time <- renderUI({
    if (inherits(data, "networkDynamic"))  
    {
      selectInput("time", 
                label = "Select timestamp", 
                choices = get.change.times(data),
                selected = get.change.times(data)[1])
    }
  })
  
  edgesReflection <- reactive({
    if (inherits(data, "networkDynamic"))
      return(rep(NA,length(get.edge.activity(data, as.spellList = TRUE)$tail)))
    
    if (is.null(input$edge) || input$edge == "None")
      return(rep(NA, ecount(data)))
    
    if (input$edge == "weight")
      return(E(data)$weight)

    if (input$edge == "betweenness")
      return(edge.betweenness(data))
    
    return(rep(NA, ecount(data)))
  })
  
  output$mainnet <- reactive({
    
    if (inherits(data, "igraph"))
    {
      if (is.null(rownames(get.adjacency(data))))
        nodes <- seq(1, nrow(get.adjacency(data)))
      else 
        nodes <- rownames(get.adjacency(data))
      connections <- get.edgelist(data)
      connectionsIdx <- matrix(nrow = nrow(connections), ncol = ncol(connections))
      
      for (i in 1 : nrow(connections))
      {
        # replace names with indexex [required by d3.js]
        sourceIdx <- which(nodes == connections[i,1])
        destIdx <- which(nodes == connections[i,2])
        
        # decrement as javascript counts from 0, not 1
        connectionsIdx[i,1] <- sourceIdx - 1
        connectionsIdx[i,2] <- destIdx - 1
      }
    }
    if (inherits(data, "networkDynamic"))
    {
      nodes <- network.vertex.names(data)
      connectionsIdx <- as.matrix(get.edge.activity(data, as.spellList = TRUE)[c("onset", "terminus", "tail", "head")])
    }
    
    # what edges should reflect
    edges_property <- matrix(edgesReflection())
    
    # bind edges with edges property
    connectionsIdx <- cbind(connectionsIdx, edges_property)
    if (inherits(data, "igraph")) colnames(connectionsIdx) <- c("source","target", "property")
    if (inherits(data, "networkDynamic")) colnames(connectionsIdx) <- c("onset", "terminus", "source", "target", "property")
    
    if (inherits(data, "igraph"))
    {
      # full vertices data for tooltips
      v_attributes <- igraph::vertex.attributes(data)
      v_attributes$Closeness <- as.vector(closeness(data))
      v_attributes$Betweenness <- as.vector(betweenness(data))
      v_attributes$Degree <- as.vector(degree(data))
    }

    v_attributes <- list()
    
    if (inherits(data, "networkDynamic"))
    {
      for (i in network::list.vertex.attributes(data))
      {
        v_attributes[[paste(i)]] <- network::get.vertex.attribute(data, paste(i))
      }
    }
    # full edges data
    #e_attributes <- edge.attributes(data)
    #e_attributes$Betweenness <- as.vector(edge.betweenness(data))
    
    if (inherits(data, "networkDynamic")) 
    {
      dir = network::is.directed(data)
      if (is.null(input$time)) timestamp <- get.change.times(data)[1]
        else timestamp <- input$time
      # d3 graph properties
      d3properties <- matrix(c(input$charge,
                               input$linkDistance, 
                               input$linkStrength,
                               input$vertexSize[1],
                               input$vertexSize[2],
                               as.numeric(dir),
                               as.numeric(timestamp)), ncol = 7)
      colnames(d3properties) <- c("charge", "linkDistance", "linkStrength", "vertexSizeMin", 
                                  "vertexSizeMax", "directed", "time")
    }
    if (inherits(data, "igraph")) 
    {
      dir = igraph::is.directed(data)
      # d3 graph properties
      d3properties <- matrix(c(input$charge,
                               input$linkDistance, 
                               input$linkStrength,
                               input$vertexSize[1],
                               input$vertexSize[2],
                               as.numeric(dir)), ncol = 6)
      colnames(d3properties) <- c("charge", "linkDistance", "linkStrength", "vertexSizeMin", 
                                  "vertexSizeMax", "directed")
    }
    
    
    if (inherits(data, "igraph")) type <- "igraph"
    if (inherits(data, "networkDynamic")) type <- "networkDynamic"
    
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
})
