# 0 - Packages and options -------------------------------------------------
library(sf)
library(tidygraph)
# Install with: devtools::install_github('luukvdmeer/sfnetworks')
library(sfnetworks)
# Install with: devtools::install_github('ropensci/osmextract')
library(osmextract)
library(mapview)
library(grid)
library(ggplot2)
library(emoji)
library(purrr)
mapviewOptions(basemaps = "OpenStreetMap.HOT", viewer.suppress = TRUE)
options(sfn_max_print_inactive = 6L)

# 1 - OSM data -------------------------------------------------------------

# Get OSM polygonal data for the city of Florence
firenze <- oe_get_boundary("Toscana", "Firenze", extra_tags = "name:en")

# Check the output
firenze[, c(1, 3, 7, 25)]

# For simplicity, we will focus only on the city of Florence (instead of the
# complete metropolitan area)
firenze <- firenze[2, ]

# Now we can download and extract the street segments of the city according to a
# "walking" mode of transport.
street_segments_firenze <- oe_get_network(
  place = "Toscana", 
  mode = "walking", 
  boundary = firenze, 
  boundary_type = "clipsrc", 
  vectortranslate_options = c(
    "-select", "name,highway",
    "-nlt", "PROMOTE_TO_MULTI" 
  )
)

# Print the output
street_segments_firenze

# Unfortunately, due to the cropping operations, we need to slightly tweak the
# output before proceeding with the next steps.
street_segments_firenze <- st_cast(street_segments_firenze, "LINESTRING")

# Let's plot it! 
par(mar = rep(0, 4))
plot(st_geometry(street_segments_firenze), reset = FALSE, col = grey(0.8))
plot(st_boundary(st_geometry(firenze)), lwd = 2, add = TRUE)

# We can clearly notice the shape of the river (Arno) and the railway (i.e. the
# series of white polygon in the middle of the map). An interactive
# visualisation can be derived as follows:
mapview(st_geometry(street_segments_firenze))

# 2 - The sfnetwork data structure -----------------------------------------

# Now we can finally convert the input segments into a sfnetwork object. For
# simplicity, we will consider an undirected network (which may also be a
# reasonable assumption for a walking mode of transport).
sfn_firenze <- as_sfnetwork(street_segments_firenze, directed = FALSE)

# Print the output
sfn_firenze

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
# active. This active element is the target of the data manipulation. The active
# element can be changed with the activate() verb, i.e. by calling
# activate("nodes") or activate("edges"). We will see several examples later on.

# The sfnetwork objects have an ad-hoc plot method
plot(sfn_firenze, reset = FALSE, pch = ".", cex = 2, col = grey(0.85))
plot(st_boundary(st_geometry(firenze)), lwd = 2, add = TRUE)

# Unfortunately, there are so many nodes and edges that it's difficult to
# understand the general structure of the street network. Therefore, let's zoom
# into an area close to Piazza Duomo.

# First, we want to extract the nodes and edges geometry from the active
# geometry table: 

nodes <- sfn_firenze %>% activate("nodes") %>% st_geometry() 
# or, equivalently, nodes <- sfn_firenze %N>% st_geometry()

edges <- sfn_firenze %E>% activate("edges") %>% st_geometry() 
# or, equivalently, sfn_firenze %E>% st_geometry()

# and then we can plot them as usual
par(mar = rep(2.5, 4))
plot(nodes, axes = TRUE, xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), pch = 20)
plot(edges, add = TRUE, xlim = c(11.24, 11.26), ylim = c(43.76, 43.78))

# A similar operation could also be implemented using coordinate query functions
# and tidygraph verbs:
sfn_firenze %N>% 
  filter(
    node_X() > 11.235 & node_X() < 11.265 & 
    node_Y() > 43.760 & node_Y() < 43.780
  ) %>% 
  plot(axes = TRUE)
  
# But how did we derive the network structure? The operation works as follows:
# the input segments represent the edges of the sfnetwork object, while the
# nodes are created at their endpoints. Two distinct edges are connected if they
# share one point in the union of their spatial boundaries (i.e. the terminal
# points).

# 3 - Pre-processing steps -------------------------------------------------

# As we all know, real world data requires several steps before we are able to
# apply our favourite tool for geo-spatial analysis or statistical modelling
# technique. Spatial networks represent no exception.

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

