library(dplyr)
library(osmextract)
library(sf)

# Obtain Florence highways from OSM
duomo =  c( 11.2560, 43.7734)

florence_info = oe_match(duomo)
oe_download(
  file_url = florence_info$url,
  file_size = florence_info$file_size,
  download_directory = "data/"
)
italy_lines = oe_read(
  "data/geofabrik_centro-latest.osm.pbf",
  quiet = FALSE,
  query = "SELECT highway, geometry FROM 'lines'"
)

florence = getbb(
  'Florence, Italy',
  featuretype = "city",
  format_out = "sf_polygon"
)

# Create a LINESTRING sf object with selected columns and correct encoding
# Crear un objeto sf LINESTRINGS con una selección de columnas y corrección
# de codificación
florence_stn = italy_lines %>%
  st_crop(florence) 

# Save as .rda file
# Guardar datos como .rda
save(florence_stn, file = 'data/florence.rda')
