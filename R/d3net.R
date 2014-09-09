#' Launching Shiny apps
#'
#' Functions to launch the shiny app.
#'
#' @param dataset R object, see Details for available methods
#'
#' Currently methods are implemented for objects of class "igraph", "network",
#' and "networkDynamic".
#'
#' @export
#' @import shiny
d3net <- function(dataset) {
  UseMethod("d3net", dataset)
}

#' @method d3net default
#' @rdname d3net
#' @export
d3net.default <- function(dataset)
{
  stop(paste("no 'd3net' method for objects of class", class(dataset)))
}

#' @method d3net igraph
#' @rdname d3net
#' @import igraph
#' @export
d3net.igraph <- function(dataset)
{
  print("Running Shiny App for igraphs...")
  require(igraph)
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp( system.file("igraph-app", package="d3net") )
}


#' @method d3net networkDynamic
#' @rdname d3net
#' @import networkDynamic
#' @export
d3net.networkDynamic <- function(dataset)
{
  print("Running Shiny App for dynamic networks...")
  require(network)
  require(networkDynamic)
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp( system.file("network-app", package="d3net") )
}


#' @method d3net network
#' @rdname d3net
#' @import intergraph
#' @import network
#' @export
d3net.network <- function(dataset)
{
  print("Running Shiny App for networks...")
  require(network)
  require(igraph)
  dataset <- asIgraph(dataset)
  .GlobalEnv$.d3net.dataset <- dataset
  on.exit(rm(.d3net.dataset, envir=.GlobalEnv))
  shiny::runApp( system.file("igraph-app", package="d3net") )
}
  