# To see this problem more clearly, we can compute the components membership of
# each node
sfn_firenze <- sfn_firenze %N>% 
  mutate(group_component = group_components())

# And plot it
par(mar = rep(0.5, 4))
layout(matrix(1:2, nrow = 2), heights = c(2.5, 0.5))
plot(
  sfn_firenze %E>% st_geometry() , col = "grey", 
  xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), reset = FALSE
)
plot(
  sfn_firenze %N>% st_as_sf(), pch  = 20, main = "", 
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

sfn_firenze <- convert(sfn_firenze, to_spatial_subdivision, .clean = TRUE)

# Check the printing
sfn_firenze

# We can see there are many more nodes and edges and less components. 

# Let's repeat the previous experiment. 
sfn_firenze <- sfn_firenze %N>% 
  mutate(group_component = group_components())

dev.off()
par(mar = rep(0.5, 4))
layout(matrix(1:2, nrow = 2), heights = c(2.5, 0.5))
plot(
  sfn_firenze %E>% st_geometry() , col = "grey", 
  xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), reset = FALSE
)
plot(
  sfn_firenze %N>% st_as_sf(), pch  = 20, main = "", 
  xlim = c(11.24, 11.26), ylim = c(43.76, 43.78), add = TRUE
)
.image_scale(
  z = 1:415, col = sf.colors(9), 
  key.length = 1, key.pos = 1
)

# There is a clearly more coherent structure than before. 

# > 3.2 - Simplify network ------------------------------------------------

# The "to_spatial_simple" morpher can be used to remove multiple edges between
# the same nodes and loops (which might create useless complexities from a
# routing perspective): 

sfn_firenze = convert(sfn_firenze, to_spatial_simple)

# Moreover, the morpher has an argument named summarise_attributes that lets you
# specify exactly how you want to merge the attributes of each set of multiple
# edges. We refer to the vignettes for more details. 

# > 3.3 - Smooth pseudo-nodes ---------------------------------------------

# A network may contain nodes that have only one incoming and one outgoing edge.
# For tasks like calculating shortest paths, such nodes are redundant because
# they don't represent a point where different directions can possibly be taken.
# Sometimes, these type of nodes are referred to as pseudo nodes.

# The "to_spatial_smooth" morpher can be used to remove these redundant nodes: 
sfn_firenze = convert(sfn_firenze, to_spatial_smooth, .clean = TRUE)

# > 3.4 - Subsetting the main component -----------------------------------

# As we can see from the previous map, it looks like most nodes belong to just
# one component. We can check this hypothesis as follows:
tail(sort(table(igraph::components(sfn_firenze)$membership), descending = FALSE))

# Therefore, we can select only the nodes that belong to the main component
# using the appropriate morpher.
sfn_firenze = sfn_firenze %>% convert(to_components, .select = 1L, .clean = TRUE)

# Let's plot it again: 
dev.off()
par(mar = rep(0, 4))
sfn_firenze %N>% 
  filter(
    node_X() > 11.235 & node_X() < 11.265 & 
      node_Y() > 43.760 & node_Y() < 43.780
  ) %>% 
  plot()

# We refer to the introductory vignettes for several more preprocessing steps.

# Clear ws 
rm(edges, nodes, street_segments_firenze); gc(full = TRUE)

# 4 - Spatial joins and spatial filters ----------------------------------

# Now we will showcase spatial joins and spatial filters using OSM data extracted
# from the city of Siena. In fact, Siena is a city near Florence "naturally"
# divided into several neighbourhoods (also named "Contrade"). I think it might
# provide an ideal example to showcase these functionalities.

# > 4.1 - Spatial filters -------------------------------------------------

# First, download the boundary data for the "Contrade" and merge them:
contrade <- oe_get(
  "Toscana", 
  query = "
  SELECT name, place, geometry 
  FROM multipolygons 
  WHERE name LIKE 'Contrada%' OR name LIKE 'Contrata%'" 
)
contrade <- st_transform(contrade, 32632)
contrade <- st_buffer(contrade, units::set_units(30, "m"))
contrade_poly <- st_union(st_geometry(contrade))

