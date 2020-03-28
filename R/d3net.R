#' Launching d3net Shiny apps
#' 
#' Launch a Shiny application providing an interactive visualisation of static
#' or dynamic network data.
#'
#' @param dataset R object providing data, see Details for available methods#'
#' @param ... other arguments passed to/from other methods
#'
#' @details
#' This function launches a Shiny application. Currently there are two
#' applications implemented: for static network data, and for dynamic network
#' data. Which one is launched depends on the class of \code{dataset}.
#'
#' Static and dynamic application have a very similar interface. In the
#' leftmost column you will find a set of sliders with which various layout
#' parameters can be specified. These are mostly specific to the d3 library
#' which is used for network visualization.  See \url{} for explanations.
#'
#' To the right of the sliders there is a column of dropdown lists with which
#' it is possible to assign vertex and edge attributes found in data to various
#' graphical elements.
#'
#' # Layout and other d3 properties
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
#' # Handling vertex and edge attributes
#'
#' To the right of the sliders there are several dropdown lists with which
#' vertex- and edge attributes can be assigned to graphical features like
#' vertex size, vertex color and so on.
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
#' @examples
#' \dontrun{
#' # static network of class 'igraph'
#' data(karate, package="igraphdata")
#' d3net(karate)
#'
#' # static network 2
#' data(flo, package="network")
#' g <- graph.adjacency(flo, mode="directed")
#' d3net(g)
#'
#' # dynamic network
#' data(harry_potter_support, package="networkDynamicData")
#' d3net(harry_potter_support)
#' }
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



#' @method d3net igraph
#' 
#' @rdname d3net
#' @export
d3net.igraph <- function(dataset, ...)
{
  igraphApp(dataset)
}




#' @method d3net network
#'
#' @details
#' If \code{dataset} is of class "network", it is converted to "igraph" object
#' using \code{\link[intergraph]{asIgraph}}.
#'
#' @rdname d3net
#' @export
d3net.network <- function(dataset, ...)
{
  dataset <- intergraph::asIgraph(dataset)
  igraphApp(dataset)
}
