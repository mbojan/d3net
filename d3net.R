require(shiny) 

d3net <- function(dataset) {
  UseMethod("d3net", dataset)
}

d3net.default <- function(dataset)
{
  print("Invalid arguments. Data should be igraph or networkDynamic class.")
}

d3net.igraph <- function(dataset)
{
  print("Running Shiny App for igraphs...")
  require(igraph)
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp("igraph-app")
}

d3net.networkDynamic <- function(dataset)
{
  print("Running Shiny App for dynamic networks...")
  require(network)
  require(networkDynamic)
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp("network-app")
}

d3net.network <- function(dataset)
{
  print("Running Shiny App for networks...")
  require(network)
  require(igraph)
  dataset <- asIgraph(dataset)
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp("igraph-app")   
}
  