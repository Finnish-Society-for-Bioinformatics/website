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

#' Creates a markdown link when the URL is available.
#'
#' @param text Text to display.
#' @param url Optional URL. When NULL or empty, the text is returned as is.
#'
#' @return Text, optionally formatted as a Markdown link.
md_link <- function(text, url = NULL) {
  if (is.null(url) || length(url) == 0 || is.na(url) || !nzchar(url)) {
    return(text)
  }

  sprintf("[%s](%s)", text, url)
}

#' Renders events (BioBeers and BioWebinars) from a YAML file.
#'
#' Webinar entries may optionally include `speaker_url` (ex. speaker website or
#' LinkedIn) and `topic_url`.
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
          sprintf(
            "**Speaker**: %s",
            md_link(item$speaker, item$speaker_url)
          ),
          sprintf("**Affiliation**: %s", item$affiliation),
          sprintf(
            "**Topic**: %s",
            md_link(item$topic, item$topic_url)
          ),
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
