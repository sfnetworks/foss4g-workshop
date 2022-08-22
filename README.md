# sfnetworks: Tidy Geospatial Networks in R

<!-- badges: start -->

[![Binder](http://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/sfnetworks/foss4g-workshop/main?urlpath=rstudio)

<!-- badges: end -->

Material for FOSS4G 2022 workshop on tidy spatial network analysis with sfnetworks

-   [Abstract](https://talks.osgeo.org/foss4g-2022-workshops/talk/TY9FTW/)

-   [Slides](https://sfnetworks.github.io/foss4g-workshop/slides/slides)

-   [`sfnetworks` repo](https://github.com/luukvdmeer/sfnetworks)

-   [Live demo](scripts/demo.R)

## How to follow the tutorial

### Option 1: Binder

Launch the Binder environment with the badge at the top of the README.
This will open an RStudio session where you can follow along.
Please be patient, the first time you run in can take a while.

### Option 2: Docker

You can create a Docker container with all the packages needed.
The main pre-requisite is to install Docker if you do not have it already.
See instructions for [Windows here](https://docs.docker.com/desktop/windows/install/) and for [Linux here](https://docs.docker.com/engine/install/).

Once you have Docker available, you can clone this repo, navigate to [docker/](docker/) and run:

    docker build -t sfnetworks .

This will build a Docker container based on the [Dockerfile](docker/Dockerfile) in that directory.

Then to start the container for the first time run:

    cd ..
    bash ./docker/create_container.sh

#### Troubleshoot - Windows:

-   You might need to run `sh ./docker/create_container.sh`

-   Make sure to update your working directory to mount a volume to the current directory inside **create_container.sh**, specifically this line: `-v CHANGE_DIR_HERE://home/rstudio/workdir \`.
    Note the extra `/` before home.

### Option 3: On your local machine

If this is not your first time doing R-Spatial, it is likely that you already have all the artillery needed to work with sfnetworks on your local machine.

Even if you are new to R, you can run all the code presented in this tutorial on your laptop.
To do so, you need to install R and RStudio, from the following links:

-   Install R: <https://cran.r-project.org/>
-   Install RStudio: <https://www.rstudio.com/products/rstudio/download/#download>

After you have installed R and RStudio, install the following packages:

    install.packages('dbscan')
    install.packages('igraph')
    install.packages('mapview')
    install.packages('tidygraph')
    install.packages('TSP')
    install.packages('tidyverse')
    devtools::install_github('luukvdmeer/sfnetworks')
    devtools::install_github('ropensci/osmextract')

## Question or problems?

If you have any question related to running this tutorial, please [open an issue here](https://github.com/sfnetworks/foss4g-workshop/issues/new).

If you have been using sfnetworks already and have an interesting problem to discuss, you can [go to our Discussions tab of the package here](https://github.com/luukvdmeer/sfnetworks/discussions).
