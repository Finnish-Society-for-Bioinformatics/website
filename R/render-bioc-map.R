#' Read the Bioconductor member list
#'
#' @param path Path to the yaml file containing Bioconductor members.
#'
#' @return A list with the `updated` date and a `members` data frame.
read_bioc_members <- function(path) {
  data <- yaml::read_yaml(path)

  members <- dplyr::bind_rows(data$members)

  # To be sure: keep only members with coordinates to avoid issues
  if (nrow(members) > 0) {
    members$lat <- as.numeric(members$lat)
    members$lon <- as.numeric(members$lon)
  }

  list(updated = data$updated, members = members)
}

#' Render the country outlines used by the Bioconductor map
#'
#' @param path Path to the yaml file containing Bioconductor members.
#' @param outline_path Path to the GeoJSON file containing country outlines.
#' @param height Height of the Leaflet widget in pixels.
#'
#' @return A Leaflet HTML widget.
render_bioc_outline <- function(path, outline_path, height = 550) {
  members <- read_bioc_members(path)$members

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

#' Render the list of Bioconductor members shown next to the map
#'
#' The list is plain HTML generated from the same YAML file as the map, so it
#' needs no JavaScript.
#'
#' @param path Path to the yaml file containing Bioconductor members.
#' @param height Height of the panel in pixels. Use the same value as the map
#'   so that the list and the map line up.
#'
#' @return Character string of HTML.
render_bioc_people <- function(path, height = 550) {
  bioc <- read_bioc_members(path)
  members <- bioc$members

  # Only show people that are also on the map
  if (nrow(members) > 0) {
    members <- members[
      is.finite(members$lat) & is.finite(members$lon),
      ,
      drop = FALSE
    ]
  }

  panel <- function(...) {
    # Create the panels of Bioconductor members to the left of the map
    htmltools::tags$div(
      class = "bioc-people",
      style = sprintf("--bioc-panel-height: %dpx", height),
      ...
    )
  }

  # Use different colors for developers and users
  # Colors are defined in styles.scss
  role_label <- c(user = "User", developer = "Developer")
  role_class <- c(
    user = "bioc-role--user",
    developer = "bioc-role--developer"
  )

  # Check what fields are available
  # If the field does not exist, return NA
  # This is required also for filled, which will treat NA as not available
  field <- function(name) {
    if (name %in% names(members)) {
      as.character(members[[name]])
    } else {
      rep(NA_character_, nrow(members))
    }
  }

  name <- field("name")
  role <- field("role")
  role[is.na(role) | !role %in% names(role_label)] <- "user"
  city <- field("city")
  country <- field("country")
  title <- field("title")
  affiliation <- field("affiliation")
  github <- field("github")
  linkedin <- field("linkedin")
  bluesky <- field("bluesky")
  website <- field("website")

  # Check if a value of the field exists
  filled <- function(x) !is.na(x)

  # Format person's location for display
  place <- function(city, country) {
    if (!filled(country) || country == "Finland") {
      if (filled(city)) city else ""
    } else if (filled(city)) {
      paste(city, country, sep = ", ")
    } else {
      country
    }
  }

  # Generate initials as a fallback if someone does not have a GitHub avatar
  initials <- function(name) {
    parts <- strsplit(name, "\\s+")[[1]]
    toupper(paste0(
      substr(parts[seq_len(min(2, length(parts)))], 1, 1),
      collapse = ""
    ))
  }

  # Inline SVG icons from Bootstrap Icons
  icon <- function(path) {
    htmltools::HTML(paste0(
      # 16x16 svg icon
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" ',
      # currentColor follows the link's color
      # https://css-tricks.com/cascading-svg-fill-color/
      # aria-hidden hides it from accessibility API
      'fill="currentColor" aria-hidden="true">',
      '<path d="',
      path,
      '"/></svg>'
    ))
  }

  icons <- list(
    # https://icons.getbootstrap.com/icons/github/
    github = icon(
      "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8"
    ),
    # https://icons.getbootstrap.com/icons/linkedin/
    linkedin = icon(
      "M0 1.146C0 .513.526 0 1.175 0h13.65C15.474 0 16 .513 16 1.146v13.708c0 .633-.526 1.146-1.175 1.146H1.175C.526 16 0 15.487 0 14.854zm4.943 12.248V6.169H2.542v7.225zm-1.2-8.212c.837 0 1.358-.554 1.358-1.248-.015-.709-.52-1.248-1.342-1.248S2.4 3.226 2.4 3.934c0 .694.521 1.248 1.327 1.248zm4.908 8.212V9.359c0-.216.016-.432.08-.586.173-.431.568-.878 1.232-.878.869 0 1.216.662 1.216 1.634v3.865h2.401V9.25c0-2.22-1.184-3.252-2.764-3.252-1.274 0-1.845.7-2.165 1.193v.025h-.016l.016-.025V6.169h-2.4c.03.678 0 7.225 0 7.225z"
    ),
    # https://icons.getbootstrap.com/icons/bluesky/
    bluesky = icon(
      "M3.468 1.948C5.303 3.325 7.276 6.118 8 7.616c.725-1.498 2.698-4.29 4.532-5.668C13.855.955 16 .186 16 2.632c0 .489-.28 4.105-.444 4.692-.572 2.04-2.653 2.561-4.504 2.246 3.236.551 4.06 2.375 2.281 4.2-3.376 3.464-4.852-.87-5.23-1.98-.07-.204-.103-.3-.103-.218 0-.081-.033.014-.102.218-.379 1.11-1.855 5.444-5.231 1.98-1.778-1.825-.955-3.65 2.28-4.2-1.85.315-3.932-.205-4.503-2.246C.28 6.737 0 3.12 0 2.632 0 .186 2.145.955 3.468 1.948"
    ),
    # https://icons.getbootstrap.com/icons/globe/
    website = icon(
      "M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8m7.5-6.923c-.67.204-1.335.82-1.887 1.855A8 8 0 0 0 5.145 4H7.5zM4.09 4a9.3 9.3 0 0 1 .64-1.539 7 7 0 0 1 .597-.933A7.03 7.03 0 0 0 2.255 4zm-.582 3.5c.03-.877.138-1.718.312-2.5H1.674a7 7 0 0 0-.656 2.5zM4.847 5a12.5 12.5 0 0 0-.338 2.5H7.5V5zM8.5 5v2.5h2.99a12.5 12.5 0 0 0-.337-2.5zM4.51 8.5a12.5 12.5 0 0 0 .337 2.5H7.5V8.5zm3.99 0V11h2.653c.187-.765.306-1.608.338-2.5zM5.145 12q.208.58.468 1.068c.552 1.035 1.218 1.65 1.887 1.855V12zm.182 2.472a7 7 0 0 1-.597-.933A9.3 9.3 0 0 1 4.09 12H2.255a7 7 0 0 0 3.072 2.472M3.82 11a13.7 13.7 0 0 1-.312-2.5h-2.49c.062.89.291 1.733.656 2.5zm6.853 3.472A7 7 0 0 0 13.745 12H11.91a9.3 9.3 0 0 1-.64 1.539 7 7 0 0 1-.597.933M8.5 12v2.923c.67-.204 1.335-.82 1.887-1.855q.26-.487.468-1.068zm3.68-1h2.146c.365-.767.594-1.61.656-2.5h-2.49a13.7 13.7 0 0 1-.312 2.5m2.802-3.5a7 7 0 0 0-.656-2.5H12.18c.174.782.282 1.623.312 2.5zM11.27 2.461c.247.464.462.98.64 1.539h1.835a7 7 0 0 0-3.072-2.472c.218.284.418.598.597.933M10.855 4a8 8 0 0 0-.468-1.068C9.835 1.897 9.17 1.282 8.5 1.077V4z"
    )
  )

  link <- function(href, icon, label) {
    htmltools::tags$a(
      href = href,
      class = "bioc-link",
      title = label,
      # aria-label is for screen readers
      `aria-label` = label,
      target = "_blank",
      rel = "noopener",
      icon
    )
  }

  card <- function(i) {
    # Add GitHub link
    avatar <- if (filled(github[i])) {
      htmltools::tags$img(
        class = paste("bioc-avatar", role_class[[role[i]]]),
        src = paste0(
          "https://github.com/",
          utils::URLencode(github[i], reserved = TRUE),
          ".png?size=160"
        ),
        alt = paste("GitHub profile picture of", name[i]),
        loading = "lazy"
      )
    } else {
      htmltools::tags$span(
        class = paste(
          "bioc-avatar",
          "bioc-initials",
          role_class[[role[i]]]
        ),
        initials(name[i])
      )
    }

    links <- Filter(
      Negate(is.null), # keep everything that is not NULL
      list(
        if (filled(github[i])) {
          link(
            paste0(
              "https://github.com/",
              # Make sure the URL uses correct characters
              utils::URLencode(github[i], reserved = TRUE)
            ),
            icons$github,
            "GitHub"
          )
        },
        if (filled(linkedin[i])) {
          link(
            paste0(
              "https://www.linkedin.com/in/",
              utils::URLencode(linkedin[i], reserved = TRUE)
            ),
            icons$linkedin,
            "LinkedIn"
          )
        },
        if (filled(bluesky[i])) {
          link(
            paste0(
              "https://bsky.app/profile/",
              utils::URLencode(bluesky[i], reserved = TRUE)
            ),
            icons$bluesky,
            "Bluesky"
          )
        },
        if (filled(website[i])) {
          link(website[i], icons$website, "Website")
        }
      )
    )

    # Build a card for one purson
    htmltools::tags$li(
      class = "bioc-person",
      avatar,
      htmltools::tags$div(
        class = "bioc-person-body",
        htmltools::tags$div(
          class = "bioc-person-heading",
          htmltools::tags$span(class = "bioc-person-name", name[i]),
          htmltools::tags$span(
            class = paste("bioc-role", role_class[[role[i]]]),
            role_label[[role[i]]]
          )
        ),
        if (filled(title[i])) {
          htmltools::tags$div(class = "bioc-person-title", title[i])
        },
        if (nzchar(place(city[i], country[i]))) {
          htmltools::tags$div(
            class = "bioc-person-meta",
            place(city[i], country[i])
          )
        },
        if (filled(affiliation[i])) {
          htmltools::tags$div(
            class = "bioc-person-meta",
            affiliation[i]
          )
        },
        if (length(links) > 0) {
          htmltools::tags$div(class = "bioc-person-links", links)
        }
      )
    )
  }

  developers <- sum(role == "developer")
  # Make roles plural if required
  plural <- function(n, word) {
    paste0(n, " ", word, if (n == 1) "" else "s")
  }
  people <- if (nrow(members) == 1) {
    "1 person"
  } else {
    paste(nrow(members), "people")
  }
  summary <- paste0(
    people,
    " (",
    # Number of users is number of members - developers
    # NOTE if we have other roles, this might require adjustment
    plural(nrow(members) - developers, "user"),
    ", ",
    plural(developers, "developer"),
    ")"
  )
  if (!is.null(bioc$updated)) {
    summary <- paste0(
      summary,
      " · Last updated ",
      as.character(bioc$updated)
    )
  }

  # Generate the html panel
  html <- as.character(panel(
    htmltools::tags$p(class = "bioc-people-summary", summary),
    htmltools::tags$ul(
      class = "bioc-people-list",
      lapply(seq_len(nrow(members)), card)
    )
  ))

  # Keep the panel on one line
  gsub("\\s*\\n\\s*", "", html)
}
