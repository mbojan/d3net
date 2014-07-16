library(igraph)
library(igraphdata)

shinyServer(function(input, output) {
  output$rplot <- renderPlot({
    plot(karate)
  })
  
  output$pngDownload <- downloadHandler(
    filename = function() {
      paste('data-', Sys.Date(), '.png', sep='')
    },
    content = function(file) {
      png(file)
      plot(karate)
      dev.off()
    }
  )
  
  output$pdfDownload <- downloadHandler(
    filename = function() {
      paste('data-', Sys.Date(), '.pdf', sep='')
    },
    content = function(file) {
      pdf(file)
      plot(karate)
      dev.off()
    }
  )
  
  output$mainnet <- reactive({
    nodes <- rownames(get.adjacency(karate))
    connections <- get.edgelist(karate)
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
    
    connectionsIdx <- cbind(connectionsIdx, E(karate)$weight)
    colnames(connectionsIdx) <- c("source","target", "weight")
    
    graphData <- list(names=nodes,links=connectionsIdx)
    graphData
  })
})
