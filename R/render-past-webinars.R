render_webinars <- function(webinars) {
  cat("::::: {.grid}\n\n")

  for (webinar in webinars) {
    cat(":::: {.g-col-12 .g-col-md-6 .g-col-lg-4 .d-flex .flex-column}\n\n")

    # Video
    if (!is.null(webinar$video)) {
      cat(sprintf(
        "{{< video %s >}}\n\n",
        webinar$video
      ))
    } else {
      # Add the image if no video
      cat(sprintf(
        "![](%s){.img-fluid}\n\n",
        webinar$image
      ))
    }

    # Speaker
    cat(sprintf(
      "### %s {.mt-3}\n\n",
      webinar$speaker
    ))

    # Affiliation
    cat(sprintf(
      "**%s**\n\n",
      webinar$affiliation
    ))

    # Title
    cat(sprintf(
      "*%s*\n\n",
      webinar$title
    ))

    # Abstract
    cat(
      "::: {.callout-note collapse=\"true\" icon=\"false\"}\n"
    )
    cat("## Abstract\n\n")
    cat(webinar$abstract)
    cat("\n:::\n\n")
    cat("::::\n\n")
  }

  cat(":::::\n")
}
