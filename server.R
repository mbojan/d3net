library(igraph)
library(igraphdata)
data <- karate

shinyServer(function(input, output) {
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
    #else NA
    #to do - nothing chosen
    else
      return(closeness(data))
  })
  
  edgesReflection <- reactive({
    if (input$edge == "weight")
      return(E(data)$weight)
    if (input$edge == "betweenness")
      return(edge.betweenness(data))
    #else NA
    #to do - nothing chosen
    else
      return(E(data)$weight)
  })
  
  output$mainnet <- reactive({
    nodes <- rownames(get.adjacency(data))
    connections <- get.edgelist(data)
    connectionsIdx <- matrix(nrow = nrow(lista), ncol = ncol(lista))
    
    for (i in 1 : nrow(lista))
    {
      # replace names with indexex [required by d3.js]
      sourceIdx <- which(nodes == connections[i,1])
      destIdx <- which(nodes == connections[i,2])
      # decrement as javascript counts from 0, not 1
      connectionsIdx[i,1] <- sourceIdx - 1
      connectionsIdx[i,2] <- destIdx - 1
    }
    # what edges should reflect
    edgesData <- matrix(edgesReflection())
    # what vertices should reflect
    nodesdata <- matrix(verticesReflection())
    # bind edges with edges property
    connectionsIdx <- cbind(connectionsIdx, edgesData)
    colnames(connectionsIdx) <- c("source","target", "property")
    
    print(nodesdata)
    graphData <- list(names = nodes, # vertices
                      links = connectionsIdx, # edges
                      edgesdata = edgesData, # edges thickness relation matrix
                      linksdata = nodesdata) # vertices size relation matrix
    graphData
  })
})
