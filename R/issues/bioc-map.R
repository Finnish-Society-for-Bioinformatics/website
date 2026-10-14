#!/usr/bin/env Rscript
#
# Validates and applies Bioconductor map requests submitted through GitHub
# issue forms (.github/ISSUE_TEMPLATE/bioc-map-*.yml). Used by
# .github/workflows/bioc-map.yml.
#
# Usage (from the repository root):
#   Rscript R/issues/bioc-map.R validate [event.json] [data.yaml]
#   Rscript R/issues/bioc-map.R apply    [event.json] [data.yaml]
#
# `validate` only checks the request. `apply` checks it again and, if valid,
# writes the change to the data file. Both write a Markdown report to
# $RUNNER_TEMP/bioc-map-report.md and set the step outputs
# `valid`, `action`, and `name` in $GITHUB_OUTPUT.

source("R/issues/common.R")

DATA_PATH <- "data/bioconductor_members.yaml"

# Issue form labels (the "### ..." headings in the issue body) and the keys
# they map to. Keep these in sync with the issue templates.
FIELDS <- c(
  "Current entry" = "entry",
  "Name" = "name",
  "Role" = "role",
  "City" = "city",
  "Country" = "country",
  "Job title" = "title",
  "Affiliation" = "affiliation",
  "GitHub handle" = "github",
  "LinkedIn" = "linkedin",
  "Bluesky" = "bluesky",
  "Website" = "website",
  "Consent" = "consent",
  "Reason" = "reason"
)
OPTIONAL <- c("title", "affiliation", "github", "linkedin", "bluesky", "website")
ROLES <- c("Bioconductor user" = "user", "Bioconductor developer" = "developer")

# ---- Parsing -----------------------------------------------------------------

#' Detects the requested action from the issue labels.
detect_action <- function(issue) {
  labels <- issue_labels(issue)
  for (action in c("add", "modify", "remove")) {
    if (paste0("bioc-map: ", action) %in% labels) return(action)
  }
  NA_character_
}

# ---- Field validation --------------------------------------------------------
# Each validator returns list(value = normalised value, error = message|NULL).
# check_text() and check_url() are in common.R.

check_role <- function(value) {
  if (!value %in% names(ROLES)) {
    return(fail(sprintf(
      "Role must be one of: %s.", paste(names(ROLES), collapse = ", ")
    )))
  }
  ok(unname(ROLES[value]))
}

check_github <- function(value, token = Sys.getenv("GITHUB_TOKEN")) {
  handle <- sub("^(https?://)?(www\\.)?github\\.com/", "", value)
  handle <- sub("/$", "", sub("^@", "", handle))
  pattern <- "^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$"
  if (!grepl(pattern, handle, perl = TRUE)) {
    return(fail(sprintf("`%s` is not a valid GitHub handle.", value)))
  }
  headers <- c("User-Agent" = USER_AGENT, "Accept" = "application/vnd.github+json")
  if (nzchar(token)) headers["Authorization"] <- paste("Bearer", token)
  user <- tryCatch(
    fetch_json(paste0("https://api.github.com/users/", handle), headers),
    error = function(e) NULL
  )
  if (is.null(user$login)) {
    return(fail(sprintf("GitHub user `%s` was not found.", handle)))
  }
  ok(user$login)
}

check_linkedin <- function(value) {
  pattern <- "^(https?://)?([a-z]{2,3}\\.)?linkedin\\.com/in/([^/?#]+)/?([?#].*)?$"
  slug <- if (grepl(pattern, value, ignore.case = TRUE)) {
    sub(pattern, "\\3", value, ignore.case = TRUE)
  } else {
    value
  }
  if (!grepl("^[A-Za-z0-9_%-]{3,100}$", slug)) {
    return(fail(
      "LinkedIn must be a profile URL (https://www.linkedin.com/in/...)."
    ))
  }
  ok(paste0("https://www.linkedin.com/in/", slug))
}

check_bluesky <- function(value) {
  handle <- sub("^(https?://)?bsky\\.app/profile/", "", value)
  handle <- tolower(sub("/$", "", sub("^@", "", handle)))
  pattern <- "^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,}$"
  if (!grepl(pattern, handle)) {
    return(fail(sprintf(
      "`%s` is not a valid Bluesky handle (e.g., name.bsky.social).", value
    )))
  }
  ok(handle)
}

