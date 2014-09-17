#' Visualizing networks using Shiny and D3.js
#'
#' Framework for creating Shiny applications for static and dynamic network
#' visualizations using D3.js JavaScript library.
#'
#' The package relies on an interactive SVG graph showing the network with
#' force-directed placement. The vertices and and edges can be dragged around
#' to modify the layout. Vertex- and edge-level attributes can be shown using
#' vertex color and size, edge width, and dynamic tooltips.
#'
#' The package enables to visualize both static network data (currently objects
#' of class "igraph" or "network") and dynamic network data (objects of class
#' "networkDynamic", currently experimental feature).
#'
#' The graph is zoomable. The graph itself is also zoomable. For dynamic networks, player
#' controls has been provided.
#'
#' @seealso
#' \code{\link{d3net}}
#'
#' @name d3net-package
#' @import shiny
#' @author
#' Michal Bojanowski \email{michal2992@@gmail.com},
#' Monika Pawluczuk \email{pawluczuk.monika@@gmail.com}
#' @docType package
#' @seealso \url{http://d3js.org}
NULL
