# sfnetworks: Tidy Geospatial Networks in R


<!-- badges: start -->
[![Binder](http://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/sfnetworks/foss4g-workshop/main?urlpath=rstudio)
<!-- badges: end -->

Material for FOSS4G 2022 workshop on tidy spatial network analysis with sfnetworks

- [Abstract](https://talks.osgeo.org/foss4g-2022-workshops/talk/TY9FTW/)

- [Slides](https://sfnetworks.github.io/foss4g-workshop/slides/slides) 

- [Live demo]()

## How to follow the tutorial

### Option 1: Binder

Launch the Binder environment with the badge at the top of the README. This will open an RStudio session where you can follow along. Please be patient, the first time you run in can take a while. 

### Option 2: Docker

You can create a Docker container with all the packages needed. The main pre-requisite is to install Docker if you do not have it already. See instructions for [Windows here](https://docs.docker.com/desktop/windows/install/) and for [Linux here](https://docs.docker.com/engine/install/).

Once you have Docker available, you can clone this repo, navigate to [docker/](docker/) and run:

```
docker build -t sfnetworks .
```

This will build a Docker container based on the [Dockerfile](docker/Dockerfile) in that directory.

Then to start the container for the first time run:

```
bash create_container.sh
```

Make sure to update your working directory to mount a volume with your data. 


### Option 3: You are an R-Spatial user

If this is not your first time doing R-Spatial, it is likely that you already count with all the artillery needed to work with sfnetworks on your local machine. 

If that is the case, you would need to install the following packages:

```
install.packages('dbscan')
install.packages('igraph')
install.packages('tidygraph')
install.packages('TSP')
devtools::install_github('luukvdmeer/sfnetworks')
```