#' Geocodes a city with OpenStreetMap Nominatim.
#'
#' @return List with the English names of the city and country, coordinates
#'   (rounded to the city level), and `error` if the city was not found.
check_location <- function(city, country) {
  for (res in list(check_text(city, "City", 60), check_text(country, "Country", 60))) {
    if (!is.null(res$error)) return(res)
  }
  url <- paste0(
    "https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1",
    "&featureType=settlement&addressdetails=1&accept-language=en&q=",
    utils::URLencode(paste(city, country, sep = ", "), reserved = TRUE)
  )
  hits <- tryCatch(
    fetch_json(url, c("User-Agent" = USER_AGENT)),
    error = function(e) NULL
  )
  if (is.null(hits) || length(hits) == 0) {
    return(fail(sprintf("City `%s` was not found in `%s`.", city, country)))
  }
  list(
    city = hits$name[1],
    country = hits$address$country[1],
    lat = round(as.numeric(hits$lat[1]), 4),
    lon = round(as.numeric(hits$lon[1]), 4),
    error = NULL
  )
}

#' Validates a single field and returns the result.
check_field <- function(key, value) {
  switch(key,
    name = check_text(value, "Name", 100),
    role = check_role(value),
    title = check_text(value, "Job title", 100),
    affiliation = check_text(value, "Affiliation", 150),
    github = check_github(value),
    linkedin = check_linkedin(value),
    bluesky = check_bluesky(value),
    website = check_url(value, "Website"),
    ok(value)
  )
}

# ---- Request handling --------------------------------------------------------

#' Finds the index of an existing entry by its name or GitHub handle.
find_member <- function(members, query) {
  query <- tolower(sub("^@", "", trimws(query)))
  hits <- which(vapply(members, function(m) {
    query %in% tolower(c(m$name, m$github %||% NA_character_))
  }, logical(1)))
  if (length(hits) == 1) hits else NA_integer_
}

#' Checks whether the issue author is the owner of the entry.
is_owner <- function(member, author) {
  tolower(author) %in% tolower(c(member$github, member$submitted_by))
}

