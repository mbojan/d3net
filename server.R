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
  output$edges <- renderUI({
    if (is.weighted(data)) 
      list <- c("None" = "none","Weight" = "weight", "Betweenness" = "betweenness")
    else
      list <- c("None" = "none","Betweenness" = "betweenness")
    selectInput("edge",
                label = "Edges reflect",
                choices = list)
  })
  
  output$tooltipAttr <- renderUI({
      selectInput("tooltipAttr",
                  label = "Tooltip information",
                  choices = c("Degree", "Betweenness", "Closeness", names(vertex.attributes(data))),
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
       return(E(data)$weight)
    if (input$edge == "betweenness")
      return(edge.betweenness(data))
    else
      return(rep(NA, ecount(data)))
  })
  
  output$mainnet <- reactive({
    if (is.null(rownames(get.adjacency(data))))
      nodes <- seq(1, nrow(get.adjacency(data)))
    else 
      nodes <- rownames(get.adjacency(data))
    
    #colnames(nodes) <- c("vertex")
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
    
    # bind edges with edges property
    connectionsIdx <- cbind(connectionsIdx, edges_property)
    colnames(connectionsIdx) <- c("source","target", "property")
    
   
    # full vertices data for tooltips
    attributes <- vertex.attributes(data)
    attributes$Closeness <- as.vector(closeness(data))
    attributes$Betweenness <- as.vector(betweenness(data))
    attributes$Degree <- as.vector(degree(data))
    
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
