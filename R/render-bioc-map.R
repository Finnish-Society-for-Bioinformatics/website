#' Renders the Bioconductor map data from a YAML file.
#'
#' @param path Path to yaml file with members.
#' @param outline_path Path to GeoJSON file with the country outlines drawn as
#'   the base map. The outlines are from Natural Earth (public domain).
#'
#' @return Character string with a script tag that defines the members, the
#'   date of the last update, and the country outlines for the map in
#'   pages/communities/_bioc-map.html.
render_bioc_map <- function(path, outline_path) {
  data <- yaml::read_yaml(path)
  keys <- c(
    "name", "role", "city", "country", "lat", "lon", "affiliation", "github", "linkedin",
    "bluesky", "website"
  )
  members <- lapply(data$members, function(m) m[intersect(keys, names(m))])
  json <- jsonlite::toJSON(
    list(
      updated = data$updated,
      members = members,
      outline = jsonlite::read_json(outline_path)
    ),
    auto_unbox = TRUE, null = "null", digits = NA
  )
  # Prevent closing the script tag from within the data
  json <- gsub("</", "<\\/", json, fixed = TRUE)
  sprintf("<script>window.biocMap = %s;</script>", json)
}
