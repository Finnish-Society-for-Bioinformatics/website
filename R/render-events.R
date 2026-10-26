#' Formats a webinar's date, time, and timezone.
#'
#' @param date Date in ISO format (YYYY-MM-DD).
#' @param time Time in 24-hour format (HH:MM).
#' @param tz Timezone name.
#'
#' @return Formatted date and time.
format_datetime <- function(date, time, tz = "Europe/Helsinki") {
  dt <- as.POSIXct(
    paste(date, time),
    format = "%Y-%m-%d %H:%M",
    tz = tz
  )

  label <- paste0(
    format(dt, "%-d %B %Y, %A, %H:%M %Z", tz = tz),
    " (",
    tz,
    ")"
  )
}

#' Renders events (BioBeers and BioWebinars) from a YAML file.
#'
#' @param path Path to yaml file with events.
#' @param type Type of event (biobeers or webinars).
#'
#' @return Character vector of events separated by a new line.
render_events <- function(path, type) {
  # Read yaml file with the correct t ype
  items <- yaml::read_yaml(path)[[type]]

  # Create lines to render
  lines <- vapply(
    items,
    function(item) {
      if (type == "webinars") {
        paste(
          sprintf("**Speaker**: %s", item$speaker),
          sprintf("**Affiliation**: %s", item$affiliation),
          sprintf("**Topic**: %s", item$topic),
          sprintf(
            "**Date**: %s",
            format_datetime(item$date, item$time, item$timezone)
          ),
          sep = "\n\n"
        )
      } else {
        if (!is.null(item$status)) {
          return(sprintf("**%s:** %s", item$city, item$status))
        }

        date <- format(as.Date(item$date), "%-d %B %Y")
        weekday <- format(as.Date(item$date), "%A")

        details <- paste(
          paste(date, weekday, item$time, sep = ", "),
          sprintf("@ %s", item$place)
        )

        sprintf("**%s:** %s", item$city, details)
      }
    },
    character(1)
  )
  paste(lines, collapse = "\n\n")
}
