#' Renders job advertisements from a YAML file.
#'
#' Jobs that have expired when the page is rendered are left out. Jobs that
#' expire later are hidden in the browser by the script in pages/_jobs.html,
#' so the page does not need to be rendered again.
#'
#' @param path Path to yaml file with jobs.
#' @param today Date used to leave out expired jobs.
#'
#' @return Character string with an HTML block of job cards.
render_jobs <- function(path, today = Sys.Date()) {
  jobs <- yaml::read_yaml(path)$jobs
  jobs <- Filter(function(job) as.Date(job$expires) >= today, jobs)

  cards <- vapply(jobs, function(job) {
    expires <- as.Date(job$expires)
    sprintf(
      paste(
        '<article class="job-card" data-expires="%s">',
        "<h3>%s</h3>",
        '<div class="job-meta">',
        '<span><i class="bi bi-building"></i> %s</span>',
        '<span><i class="bi bi-geo-alt"></i> %s</span>',
        '<span><i class="bi bi-calendar-event"></i> Apply by %s</span>',
        "</div>",
        '<div class="job-description">%s</div>',
        '<div class="job-contact"><i class="bi bi-person"></i> Contact: %s</div>',
        '<a class="btn btn-dark rounded-pill" href="%s" target="_blank" rel="noopener">More information</a>',
        "</article>",
        sep = "\n"
      ),
      format(expires),
      escape_html(job$title),
      escape_html(job$company),
      escape_html(job$location),
      format(expires, "%-d %B %Y"),
      format_paragraphs(job$description),
      link_emails(escape_html(job$contact)),
      escape_html(job$link)
    )
  }, character(1))

  paste(
    "```{=html}",
    '<div class="job-list">',
    paste(cards, collapse = "\n"),
    "</div>",
    sprintf(
      '<p class="job-empty"%s>There are no open positions at the moment.</p>',
      if (length(cards) > 0) " hidden" else ""
    ),
    "```",
    sep = "\n"
  )
}

escape_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

#' Turns plain text into paragraphs. Empty lines separate paragraphs.
format_paragraphs <- function(text) {
  paragraphs <- strsplit(trimws(text), "\n[[:space:]]*\n")[[1]]
  paragraphs <- gsub("\n", "<br>", escape_html(trimws(paragraphs)), fixed = TRUE)
  paste0("<p>", paragraphs, "</p>", collapse = "")
}

#' Turns email addresses into mailto links.
link_emails <- function(text) {
  gsub(
    "([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})",
    '<a href="mailto:\\1">\\1</a>',
    text
  )
}