# One rectangular polygon that will be used in the next part of the code
piazza_campo_poly <- st_sfc(st_polygon(
  x = list(rbind(
    c(11.329, 43.316), c(11.334, 43.316), 
    c(11.334, 43.320), c(11.329, 43.320), 
    c(11.329, 43.316)
  ))
), crs = 4326)
piazza_campo_poly <- st_transform(piazza_campo_poly, 32632)

# Then download the segments
street_segments_siena <- oe_get_network(
  place = "Toscana", 
  mode = "walking", 
  boundary = st_make_valid(contrade_poly), 
  boundary_type = "clipsrc", 
  vectortranslate_options = c(
    "-select", "name",
    "-t_srs", "EPSG:32632",
    "-nlt", "PROMOTE_TO_MULTI" 
  )
)

# And repeat the same steps as before
street_segments_siena <- st_cast(street_segments_siena, "LINESTRING")
sfn_siena <- as_sfnetwork(street_segments_siena, directed = FALSE)
sfn_siena <- sfn_siena %>% 
  convert(to_spatial_subdivision) %>% 
  convert(to_spatial_simple) %>% 
  convert(to_spatial_smooth) %>% 
  convert(to_components, .select = 1L, .clean = TRUE)

# Check the print
sfn_siena

# Let's plot it
par(mar = rep(0, 4))
plot(sfn_siena, reset = FALSE, col = grey(0.4))
plot(st_boundary(st_geometry(contrade_poly)), lwd = 2, add = TRUE)
plot(st_boundary(st_geometry(contrade)), lty = 2, col = "orange", add = TRUE, lwd = 1.25)

# Using the function st_filter, we can select only the nodes that lie inside the
# red polygon displayed below. 
plot(sfn_siena, reset = FALSE, col = grey(0.4))
plot(st_boundary(st_geometry(contrade_poly)), lwd = 2, add = TRUE)
plot(st_boundary(piazza_campo_poly), col = "darkred", add = TRUE, lwd = 2)

sfn_siena_small <- st_filter(activate(sfn_siena, "nodes"), piazza_campo_poly)

# Check the print
sfn_siena_small

# We can also exploit the tidygraph implementation and use the ggplot2 package to
# display the two networks extracting and plotting the nodes and edges table one
# at a time. 
contrade_plot <- ggplot() + 
  geom_sf(data = st_boundary(st_geometry(contrade_poly))) + 
  geom_sf(data = st_boundary(piazza_campo_poly), col = "darkred", linetype = 2, size = 1) + 
  # Extract and plot the edges and nodes table
  geom_sf(data = st_geometry(sfn_siena, "edges"), col = grey(0.5)) + 
  geom_sf(data = st_geometry(sfn_siena, "nodes"), col = grey(0.5)) + 
  theme_minimal() + 
  theme(panel.grid.minor = element_blank())

siena_small_plot <- ggplot() + 
  geom_sf(data = st_boundary(piazza_campo_poly), col = "darkred", linetype = 2, size = 1) + 
  geom_sf(data = st_geometry(sfn_siena_small, "nodes"), col = grey(0.4)) + 
  geom_sf(data = st_geometry(sfn_siena_small, "edges"), col = grey(0.4)) + 
  theme(
    panel.border = element_blank(), panel.background = element_blank(), 
    axis.ticks = element_blank(), axis.text = element_blank()
  )

# The object contrade_plot represent the plot of the whole city, while
# "siena_small_plot" is just the nodes/edges inside the red polygon. We can now
# define the "viewport" of the two figures and represent both of them at the
# same time.
dev.off()
v1 <- viewport(width = 0.85, height = 0.85, x = 0.4, y = 0.5)
v2 <- viewport(width = 0.45, height = 0.45, x = 0.75, y = 0.75)
plot(contrade_plot, vp = v1)
plot(siena_small_plot, vp = v2)
grid.move.to(0.46, 0.47)
grid.line.to(
  x = 0.585, y = 0.75, arrow = grid::arrow(angle = 20), 
  gp = gpar(lwd = 2, col = "darkred")
)

# The same approach can be adopted to filter the nodes inside more complicated
# polygonal structure. For example, the following code filters only the nodes
# inside the "Contrada del Nicchio" (displayed in dark-blue):
contrada_nicchio <- filter(contrade, grepl("Nicchio", name)) 
sfn_siena_nicchio <- st_filter(sfn_siena, contrada_nicchio)