#' Validates a request and computes the resulting member list.
#'
#' @param action One of "add", "modify", or "remove".
#' @param fields Parsed issue form fields.
#' @param members Current members.
#' @param author GitHub login of the issue author.
#' @param today Date of the change.
#'
#' @return List with `errors`, `notes`, `members` (the new member list), and
#'   `name` (the name of the affected entry).
process_request <- function(action, fields, members, author, today) {
  errors <- character(0)
  notes <- character(0)
  get <- function(key) trimws(fields[[key]] %||% "")

  if (is.na(action)) {
    return(list(errors = paste(
      "Could not detect the request type. The issue needs one of the labels",
      "`bioc-map: add`, `bioc-map: modify`, or `bioc-map: remove`."
    )))
  }
  if (!grepl("[Xx]\\]", get("consent"))) {
    errors <- c(errors, "Please tick the consent checkbox.")
  }

  # Locate the existing entry for modify/remove
  idx <- NA_integer_
  if (action %in% c("modify", "remove")) {
    idx <- find_member(members, get("entry"))
    if (is.na(idx)) {
      errors <- c(errors, sprintf(
        "No single entry matches `%s`. Use the exact name or GitHub handle.",
        get("entry")
      ))
    } else if (is_owner(members[[idx]], author)) {
      notes <- c(notes, sprintf("✅ @%s owns this entry.", author))
    } else {
      notes <- c(notes, sprintf(paste(
        "⚠️ @%s is not the GitHub user linked to this entry. A maintainer",
        "must verify that the request comes from the person themselves."
      ), author))
    }
  }

  if (action == "remove") {
    name <- if (is.na(idx)) get("entry") else members[[idx]]$name
    if (length(errors) == 0) members <- members[-idx]
    return(list(errors = errors, notes = notes, members = members, name = name))
  }

  # Build the new entry for add/modify
  member <- if (is.na(idx)) list() else members[[idx]]
  for (key in c("name", "role", OPTIONAL)) {
    value <- get(key)
    if (!nzchar(value)) {
      if (action == "add" && !key %in% OPTIONAL) {
        errors <- c(errors, sprintf("`%s` is required.", names(FIELDS)[FIELDS == key]))
      }
      next
    }
    # In modify requests, "-" clears an optional field
    if (action == "modify" && value == "-") {
      if (key %in% OPTIONAL) {
        member[[key]] <- NULL
      } else {
        errors <- c(errors, sprintf("`%s` cannot be removed.", key))
      }
      next
    }
    res <- check_field(key, value)
    if (!is.null(res$error)) {
      errors <- c(errors, res$error)
      next
    }
    member[[key]] <- res$value
  }

  # The city and country are geocoded together. In modify requests, a missing
  # one is taken from the current entry.
  city <- get("city")
  country <- get("country")
  if (action == "add") {
    if (!nzchar(city)) errors <- c(errors, "`City` is required.")
    if (!nzchar(country)) errors <- c(errors, "`Country` is required.")
  }
  if ((nzchar(city) || nzchar(country)) && (action == "modify" || nzchar(city) && nzchar(country))) {
    if (!nzchar(city)) city <- member$city
    if (!nzchar(country)) country <- member$country %||% "Finland"
    res <- check_location(city, country)
    if (is.null(res$error)) {
      member[c("city", "country", "lat", "lon")] <- res[c("city", "country", "lat", "lon")]
    } else if (action == "modify" && !nzchar(get("country"))) {
      errors <- c(errors, paste(res$error, "If you moved to another country, fill in `Country` too."))
    } else {
      errors <- c(errors, res$error)
    }
  }

  # Prevent duplicates
  others <- if (is.na(idx)) members else members[-idx]
  for (key in c("name", "github")) {
    if (!is.null(member[[key]]) && !is.na(find_member(others, member[[key]]))) {
      errors <- c(errors, sprintf(
        "An entry with %s `%s` already exists. Use the modify template instead.",
        key, member[[key]]
      ))
    }
  }

  if (action == "add") {
    member$submitted_by <- author
    member$added <- today
  }
  member$updated <- today
  member <- member[intersect(MEMBER_KEYS, names(member))]

  if (length(errors) == 0) {
    if (is.na(idx)) members <- c(members, list(member)) else members[[idx]] <- member
    members <- members[order(tolower(vapply(members, `[[`, "", "name")))]
  }
  list(
    errors = errors, notes = notes, members = members,
    name = member$name %||% get("entry"), member = member
  )
}

MEMBER_KEYS <- c(
  "name", "role", "city", "country", "lat", "lon", "title", "affiliation", "github", "linkedin",
  "bluesky", "website", "submitted_by", "added", "updated"
)

# ---- Output ------------------------------------------------------------------

report <- function(action, result, mode) {
  m <- result[["member"]]
  shown <- setdiff(names(m), c("lat", "lon", "submitted_by", "added", "updated"))
  format_report(
    marker = "bioc-map-bot",
    title = paste(action %|na|% "map", "request"),
    errors = result$errors,
    notes = result$notes,
    entry = m[shown],
    next_step = if (mode == "validate") {
      "A maintainer will review the request. Once it is approved, a pull request updating the map is opened automatically."
    }
  )
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  mode <- args[1]
  stopifnot(mode %in% c("validate", "apply"))
  event_path <- if (length(args) >= 2) args[2] else Sys.getenv("GITHUB_EVENT_PATH")
  data_path <- if (length(args) >= 3) args[3] else DATA_PATH

  issue <- jsonlite::read_json(event_path)$issue
  data <- yaml::read_yaml(data_path)
  today <- format(Sys.Date())

  action <- detect_action(issue)
  result <- process_request(
    action, parse_issue_form(issue$body, FIELDS), data$members %||% list(),
    issue$user$login, today
  )
  valid <- length(result$errors) == 0

  write_report(report(action, result, mode), "bioc-map")
  if (mode == "apply" && valid) {
    write_data(list(updated = today, members = result$members), data_path)
  }
  set_output(
    valid = tolower(valid), action = action %|na|% "", name = result$name %||% ""
  )
}

if (sys.nframe() == 0) main()
