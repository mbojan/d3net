#' Launching Shiny apps
#' 
#' Launch a Shiny application providing interactive visualisation of a static
#' or dynamic network data.
#'
#' @param dataset R object containing (dynamic) network data. See Usage and Details
#' for description of available methods.
#'
#' Graph layout has some predefined properties that can be changed
#' through the controls in the app.  See sections below for more information.
#' To launch the shiny app use functions described below. 
#' 
#' @section D3.js properties:
#' Link distance, charge and vertex size are calculated depending on total number of nodes.
#' 
#' @section R properties:
#' Vertices and edges properties of the visualised object can be reflected as well.
#' Controls in \code{R properties} section enable this.
#' Logical and character network's vertices properties can be reflected by color nodes, 
#' numeric ones by the size of the node. Edge properties can be reflected by edge thickness.
#' All of the available properties may be added to the tooltip information, 
#' which is shown on node mouseover.
#' 
#' @section Dynamic networks:
#' For dynamic visualisations, user may also set the time interval between each timepoint. 
#' It is by default 3000ms (3s). To play with the visualisation, use the controls below the graph.
#' It is also possible to pause a visualisation and freeze the graph by pressing spacebar.
#' 
#' @section Large networks:
#' For visualisations with large number of vertices, nodes size can be pretty small. 
#' For this reason, there is a zooming control that lets you change the scale. 
#' You can also move the whole graph in every direction. 
#' As gestures may be interferring with the dragging, it's not possible to drag the 
#' nodes when zooming is on.
#' 
#' @note Function transforms network object into igraph object using intergraph.
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
