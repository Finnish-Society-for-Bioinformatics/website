#' Render the country outlines used by the Bioconductor map
#'
#' @param path Path to the yaml file containing Bioconductor members.
#' @param outline_path Path to the GeoJSON file containing country outlines.
#' @param height Height of the Leaflet widget in pixels.
#'
#' @return A Leaflet HTML widget.
render_bioc_outline <- function(path, outline_path, height = 550) {
  data <- yaml::read_yaml(path)

  members <- dplyr::bind_rows(data$members)

  members$lat <- as.numeric(members$lat)
  members$lon <- as.numeric(members$lon)

  # members <- members[
  #   is.finite(members$lat) & is.finite(members$lon),
  # ]
  outline <- sf::st_read(outline_path, quiet = TRUE) |>
    # Transform lon and lat in degrees since Leaflet expects all
    # coordinates to be in WGS 84 (a.k.a. EPSG:4326) format
    # See https://rstudio.github.io/leaflet/articles/projections.html
    sf::st_transform(4326)

  leaflet::leaflet(
    data = outline,
    width = "100%",
    height = height,
    options = leaflet::leafletOptions(
      scrollWheelZoom = TRUE,
      minZoom = 2,
      maxZoom = 9,
      zoomSnap = 0.25,
      attributionControl = FALSE
    )
  ) |>
    leaflet::addPolygons(
      color = ~ ifelse(finland, "#1a81c2", "#d5d5d5"),
      weight = ~ ifelse(finland, 1.5, 1),
      fillColor = ~ ifelse(finland, "#ffffff", "#ececec"), # Thicker country border
      fillOpacity = 1,
      opacity = 1,
      smoothFactor = 0.5,
      options = leaflet::pathOptions(
        interactive = FALSE
      )
    ) |>
    leaflet::addCircleMarkers(
      data = members,
      lng = ~lon,
      lat = ~lat,
      radius = 7,
      color = "#ffffff",
      weight = 2,
      fillColor = ~ ifelse(
        role == "developer",
        "#8aca25",
        "#3792ad"
      ),
      fillOpacity = 1,
      label = ~name,
      # For clustering of circles if they are close to each other
      clusterOptions = leaflet::markerClusterOptions(
        showCoverageOnHover = FALSE,
        maxClusterRadius = 40,
        spiderfyOnMaxZoom = TRUE,
        # Without this option, one of the names was not showing up
        # when zoomed in
        spiderfyDistanceMultiplier = 2
      )
    ) |>
    leaflet::addControl(
      html = paste0(
        '<a href="https://www.naturalearthdata.com/" ',
        'target="_blank" rel="noopener">Natural Earth</a>'
      ),
      position = "bottomright"
    ) |>
    leaflet::fitBounds(
      lng1 = 19.5,
      lat1 = 59.7,
      lng2 = 31.6,
      lat2 = 70.1
    )
}