dev.off()
par(mar = rep(0, 4))
plot(sfn_siena, reset = FALSE, col = grey(0.4))
plot(st_boundary(st_geometry(contrade_poly)), lwd = 2, add = TRUE)
plot(st_boundary(st_geometry(contrada_nicchio)), lwd = 2, add = TRUE, lty = 2, col = "blue")
plot(sfn_siena_nicchio, add = TRUE, col = "blue")

# > 4.2 - Spatial joins ---------------------------------------------------

# Information can be spatially joined into a network by using spatial predicate
# functions inside the sf function sf::st_join(), which works as follows: the
# function is applied to a set of geometries A with respect to another set of
# geometries B, and attaches feature attributes from features in B to features
# in A based on their spatial relation.

# For example, we can match each node with the Contrada where they are located: 
sfn_siena <- st_join(sfn_siena, contrade, join = st_intersects)

# Let's see the print
sfn_siena

# Add a plot
ggplot() + 
  geom_sf(data = st_boundary(st_geometry(contrade_poly))) + 
  geom_sf(data = sfn_siena %E>% st_as_sf(), col = grey(0.4)) + 
  geom_sf(data = sfn_siena %N>% st_as_sf(), aes(col = name)) + 
  geom_sf(data = st_boundary(contrade), linetype = 2, col = grey(0.6)) + 
  theme_minimal() + 
  labs(col = "")

# or, in a more playful way, we can also plot each point according to the symbol
# (an emoji, actually) of the Contrade:
siena_name <- sfn_siena %N>% pull(name)
siena_emoji <- dplyr::case_when(
  siena_name == "Contrada del Bruco" ~ emoji::emoji("lady beetle"),
  siena_name == "Contrada del Drago" ~ emoji::emoji("dragon"),
  siena_name == "Contrada del Leocorno" ~ emoji::emoji("unicorn"),
  siena_name == "Contrada del Nicchio" ~  emoji::emoji("shell"),
  siena_name == "Contrada del Valdimontone" ~  emoji::emoji("sheep"),
  siena_name == "Contrada dell'Aquila" ~  emoji::emoji("eagle"),
  siena_name == "Contrada dell'Istrice" ~ emoji::emoji("hedgehog"),
  siena_name == "Contrada dell'Oca" ~ emoji::emoji("duck"),
  siena_name == "Contrada dell'Onda" ~ emoji::emoji("dolphin"),
  siena_name == "Contrada della Chiocciola" ~ emoji::emoji("snail"),
  siena_name == "Contrada della Civetta" ~ emoji::emoji("owl"),
  siena_name == "Contrada della Giraffa" ~ emoji::emoji("giraffe"),
  siena_name == "Contrada della Lupa" ~ emoji::emoji("wolf"),
  siena_name == "Contrada della Pantera" ~ emoji::emoji("cat"),
  siena_name == "Contrada della Selva" ~ emoji::emoji("evergreen tree"),
  siena_name == "Contrada della Tartuca" ~ emoji::emoji("turtle"),
  siena_name == "Contrata della Torre" ~ emoji::emoji("castle"),
  TRUE ~ NA_character_
)
sfn_siena_coords <- sfn_siena %>% st_coordinates() %>% data.frame()

ggplot(sfn_siena_coords) + 
  geom_sf(data = st_boundary(st_geometry(contrade_poly))) + 
  geom_text(aes(X, Y), label = siena_emoji, size = 4.5) + 
  theme_minimal() + 
  theme(axis.title = element_blank(), axis.text = element_blank())

# Clear ws
rm(list = setdiff(ls(), c("firenze", "sfn_firenze"))); gc()

# 5 - Shortest paths and TSP ----------------------------------------------

# Calculating shortest paths between pairs of nodes is a core task in network
# analysis. The sfnetworks package offers wrappers around the path calculation
# functions of igraph, making it easier to use them when working with spatial
# data and tidyverse packages. 

# Now we can showcase some of these functionalities considering the data from
# Florence, but, for simplicity, we will restrict ourself to a smaller street
# network near the city centre.

