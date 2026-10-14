#!/usr/bin/env Rscript
#
# Validates and applies job advertisements submitted through the GitHub issue
# forms .github/ISSUE_TEMPLATE/job-ad.yml (add) and job-ad-remove.yml (remove).
# Used by .github/workflows/job-ads.yml.
#
# Usage (from the repository root):
#   Rscript R/issues/jobs.R validate [event.json] [data.yaml]
#   Rscript R/issues/jobs.R apply    [event.json] [data.yaml]
#
# `validate` only checks the request. `apply` checks it again and, if valid,
# adds or removes the job in the data file. Both write a Markdown report to
# $RUNNER_TEMP/job-ad-report.md and set the step outputs `valid`, `action`, and
# `title` in $GITHUB_OUTPUT.

source("R/issues/common.R")

DATA_PATH <- "data/jobs.yaml"
# Advertisements can be shown for at most this many days
MAX_DAYS <- 365

# Issue form labels (the "### ..." headings in the issue body) and the keys
# they map to. Keep these in sync with the issue template.
FIELDS <- c(
  "Job title" = "title",
  "Company or organisation" = "company",
  "Location" = "location",
  "Description" = "description",
  "Link to more information" = "link",
  "Contact person" = "contact",
  "Expiry date" = "expires"
)
# Fields of the removal form
REMOVE_FIELDS <- c(
  "Advertisement" = "job",
  "Reason" = "reason"
)
JOB_KEYS <- c(
  "id", "title", "company", "location", "description", "link", "contact",
  "expires", "submitted_by", "added"
)

check_expiry <- function(value, today) {
  date <- if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value)) {
    as.Date(value, optional = TRUE)
  } else {
    NA
  }
  if (is.na(date)) {
    return(fail(sprintf("Expiry date `%s` must be a date in the format YYYY-MM-DD.", value)))
  }
  if (date < today) {
    return(fail(sprintf("Expiry date %s has already passed.", value)))
  }
  if (date > today + MAX_DAYS) {
    return(fail(sprintf("Expiry date must be within %d days.", MAX_DAYS)))
  }
  ok(format(date))
}

#' Validates a job advertisement and adds it to the list of jobs.
#'
#' @param fields Parsed issue form fields.
#' @param jobs Current jobs.
#' @param issue_number Number of the issue, used as the id of the job.
#' @param author GitHub login of the issue author.
#' @param today Date of the change.
#'
#' @return List with `errors`, `job`, and `jobs` (the new list of jobs).
process_job <- function(fields, jobs, issue_number, author, today) {
  errors <- character(0)
  get <- function(key) trimws(fields[[key]] %||% "")

  job <- list(id = issue_number)
  for (key in unname(FIELDS)) {
    value <- get(key)
    if (!nzchar(value)) {
      errors <- c(errors, sprintf("`%s` is required.", names(FIELDS)[FIELDS == key]))
      next
    }
    res <- switch(key,
      title = check_text(value, "Job title", 150),
      company = check_text(value, "Company or organisation", 150),
      location = check_text(value, "Location", 100),
      description = check_text(value, "Description", 3000, multiline = TRUE),
      link = check_url(value, "Link"),
      contact = check_text(value, "Contact person", 200),
      expires = check_expiry(value, as.Date(today))
    )
    if (is.null(res$error)) job[[key]] <- res$value else errors <- c(errors, res$error)
  }
  job$submitted_by <- author
  job$added <- today
  job <- job[intersect(JOB_KEYS, names(job))]

  # Re-approving an issue replaces the earlier version of the job
  jobs <- Filter(function(j) !identical(j$id, issue_number), jobs)
  if (length(errors) == 0) {
    jobs <- c(jobs, list(job))
    # Newest first
    jobs <- jobs[order(vapply(jobs, `[[`, "", "added"), decreasing = TRUE)]
  }
  list(errors = errors, job = job, jobs = jobs)
}

#' Finds the index of a job by its issue number (e.g., "#42") or title.
find_job <- function(jobs, query) {
  query <- tolower(trimws(query))
  # Accept "#42", "42", or a link to the issue
  number <- sub("^.*?#?([0-9]+)/?$", "\\1", query, perl = TRUE)
  hits <- which(vapply(jobs, function(j) {
    (grepl("^(#|.*/issues/)?[0-9]+/?$", query) && identical(as.character(j$id), number)) ||
      identical(tolower(j$title), query)
  }, logical(1)))
  if (length(hits) == 1) hits else NA_integer_
}

#' Validates a removal request and removes the job from the list of jobs.
#'
#' @return List with `errors`, `notes`, `job`, and `jobs` (the new list).
process_removal <- function(fields, jobs, author) {
  query <- trimws(fields$job %||% "")
  idx <- find_job(jobs, query)
  if (is.na(idx)) {
    return(list(
      errors = sprintf(paste(
        "No single advertisement matches `%s`. Use the exact job title or the",
        "number of the issue that added it (e.g., #42)."
      ), query),
      jobs = jobs
    ))
  }
  job <- jobs[[idx]]
  notes <- if (identical(tolower(job$submitted_by), tolower(author))) {
    sprintf("✅ @%s submitted this advertisement.", author)
  } else {
    sprintf(paste(
      "⚠️ @%s did not submit this advertisement (it was submitted by @%s).",
      "A maintainer must check that the removal is legitimate."
    ), author, job$submitted_by)
  }
  list(errors = character(0), notes = notes, job = job, jobs = jobs[-idx])
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  mode <- args[1]
  stopifnot(mode %in% c("validate", "apply"))
  event_path <- if (length(args) >= 2) args[2] else Sys.getenv("GITHUB_EVENT_PATH")
  data_path <- if (length(args) >= 3) args[3] else DATA_PATH

  issue <- jsonlite::read_json(event_path)$issue
  data <- yaml::read_yaml(data_path)
  today <- format(Sys.Date())

  action <- if ("job-ad: remove" %in% issue_labels(issue)) "remove" else "add"
  fields <- parse_issue_form(issue$body, c(FIELDS, REMOVE_FIELDS))
  jobs <- data$jobs %||% list()
  result <- if (action == "add") {
    process_job(fields, jobs, as.integer(issue$number), issue$user$login, today)
  } else {
    process_removal(fields, jobs, issue$user$login)
  }
  valid <- length(result$errors) == 0

  shown <- setdiff(names(result$job), c("id", "submitted_by", "added"))
  write_report(
    format_report(
      marker = "job-ad-bot",
      title = if (action == "add") "job advertisement" else "removal request",
      errors = result$errors,
      notes = result$notes,
      entry = result$job[shown],
      next_step = if (mode == "validate" && action == "add") {
        "A maintainer will review the advertisement. Once it is approved, a pull request adding it to the Jobs page is opened automatically. The advertisement is removed from the page automatically after the expiry date."
      } else if (mode == "validate") {
        "A maintainer will review the request. Once it is approved, a pull request removing the advertisement is opened automatically."
      }
    ),
    "job-ad"
  )
  if (mode == "apply" && valid) {
    write_data(list(jobs = result$jobs), data_path)
  }
  set_output(
    valid = tolower(valid), action = action, title = result$job$title %||% ""
  )
}

if (sys.nframe() == 0) main()
