script <- function(dataset, ...) {
  require(shiny)
  if (inherits(dataset, "igraph"))
    require(igraph)
  if (inherits(dataset, "networkDynamic"))
  {
    require(network)
    require(networkDynamic)
  }
  
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp()
}