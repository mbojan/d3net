library(igraph)
library(igraphdata)
data <- karate

shinyServer(function(input, output) {
  #if (class(data) != 'igraph') stop()
  output$rplot <- renderPlot({
    #plot(data)
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
  
  verticesReflection <- reactive({
    if (input$vertex == "degree")
      return(degree(data))
    if (input$vertex == "betweenness")
      return(betweenness(data))
    if (input$vertex == "closeness")
      return(closeness(data))
    else
      return(rep(NA, length(degree(data))))
  })
  
  edgesReflection <- reactive({
    if (input$edge == "weight")
      return(E(data)$weight)
    if (input$edge == "betweenness")
      return(edge.betweenness(data))
    else
      return(rep(NA, length(E(data)$weight)))
  })
  
  output$mainnet <- reactive({
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
    # what vertices should reflect
    nodes_property <- matrix(verticesReflection())
    
    # bind edges with edges property
    connectionsIdx <- cbind(connectionsIdx, edges_property)
    colnames(connectionsIdx) <- c("source","target", "property")
    
    # bind vertices with vertices property
    nodes <- cbind(nodes, nodes_property)
    colnames(nodes) <- c("vertex", "property")
   
    # full vertices data for tooltips
    nodesdata <- cbind(degree(data), betweenness(data), closeness(data))
    colnames(nodesdata) <- c("degree", "betweenness", "closeness")
    
    graphData <- list(vertices = nodes, # vertices
                      links = connectionsIdx, # edges
                      verticesTooltip = nodesdata) # data for vertices tooltip
    graphData
  })
})
