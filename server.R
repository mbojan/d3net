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
  
  output$mainnet <- reactive(function(){
    lista <- get.edgelist(karate)
    connections = matrix(nrow = nrow(lista), ncol = ncol(lista))
    
    for (i in 1 : nrow(end$links))
    {
      # replace names with indexex [required by d3.js]
      sourceIdx <- which(end$names == end$links[i,1])
      destIdx <- which(end$names == end$links[i,2])
      # decrement as javascript counts from 0, not 1
      connections[i,1] <- sourceIdx - 1
      connections[i,2] <- destIdx - 1
    }
    
    connections <- cbind(connections, E(karate)$weight)
    colnames(connections) <- c("source","target", "weight")
    
    graphData <- list(names=rownames(get.adjacency(karate)),links=connections)
    graphData
  })
})
