#' Creates a Markdown link when the URL is available.
#'
#' @param text Text to display.
#' @param url Optional URL. When NULL, NA, or empty, the text is returned as is.
#'
#' @return Text, optionally formatted as a Markdown link.
committee_link <- function(text, url = NULL) {
  if (is.null(url) || length(url) == 0 || is.na(url) || !nzchar(url)) {
    return(text)
  }

  sprintf("[%s](%s)", text, url)
}

#' Formats an advisory board member as a Markdown list item.
#'
#' @param member List with `name`, `affiliation`, and `url`.
#'
#' @return Markdown list item.
format_advisory_board_member <- function(member) {
  sprintf(
    "- %s — %s",
    committee_link(member$name, member$url),
    member$affiliation
  )
}

#' Formats a local committee member as a Markdown list item.
#'
#' Local committee members only have a name and an optional URL. Affiliations
#' are not supported for this section.
#'
#' @param member Member name, or a list with `name` and `url`.
#'
#' @return Markdown list item.
format_local_committee_member <- function(member) {
  if (is.list(member)) {
    name <- member$name
    url <- member$url
  } else {
    name <- member
    url <- NULL
  }

  paste0("- ", committee_link(name, url))
}

#' Renders the advisory board as a Markdown list.
#'
#' @param data Data frame with `name`, `affiliation`, and `url` columns.
#'
#' @return Markdown list printed to the console.
render_advisory_board <- function(data) {
  members <- lapply(seq_len(nrow(data)), function(i) {
    list(
      name = data$name[[i]],
      affiliation = data$affiliation[[i]],
      url = data$url[[i]]
    )
  })

  lines <- vapply(members, format_advisory_board_member, character(1))

  cat(paste(lines, collapse = "\n"), "\n")
}

#' Renders local committees as a three-column grid.
#'
#' The input is a named list where each name is a city and each element is a
#' list of members. Each member can be a name or a list with `name` and `url`.
#'
#' @param committees Named list of cities and their committee members.
#'
#' @return Markdown grid printed to the console.
render_local_committees <- function(committees) {
  cat("::: {.grid}\n\n")

  for (city in names(committees)) {
    cat("::: {.g-col-4}\n")
    cat(sprintf("### %s\n\n", city))

    lines <- vapply(
      committees[[city]],
      format_local_committee_member,
      character(1)
    )
    cat(paste(lines, collapse = "\n"), "\n")

    cat(":::\n\n")
  }

  cat(":::\n")
}
