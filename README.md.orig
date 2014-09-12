<<<<<<< HEAD
#d3net

Framework for creating Shiny applications for network visualization using D3.js JavaScript library.

## Updating to the latest version of d3net

You can download `d3net` package at https://github.com/mbojan/d3net. To install it:

1. Install the release version of `devtools` from CRAN with `install.packages("devtools")`.

2. Follow the instructions below depending on platform.

    * **Mac and Linux**:

        ```R
        devtools::install_github("mbojan/d3net")
        ```

    * **Windows**:

        ```R
        library(devtools)
        build_github_devtools()

        #### Restart R before continuing ####
        install.packages("d3net.zip", repos = NULL)

        # Remove the package after installation
        unlink("d3net.zip")
        ```
        
## Package functions

Currently methods are implemented for objects of class "igraph", "network" and "networkDynamic".

To launch application:
```R
library(d3net)
d3net(dataset)
```
where `dataset` is R igraph, network or networkDynamic object

## Examples

To launch examples, use the example datasets provided for each object type.

igraph

```R
library(igraphdata)
data(karate)
d3net(karate)
```

--------

network

```R
library(network)
data(flo)
#create network object from sample data
nflo <- network(flo, directed = FALSE)
d3net(nflo)
```

--------

networkDynamic

```R
library(networkDynamicData)
data(harry_potter_support)
d3net(harry_potter_support)
```

## See also
* [D3.js library](www.d3js.org)
* [Shiny framework](www.shiny.rstudio.com)
=======
d3net
=====

Framework for creating Shiny applications for network visualization using d3js
>>>>>>> 0edffe4e748e4ebd8989b7b262faefa1826d1151
