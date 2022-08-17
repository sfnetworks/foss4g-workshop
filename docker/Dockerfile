FROM rocker/verse:latest
MAINTAINER Luuk van der Meer <luukvandermeer@live.nl>
  
RUN \
 apt -y update && \
 apt -y upgrade && \
 apt -y install software-properties-common && \
 add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && \
 apt -y update && \
 apt -y install libgdal-dev libgeos-dev libproj-dev libudunits2-dev

RUN R -e "devtools::install_github('r-spatial/sf')"
RUN R -e "devtools::install_github('r-spatial/s2')"
RUN R -e "devtools::install_github('r-spatial/lwgeom')"
RUN R -e "devtools::install_github('rspatial/terra')"
RUN R -e "devtools::install_github('luukvdmeer/sfnetworks')"

RUN install2.r \
 dbscan \
 dodgr \
 igraph \
 mapview \
 microbenchmark \
 osmdata \
 osmextract \
 sfheaders \
 spatstat \
 spatstat.geom \
 spatstat.linnet \
 spdep \
 sfdep \
 stplanr \
 tidygraph \
 tmap \
 TSP \
 units
