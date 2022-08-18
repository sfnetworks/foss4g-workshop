# 0 - Packages and options -------------------------------------------------
library(sf)
library(tidygraph)
library(sfnetworks)
library(osmextract)
library(mapview)
library(ggplot2)
mapviewOptions(basemaps = "OpenStreetMap.HOT", viewer.suppress = TRUE)
options(sfn_max_print_inactive = 6L)

# 1 - OSM data -------------------------------------------------------------

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

# Unfortunately, due to the cropping operations, we need to slightly tweak the
# output before proceeding with the next steps.
street_segments <- st_cast(street_segments, "LINESTRING")

# Let's plot it! 
par(mar = rep(0, 4))
plot(st_boundary(st_geometry(firenze)), lwd = 2)
plot(st_geometry(street_segments), add = TRUE, col = grey(0.8))

# We can clearly notice the shape of the river (Arno) and the railway (i.e. the
# white polygon in the middle of the map). An interactive visualisation can be
# derived as follows:
mapview(st_geometry(street_segments))

# 2 - The sfnetwork data structure -----------------------------------------

# Now we can finally convert the input segments into a sfnetwork object. For
# simplicity, we will consider an undirected network (which may also be a
# reasonable assumption for a walking mode of transport).
sfn <- as_sfnetwork(street_segments, directed = FALSE)

# Print the output
sfn

# Some comments: 
# 
# 1) The first line reports the number of nodes and edges;
# 2) The second line displays the CRS (Coordinate Reference System);
# 3) The third line briefly describe the sfnetwork object;
# 4) The following text shows the active geometry object, while the last block
# is related to the inactive geometry. The two tables are stored as sf objects.

# In fact, a sfnetwork is a multitable object in which the core network elements
# (i.e. nodes and edges) are embedded as sf objects. However, thanks to the neat
# structure of tidygraph, there is no need to first extract one of those
# elements before you are able to apply your favourite sf predicates or
# tidyverse verbs. Instead, there is always one element at a time labelled as
# active. This active element is the target of data manipulation. The active
# element can be changed with the activate() verb, i.e. by calling
# activate("nodes") or activate("edges"). We will see several examples later on.

# The sfnetwork objects have an ad-hoc plot method
plot(st_boundary(st_geometry(firenze)), lwd = 2)
plot(sfn, add = TRUE, pch = ".", cex = 2, col = grey(0.85))

# Unfortunately, there are so many nodes and edges that it's difficult to
# understand the general structure of the street network. Therefore, let's zoom
# in an area close to Piazza Duomo.

# First, we want to extract the nodes and edges geometry from the active
# geometry table
nodes <- sfn %>% activate("nodes") %>% st_geometry() #  or sfn %N>% st_geometry()
edges <- sfn %E>% activate("edges") %>% st_geometry() # or sfn %E>% st_geometry()

# and then we can plot them as usual
par(mar = rep(2.5, 4))
plot(nodes, axes = TRUE, xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), pch = 20)
plot(edges, add = TRUE, xlim = c(11.24, 11.26), ylim = c(43.76, 43.78))

# A similar operation could also be implemented using coordinate query functions
# and tidygraph verbs:
sfn %N>% 
  filter(
    node_X() > 11.235 & node_X() < 11.265 & 
    node_Y() > 43.760 & node_Y() < 43.780
  ) %>% 
  plot(axes = TRUE)
  
# But how did we derive the network structure? The operation works as follows:
# the input segments represent the edges of the sfnetwork object, while the
# nodes are created at their endpoints. The edges are connected if they share
# one point in the union of their spatial boundaries (i.e. the terminal points).

# 3 - Pre-processing steps -------------------------------------------------

# As we all know, real world data requires several steps before we are able to
# apply our favourite tool for geo-spatial analysis or statistical modelling
# technique. Spatial networks are no exception.

# For this reason, we developed several morphers (i.e. functions to transform
# the network into alternative states) that can be used to clean the network
# after the construction. I will focus on three common tasks: 1) edges
# subdivision; 2) network simplification; 3) smoothing of pseudo nodes.

