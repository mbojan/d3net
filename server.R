data <- .d3net.dataset

shinyServer(function(input, output) {
  if (class(data) != 'igraph') stop()
  output$rplot <- renderPlot({
    plot(data)
  })
  
  characterChoices <- list()
  numericChoices <- list()
  
  for (i in names(vertex.attributes(data)))
  {
    temp_col <- vertex.attributes(data)[[paste(i)]]
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
  
  output$tooltipAttr <- renderUI({
      selectInput("tooltipAttr",
                  label = "Tooltip information",
                  choices = c("Degree", "Betweenness", "Closeness",names(vertex.attributes(data))),
                  selected = "None",
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
  
  edgesReflection <- reactive({
    if (input$edge == "weight")
      {
        if (is.weighted(data))
          return(E(data)$weight)
        else
          return(rep(NA, ecount(data)))
      }
    if (input$edge == "betweenness")
      return(edge.betweenness(data))
    else
      return(rep(NA, ecount(data)))
  })
  
  vertexColor <- reactive ({
    if (!is.null(input$vertexColor) && input$vertexColor != "None")
      return(vertex.attributes(data)[[paste(input$vertexColor)]])
    else
      return(rep(NA, vcount(data)))
  })
  
  vertexRadius <- reactive ({
    if (is.null(input$vertexRadius))
      return(rep(NA, vcount(data)))
    if (!is.null(vertex.attributes(data)[[paste(input$vertexRadius)]]))
      return(vertex.attributes(data)[[paste(input$vertexRadius)]])
    if (input$vertexRadius == "Closeness")
      return(closeness(data))
    if (input$vertexRadius == "Degree")
      return(degree(data))
    if (input$vertexRadius == "Betweenness")
      return(betweenness(data))
    else
      return(rep(NA, vcount(data)))
  })
  
  output$mainnet <- reactive({
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
    
    # what edges should reflect
    edges_property <- matrix(edgesReflection())
    # what nodes radius should reflect
    nodes_property <- matrix(vertexRadius())
    # what nodes color should reflect
    nodes_color <- matrix(vertexColor())
    
    # bind edges with edges property
    connectionsIdx <- cbind(connectionsIdx, edges_property)
    colnames(connectionsIdx) <- c("source","target", "property")
    
    # bind vertices with vertices property
    nodes <- cbind(nodes, nodes_property, nodes_color)
    colnames(nodes) <- c("vertex", "property", "color")
   
    # full vertices data for tooltips
    attributes <- vertex.attributes(data)
    attributes$Closeness <- as.vector(closeness(data))
    attributes$Betweenness <- as.vector(betweenness(data))
    if (is.weighted(data))
      attributes$Weight <- as.vector((E(data)$weight))
    
    # d3 graph properties
    d3properties <- matrix(c(input$charge,
                             input$linkDistance, 
                             input$linkStrength,
                             input$vertexSize[1],
                             input$vertexSize[2],
                             as.numeric(is.directed(data))), ncol = 6)
    
    colnames(d3properties) <- c("charge", "linkDistance", "linkStrength", "vertexSizeMin", 
                                "vertexSizeMax", "directed")
    graphData <- list(vertices = nodes, # vertices
                      links = connectionsIdx, # edges
                      tooltipInfo = as.list(input$tooltipAttr), # list of attributes' names for tooltip
                      vertexRadius = input$vertexRadius, # attribute that vertex radius should reflect
                      vertexColor = input$vertexColor, # attribute that vertex color should reflect
                      verticesAttributes = attributes, # attributes data
                      d3 = d3properties)
    graphData
  })
})
