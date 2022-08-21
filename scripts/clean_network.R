library(sfnetworks)
library(sf)
library(tidygraph)
library(osmdata) # for getbb function

load('data/florence_stn.rda')


net = as_sfnetwork(florence_stn)
florence_center = getbb(
  'Quartiere 1, Florence, Italy',
  # featuretype = "city",
  format_out = "sf_polygon"
)

net_crop = st_intersection(net, florence_center)
net_crop = net[florence_center, ]

net_clean = net_crop |>
  convert(to_spatial_subdivision, .clean = TRUE) |>
  convert(to_spatial_smooth, .clean = TRUE) |>
  convert(to_spatial_simple, .clean = TRUE)

net_comp = net_clean %>%
  activate("edges") %>%
  mutate(length = edge_length()) %>%
  activate("nodes") %>%
  morph(to_components) %>%
  activate("edges") %>%
  mutate(length_comp = sum(length)) %>%
  unmorph() %>%
  activate("nodes") %>%
  mutate(comp = group_components())

net_filt = net_comp %>%
  activate("edges") %>%
  filter(length_comp > units::as_units(1000, "m")) %>%
  activate("nodes") %>%
  filter(!node_is_isolated())

plot(net_filt, col = 'grey70')
load('data/pois.rda')
plot(pois, add = TRUE, pch = 20, col = "red")

net_new = net_filt %>% st_network_blend(pois)
