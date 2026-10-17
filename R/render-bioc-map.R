#' Render the country outlines used by the Bioconductor map
#'
#' @param outline_path Path to the GeoJSON file containing country outlines.
#' @param height Height of the Leaflet widget in pixels.
#'
#' @return A Leaflet HTML widget.
# outline <- sf::st_read("data/country_outlines.geojson")
# old <- outline$finland
#
# outline$finland <- tolower(as.character(outline$finland)) %in%
#   c("true", "1", "yes", "finland")
# new <- outline$finland
# identical(old, new)
render_bioc_outline <- function(outline_path, height = 550) {
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
