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
    # "Universita Firenze"
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
    # st_point(c(11.2452, 43.8005))
  ),
  crs = 4326
)
save(pois, file = 'data/pois.rda')
