#' Formats a board member field in bold.
#'
#' @param value Field value to format.
#'
#' @return Bold value.
board_bold_line <- function(value) {
  sprintf("**%s**", value)
}

#' Formats the board member's title and affiliation.
#'
#' @param member Board member data.
#'
#' @return Comma-separated title and affiliation.
board_details_line <- function(member) {
  parts <- c(
    member$title,
    member$affiliation
  )
  parts <- parts[!is.na(parts) & nzchar(parts)]

  paste(parts, collapse = ", ")
}

#' Renders the board member's profile icons.
#'
#' LinkedIn, GitHub, and website links are shown as Bootstrap icons.
#'
#' @param member Board member data.
#'
#' @return HTML icon links.
board_profile_icons <- function(member) {
  icon_classes <- c(
    linkedin = "bi-linkedin",
    github = "bi-github",
    website = "bi-globe"
  )
  icon_labels <- c(
    linkedin = "LinkedIn",
    github = "GitHub",
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

#' Renders one board member card.
#'
#' @param member Board member data.
#'
#' @return Markdown card printed to the console.
render_board_member <- function(member) {
  cat("::: {.g-col-12 .g-col-md-6 .g-col-lg-4 .text-center}\n\n")

  if (!is.null(member$image) && nzchar(member$image)) {
    cat(sprintf("![](../%s){.board-photo .mb-3}\n\n", member$image))
  }

  cat(sprintf("%s\n\n", board_bold_line(member$name)))
  cat(sprintf("*%s*\n\n", member$role))

  details <- board_details_line(member)
  if (nzchar(details)) {
    cat(sprintf("%s\n\n", details))
  }

  if (!is.null(member$research_area) && nzchar(member$research_area)) {
    cat(sprintf("%s\n\n", member$research_area))
  }

  cat(sprintf("%s\n\n", board_profile_icons(member)))

  cat(":::\n\n")
}

#' Renders board members using a responsive card grid.
#'
#' @param members List of board members.
#' @param title Title displayed above the cards.
#'
#' @return Markdown grid printed to the console.
render_board_members <- function(members, title = "Board Members") {
  cat("::: {.grid}\n\n")
  cat(sprintf(
    "::: {.g-col-12 .board-title}\n%s\n:::\n\n",
    title
  ))

  for (member in members) {
    render_board_member(member)
  }

  cat(":::\n\n")
}
