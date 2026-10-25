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

  link <- function(href, label) {
    htmltools::tags$a(
      href = href,
      target = "_blank",
      rel = "noopener",
      label
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
            "GitHub"
          )
        },
        if (filled(linkedin[i])) {
          link(
            paste0(
              "https://www.linkedin.com/in/",
              utils::URLencode(linkedin[i], reserved = TRUE)
            ),
            "LinkedIn"
          )
        },
        if (filled(bluesky[i])) {
          link(
            paste0(
              "https://bsky.app/profile/",
              utils::URLencode(bluesky[i], reserved = TRUE)
            ),
            "Bluesky"
          )
        },
        if (filled(website[i])) link(website[i], "Website")
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