# > 3.1 - Subdivide edges -------------------------------------------------

# When constructing a sfnetwork from a set of linestrings, the endpoints of
# those linestrings become nodes in the network. If two endpoints are shared
# between multiple lines, they become a single node, and the corresponding edges
# are connected. However, a linestring geometry can also contain interior points
# that define the shape of the line, but are not its endpoints. It can happen
# that such an interior point in one edge is exactly equal to either an interior
# point or endpoint of another edge. In the network structure, however, these
# two edges are not connected, because they don't share endpoints. 

# To see this problem more clearly, we can compute the component of each node
sfn <- sfn %N>% 
  mutate(group_component = group_components())

# And plot it
par(mar = rep(0.5, 4))
layout(matrix(1:2, nrow = 2), heights = c(2.5, 0.5))
plot(
  sfn %E>% st_geometry() , col = "grey", 
  xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), reset = FALSE
)
plot(
  sfn %N>% st_as_sf(), pch  = 20, main = "", 
  xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), add = TRUE
)
.image_scale(
  z = 1:9000, col = sf.colors(9), 
  key.length = 1, key.pos = 1
)

# As we can see, there are several nodes that seem to be connected but belong to
# different components (and this is a really common problem with OSM data). If
# this is unwanted, we need to split these two edges at their shared point and
# connect them accordingly. The "to_spatial_subdivision" morpher can be used
# exactly for this scope.

sfn <- convert(sfn, to_spatial_subdivision, .clean = TRUE)

# Check the printing
sfn
# and we can see there are many more nodes and edges and less components. 

# Let's repeat the previous experiment. 
sfn <- sfn %N>% 
  mutate(group_component = group_components())

dev.off()
par(mar = rep(0.5, 4))
layout(matrix(1:2, nrow = 2), heights = c(2.5, 0.5))
plot(
  sfn %E>% st_geometry() , col = "grey", 
  xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), reset = FALSE
)
plot(
  sfn %N>% st_as_sf(), pch  = 20, main = "", 
  xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), add = TRUE
)
.image_scale(
  z = 1:415, col = sf.colors(9), 
  key.length = 1, key.pos = 1
)

# There is a clearly more coherent structure than before. 

# > 3.2 - Simplify network ------------------------------------------------

# The "to_spatial_simple" morpher can be used to remove multiple edges and loops
# (which might create useless complexities from a routing perspective). The morpher

sfn = convert(sfn, to_spatial_simple)

# Moreover, the morpher has an argument named summarise_attributes that lets you
# specify exactly how you want to merge the attributes of each set of multiple
# edges. We refer to the vignettes for more details. 

# > 3.3 - Smooth pseudo-nodes ---------------------------------------------

# A network may contain nodes that have only one incoming and one outgoing edge.
# For tasks like calculating shortest paths, such nodes are redundant, because
# they don't represent a point where different directions can possibly be taken.
# Sometimes, these type of nodes are referred to as pseudo nodes.

# The "to_spatial_smooth" morpher can be used to remove these redundant nodes: 
sfn = convert(sfn, to_spatial_smooth, .clean = TRUE)

# > 3.4 - Subsetting the main component -----------------------------------

# As we can see from the previous map, it looks like most nodes belong to just
# one component. We can check this hypothesis as follows:
tail(sort(table(igraph::components(sfn)$membership), descending = FALSE))

# Therefore, we can select only the nodes that belong to the main component
# using the appropriate morpher.
sfn = sfn %>% convert(to_components, .select = 1L, .clean = TRUE)

# Let's plot it again: 
dev.off()
par(mar = rep(0, 4))
plot(st_boundary(st_geometry(firenze)), lwd = 2)
plot(sfn, add = TRUE, pch = ".", cex = 2, col = grey(0.85))

# We refer to the introductory vignettes for several more preprocessing steps.

# 4. - Spatial joins and spatial filters ----------------------------------


