#============================================================================ 
# Here we describe all features which are generic irrespective of the method
# used (class of `dataset`)
#============================================================================ 
#
#' Launching d3net Shiny apps
#' 
#' Launch a Shiny application providing an interactive visualisation of static
#' or dynamic network data.
#'
#' @param dataset R object containing (dynamic) network data. See Usage and Details
#' for description of available methods.
#'
#' @param ... other arguments passed to/from other methods
#'
#' @details
#' Generic details first.
#'
#' d3js-specific
#'
#' Graph layout has some predefined properties that can be changed
#' through the controls in the app.  See sections below for more information.
#' To launch the shiny app use functions described below. 
#'
#' TODO describe all d3 properties in detail.
#' 
#' Link distance, charge and vertex size are calculated depending on total
#' number of nodes.
#' 
#' # how R vertex/edge attributes are handled
#'
#' Vertices and edges properties of the visualised object can be reflected as
#' well.  Controls in \code{R properties} section enable this.  Logical and
#' character network's vertices properties can be reflected by color nodes,
#' numeric ones by the size of the node. Edge properties can be reflected by
#' edge thickness.  All of the available properties may be added to the tooltip
#' information, which is shown on node mouseover.
#'
#' @note
#'
#' (TODO non-usage-specific notes, e.g. performance etc.)
#'
#' For visualisations with large number of vertices, nodes size can be pretty
#' small.  For this reason, there is a zooming control that lets you change the
#' scale.  You can also move the whole graph in every direction.  As gestures
#' may be interferring with the dragging, it's not possible to drag the nodes
#' when zooming is on.
#'
#' @export
#' @import shiny
d3net <- function(dataset, ...) {
  UseMethod("d3net", dataset)
}

#' @method d3net default
#' @rdname d3net
#' @export
d3net.default <- function(dataset, ...)
{
  stop(paste("no 'd3net' method for objects of class", class(dataset)))
}
