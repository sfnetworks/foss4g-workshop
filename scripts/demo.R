# Load relevant packages and adjust options
library(sf)
library(igraph)
library(tidygraph)
library(sfnetworks)
library(osmextract)
library(mapview)
options(sfn_max_print_inactive = 6L)


# Get OSM polygonal data for the city of Florence
firenze <- oe_get_boundary("Toscana", "Firenze", extra_tags = "name:en")

# Check the output
firenze[, c(1, 3, 7, 9, 25)]

# For simplicity, we will focus only on the city of Florence (instead of the
# complete metropolitan area)
firenze <- firenze[2, ]

# Now we can download and extract the street segments of the city according to a
# "walking" mode of transport.
street_segments <- oe_get_network(
  place = "Toscana", 
  mode = "walking", 
  boundary = firenze, 
  boundary_type = "clipsrc", 
  vectortranslate_options = c(
    "-nlt", "PROMOTE_TO_MULTI" 
  )
)

# Print the output
street_segments[, c(2, 3)]

# Unfortunately, due to the cropping operations, we need to slightly tweak the output
# before proceeding with the next steps. 
street_segments <- st_cast(street_segments, "LINESTRING")

# Let's plot it! 
par(mar = rep(0, 4))
plot(st_boundary(st_geometry(firenze)), lwd = 2)
plot(st_geometry(street_segments), add = TRUE, col = grey(0.8))

# We can clearly notice the shape of the river (Arno) and the railway (i.e. the
# white polygon in the middle of the map). An interactive visualisation can be
# derived as follows:
mapview(st_geometry(street_segments))

# Now we can finally convert the input segments into a sfnetwork object. For
# simplicity, we will consider an undirected network (which may be a reasonable
# assumption for a walking mode of transport).
sfn <- as_sfnetwork(street_segments, directed = FALSE)

# Print the output
sfn

# Some comments: 
# 1) The first line reports the number of nodes and edges
# 2) The second line displays the CRS (Coordinate Reference System)
# 3) The third line briefly describe the sfnetwork object
# 4) The following text shows the active geometry object, while the last
# block is related to the inactive geometry.

# In fact, a sfnetwork is a multitable object in which the core network elements
# (i.e. nodes and edges) are embedded as sf objects. However, thanks to the neat
# structure of tidygraph, there is no need to first extract one of those
# elements before begin able to apply your favourite sf predicates or tidyverse
# verbs. We will see several examples in the following part of the code. 

# sfnetwork objects have an ad-hoc plot method
plot(st_boundary(st_geometry(firenze)), lwd = 2)
plot(
  sfn, add = TRUE, pch = ".", cex = 2,
  col = c(rep("black", vcount(sfn)), rep(grey(0.8), ecount(sfn)))
)

# Unfortunately, there are so many nodes and edges that it's difficult to
# understand the general structure of the street network. We can zoom in the
# area close to Piazza Duomo
plot(sfn, axes = TRUE, xlim = c(11.24, 11.26), ylim = c(43.76, 43.78))








