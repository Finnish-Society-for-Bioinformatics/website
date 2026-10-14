# Helpers shared by the scripts that validate and apply requests submitted
# through GitHub issue forms (R/issues/bioc-map.R and R/issues/jobs.R).

USER_AGENT <- paste(
  "FSFB-website",
  "(https://github.com/Finnish-Society-for-Bioinformatics/website)"
)

`%||%` <- function(x, y) if (is.null(x)) y else x
`%|na|%` <- function(x, y) if (is.na(x)) y else x

#' Parses the body of an issue created from an issue form.
#'
#' @param body Issue body.
#' @param fields Named character vector mapping the issue form labels (the
#'   "### ..." headings in the issue body) to keys.
#'
#' @return Named list of field values. Empty fields are "".
parse_issue_form <- function(body, fields) {
  body <- gsub("\r\n", "\n", body %||% "")
  sections <- strsplit(body, "(^|\n)### ", perl = TRUE)[[1]]
  out <- list()
  for (section in sections[nzchar(trimws(sections))]) {
    lines <- strsplit(section, "\n", fixed = TRUE)[[1]]
    key <- fields[trimws(lines[1])]
    if (is.na(key)) next
    value <- trimws(paste(lines[-1], collapse = "\n"))
    if (identical(value, "_No response_") || identical(value, "None")) {
      value <- ""
    }
    out[[key]] <- value
  }
  out
}

#' Returns the names of the labels of an issue.
issue_labels <- function(issue) {
  vapply(issue$labels, function(l) l$name, character(1))
}

# ---- Field validation --------------------------------------------------------
# Each validator returns list(value = normalised value, error = message|NULL).

ok <- function(value) list(value = value, error = NULL)
fail <- function(message) list(value = NULL, error = message)

check_text <- function(value, label, max_chars, multiline = FALSE) {
  if (!multiline && grepl("\n", value, fixed = TRUE)) {
    return(fail(sprintf("%s must be a single line.", label)))
  }
  if (grepl("[<>]", value)) {
    return(fail(sprintf("%s must not contain `<` or `>`.", label)))
  }
  if (nchar(value) > max_chars) {
    return(fail(sprintf("%s must be at most %d characters.", label, max_chars)))
  }
  ok(value)
}

check_url <- function(value, label = "Website") {
  if (!grepl("^https?://", value, ignore.case = TRUE)) {
    value <- paste0("https://", value)
  }
  pattern <- "^https?://[A-Za-z0-9.-]+\\.[A-Za-z]{2,}(:[0-9]+)?(/[^[:space:]<>\"']*)?$"
  if (!grepl(pattern, value)) {
    return(fail(sprintf("`%s` is not a valid %s URL.", value, tolower(label))))
  }
  ok(value)
}

fetch_json <- function(url, headers) {
  con <- url(url, headers = headers)
  on.exit(close(con))
  text <- suppressWarnings(readLines(con, warn = FALSE))
  jsonlite::fromJSON(paste(text, collapse = "\n"))
}

# ---- Output ------------------------------------------------------------------

#' Formats the result of a check as a Markdown comment.
#'
#' @param marker Hidden marker that identifies the comment so that it can be
#'   updated instead of adding a new one.
#' @param title Short description of the request, e.g., "add request".
#' @param errors,notes Character vectors.
#' @param entry Named list shown as a table when the request is valid.
#' @param next_step Text shown after a successful check.
format_report <- function(marker, title, errors, notes, entry, next_step) {
  valid <- length(errors) == 0
  lines <- c(
    sprintf("<!-- %s -->", marker),
    if (valid) {
      sprintf("### ✅ The %s looks good", title)
    } else {
      sprintf("### ❌ The %s needs changes", title)
    }
  )
  if (!valid) {
    lines <- c(lines, "", paste("-", errors), "",
      "Please edit the issue to fix the problems. It will be checked again automatically."
    )
  }
  if (length(notes) > 0) lines <- c(lines, "", paste("-", notes))
  if (valid && length(entry) > 0) {
    # Keep tables intact: one line per value
    values <- gsub("\n+", " ", vapply(entry, as.character, ""))
    lines <- c(lines, "", "| Field | Value |", "|---|---|",
      sprintf("| %s | %s |", names(entry), gsub("|", "\\|", values, fixed = TRUE))
    )
  }
  if (valid && !is.null(next_step)) lines <- c(lines, "", next_step)
  paste(lines, collapse = "\n")
}

#' Writes the report to $RUNNER_TEMP/<name>-report.md.
write_report <- function(report, name) {
  writeLines(report, file.path(Sys.getenv("RUNNER_TEMP", "."), paste0(name, "-report.md")))
}

#' Writes data to a YAML file, keeping the comment lines at the top of the file.
write_data <- function(data, path) {
  header <- readLines(path, warn = FALSE)
  header <- header[seq_len(which(!startsWith(header, "#"))[1] - 1)]
  body <- yaml::as.yaml(data, indent.mapping.sequence = TRUE)
  writeLines(c(header, sub("\n$", "", body)), path)
}

#' Sets step outputs for GitHub Actions (prints them when run locally).
set_output <- function(...) {
  out <- Sys.getenv("GITHUB_OUTPUT")
  values <- list(...)
  lines <- sprintf("%s=%s", names(values), gsub("[\r\n]", " ", unlist(values)))
  if (nzchar(out)) cat(lines, file = out, sep = "\n", append = TRUE)
  else cat(lines, sep = "\n")
}
