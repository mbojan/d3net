# Check if `x` is a list of network/igraph objects

is_network_list <- function(x) {
  if( !inherits(x, "list") ) return(FALSE)
  cls <- vapply(x, data.class, character(1))
  any(cls != "igraph") | any(cls != "network")
}