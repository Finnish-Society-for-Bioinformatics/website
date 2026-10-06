#' Renders BioBeer events per city from a YAML file.
#'
#' @param path Path to yaml file with BioBeer events.
#'
#' @return Character vector of events separated by a new line.
render_biobeers <- function(path) {
  biobeers <- yaml::read_yaml(path)$biobeers

  lines <- vapply(
    biobeers,
    function(biobeer) {
      # Use status if event's date/place are still unknown
      if (!is.null(biobeer$status)) {
        return(sprintf("**%s:** %s", biobeer$city, biobeer$status))
      }

      date <- format(as.Date(biobeer$date), "%-d %B %Y")
      weekday <- format(as.Date(biobeer$date), "%A")

      details <- paste(
        paste(date, weekday, biobeer$time, sep = ", "),
        sprintf("@ %s, %s", biobeer$place, biobeer$address)
      )

      sprintf("**%s:** %s", biobeer$city, details)
    },
    character(1)
  )

  paste(lines, collapse = "\n\n")
}
