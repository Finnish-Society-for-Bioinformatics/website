render_past_members <- function(data) {
  # Split data into three columns
  col_id <- sort(rep(1:3, length.out = nrow(data)))
  columns <- split(data, col_id)

  # Main grid
  cat(":::: {.grid}\n\n")

  for (column in columns) {
    cat("::: {.g-col-4}\n")

    cat(
      sprintf(
        "* %s (%s)\n",
        column$name,
        column$dates
      )
    )

    cat(":::\n\n")
  }

  cat("::::\n")
}
