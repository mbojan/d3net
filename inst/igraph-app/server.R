############################
#### IGRAPHS & NETWORKS ####
############################
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
  
  names_vertex_attributes <- names(igraph::vertex.attributes(data))
  for (i in names_vertex_attributes)
  {
    temp_col <- igraph::vertex.attributes(data)[[paste(i)]]
    
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
      l <- c("Degree", "Betweenness", "Closeness", names(igraph::vertex.attributes(data)))  
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
    selectInput("vertexRadius", 
                label = "Vertices radius reflect", 
                choices = c("None", "Degree", "Betweenness", "Closeness", numericChoices),
                selected = "None")
  })
  
  edgesReflection <- reactive({
    
    if (is.null(input$edge) || input$edge == "None")
      return(rep(NA, ecount(data)))
    
    if (input$edge == "weight")
      return(E(data)$weight)

    if (input$edge == "betweenness")
      return(edge.betweenness(data))
    
    return(rep(NA, ecount(data)))
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
      
      # decrement indexes as javascript counts from 0, not 1
      connectionsIdx[i,1] <- sourceIdx - 1
      connectionsIdx[i,2] <- destIdx - 1
    }
    
    # what edges should reflect
    edges_property <- matrix(edgesReflection())
    
    # bind edges with edges property
    connectionsIdx <- cbind(connectionsIdx, edges_property)
    colnames(connectionsIdx) <- c("source","target", "property")
    # full vertices data for tooltips
      v_attributes <- igraph::vertex.attributes(data)
      v_attributes$Closeness <- as.vector(closeness(data))
      v_attributes$Betweenness <- as.vector(betweenness(data))
      v_attributes$Degree <- as.vector(degree(data))

    # full edges data
    #e_attributes <- edge.attributes(data)
    #e_attributes$Betweenness <- as.vector(edge.betweenness(data))
    dir = igraph::is.directed(data)
    # d3 graph properties
    d3properties <- matrix(c(input$charge,
                             input$linkDistance, 
                             input$linkStrength,
                             input$vertexSize[1],
                             input$vertexSize[2],
                             input$colorScale,
                             as.numeric(dir)), ncol = 7)
    colnames(d3properties) <- c("charge", "linkDistance", "linkStrength", "vertexSizeMin", 
                                "vertexSizeMax", "color", "directed")
    
    type <- "igraph"
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
