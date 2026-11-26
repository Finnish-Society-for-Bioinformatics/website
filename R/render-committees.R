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

#' Renders an advisory board member's profile icons.
#'
#' LinkedIn and website links are shown as Bootstrap icons.
#'
#' @param member Advisory board member data.
#'
#' @return HTML icon links.
advisory_profile_icons <- function(member) {
  icon_classes <- c(
    linkedin = "bi-linkedin",
    website = "bi-globe"
  )
  icon_labels <- c(
    linkedin = "LinkedIn",
    website = "Website"
  )

  links <- character(0)

  for (field in names(icon_classes)) {
    url <- member[[field]]

    if (is.null(url) || is.na(url) || !nzchar(url)) {
      next
    }

    links <- c(
      links,
      sprintf(
        '<a href="%s" aria-label="%s"><i class="bi %s fs-5"></i></a>',
        url,
        icon_labels[[field]],
        icon_classes[[field]]
      )
    )
  }

  paste0(
    '<div class="d-flex justify-content-center gap-2 mt-2">',
    paste(links, collapse = "\n"),
    "</div>"
  )
}

#' Formats an advisory board member as a card.
#'
#' @param member List with `name`, `affiliation`, `linkedin`, `website`, and
#'   `image`.
#'
#' @return Markdown card.
format_advisory_board_member <- function(member) {
  photo <- ""

  if (!is.null(member$image) && nzchar(member$image)) {
    photo <- sprintf(
      "![](../%s){.board-photo .advisory-photo .mb-3}\n\n",
      member$image
    )
  }

  paste0(
    "::: {.g-col-12 .g-col-md-6 .g-col-lg-4 .text-center}\n\n",
    photo,
    sprintf("**%s**\n\n", member$name),
    sprintf("%s\n\n", member$affiliation),
    advisory_profile_icons(member),
    "\n\n:::\n\n"
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

#' Renders the advisory board as a responsive card grid.
#'
#' @param members List of advisory board members.
#'
#' @return Markdown grid printed to the console.
render_advisory_board <- function(members) {
  cards <- vapply(members, format_advisory_board_member, character(1))

  cat("::: {.grid}\n\n")
  cat(cards, sep = "")
  cat(":::\n\n")
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