firenze_buffer <- st_buffer(
  st_sfc(st_point(c(11.25596, 43.76911)), crs = 4326), 
  dist = units::set_units(1.25, "km")
)
sfn_firenze_small <- st_filter(sfn_firenze %>% activate("nodes"), firenze_buffer)

# Now, for a proper spatial routing, we need to add a column of weights (i.e.
# the geographical lengths of the edges) to the sfnetwork data:
sfn_firenze_small = sfn_firenze_small %E>%
  mutate(weight = edge_length())

# The function st_network_paths() is a wrapper around the igraph function
# igraph::shortest_paths(). 
paths = st_network_paths(sfn_firenze_small, from = c(1), to = c(10, 100))
paths

# The output is a tibble with one row per path. Let's check one of them
paths %>% slice(1) %>% pull(node_paths)

# We can easily plot these paths
par(mar = rep(2.5, 4))
cols <- sf.colors(3, categorical = TRUE)
plot_path = function(node_path) {
  sfn_firenze_small %>%
    activate("nodes") %>%
    slice(node_path) %>%
    plot(cex = 1.5, lwd = 1.5, add = TRUE)
}
plot(sfn_firenze_small, axes = TRUE, col = "grey")
paths %>% pull(node_paths) %>% walk(plot_path)
plot(sfn_firenze_small %N>% slice(1), col = cols[1], add = TRUE, pch = 16, cex = 3)
plot(sfn_firenze_small %N>% slice(c(10, 100)), col = cols[2:3], add = TRUE, pch = 16, cex = 3)

# The main advantage of st_network_paths over igraph::distances is that, besides
# node indices, it gives the additional option to provide any (set of)
# geospatial point(s) as from and to location(s) of the shortest paths, either
# as sf or sfc object. 

# Moreover, considering that the smaller city network contains a set of major POI(s)

pois = st_sf(
  poi = c(
    "Palazzo Pitti",
    "Basilica di St. Croce",
    "Duomo",
    "Piazzale Michelangelo",
    "Galleria degli Uffizi",
    "Palazzio Vecchio",
    "Ponte Vecchio",
    "Palazzo Congressi"
  ),
  geometry = st_sfc(
    st_point(c(11.2500, 43.7649)),
    st_point(c(11.2624, 43.7685)),
    st_point(c(11.2560, 43.7734)),
    st_point(c(11.2650, 43.7629)),
    st_point(c(11.2553, 43.7678)),
    st_point(c(11.2562, 43.7694)),
    st_point(c(11.2531, 43.7680)),
    st_point(c(11.2497, 43.7780))
  ),
  crs = 4326
)

ggplot() +
  geom_sf(data = st_geometry(sfn_firenze_small, "nodes"), col = grey(0.8)) + 
  geom_sf(data = st_geometry(sfn_firenze_small, "edges"), col = grey(0.8)) + 
  geom_sf(data = pois, aes(col = poi), size = 4) + 
  theme_minimal() + theme(panel.grid = element_blank(), legend.position = "bottom") + 
  labs(col = "")

# We can calculate the shortest path between some of them using an ad-hoc
# spatial morpher named "to_spatial_shortest_path":
duomo_palazzo_pitti <- sfn_firenze_small %>% 
  convert(
    to_spatial_shortest_paths, 
    from = pois %>% filter(poi == "Duomo"), 
    to = pois %>% filter(poi == "Palazzo Pitti"), 
    .clean = TRUE
  )
duomo_piazzale_michelangelo <- sfn_firenze_small %>% 
  convert(
    to_spatial_shortest_paths, 
    from = pois %>% filter(poi == "Duomo"), 
    to = pois %>% filter(poi == "Piazzale Michelangelo"), 
    .clean = TRUE
  )

# and plot the result

ggplot() +
  geom_sf(data = st_geometry(sfn_firenze_small, "nodes"), col = grey(0.8)) + 
  geom_sf(data = st_geometry(sfn_firenze_small, "edges"), col = grey(0.8)) + 
  geom_sf(data = duomo_palazzo_pitti %E>% st_geometry(), col = "black", size = 2) +
  geom_sf(data = duomo_piazzale_michelangelo %E>% st_geometry(), col = "black", size = 2) + 
  theme_minimal() + theme(panel.grid = element_blank(), legend.position = "bottom") + 
  geom_sf(data = pois, aes(col = poi), size = 4) + 
  labs(col = "")

