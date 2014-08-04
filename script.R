script <- function(dataset, ...) {
  require(shiny)
  require(igraph)
  
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp()
}