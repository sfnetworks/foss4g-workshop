library(dplyr)
library(osmextract)
library(osmdata)
library(sf)

# Obtain Florence highways from OSM
duomo =  c( 11.2560, 43.7734)

florence_info = oe_match(duomo)
oe_download(
  file_url = florence_info$url,
  file_size = florence_info$file_size,
  download_directory = "data/"
)
italy_pbf = "data/geofabrik_centro-latest.osm.pbf"
florence = getbb(
  'Florence, Italy',
  featuretype = "city",
  format_out = "sf_polygon"
)
extra_tags_ls =  c("bicycle", "foot", "access",
                   "surface", "oneway", "maxspeed",
                   "tunnel", "bridge")
florence_lines = oe_vectortranslate(
  italy_pbf,
  layer = 'lines',
  extra_tags = extra_tags_ls,
  boundary = florence,
  boundary_type = "spat"
)


# Create a LINESTRING sf object with selected columns and correct encoding
# Crear un objeto sf LINESTRINGS con una selección de columnas y corrección
# de codificación
florence_gpkg = "data/geofabrik_centro-latest.gpkg"
florence_stn = oe_read(florence_gpkg) %>% 
  select(name, highway, all_of(extra_tags_ls))

# Save as .rda file
# Guardar datos como .rda
save(florence_stn, file = 'data/florence_stn.rda')
