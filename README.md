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
        unlink("devtools.zip")
        ```
## Package functions

Currently methods are implemented for objects of class "igraph", "network" and "networkDynamic".

To launch application:
`d3net(dataset)` where `dataset` is R igraph, network or networkDynamic object