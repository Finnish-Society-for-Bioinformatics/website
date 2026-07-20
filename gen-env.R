library(rix)

rix(
  r_ver = "4.5.2",
  r_pkgs = c(
    "languageserver",
    "readr",
    "dplyr",
    "knitr",
    "rix",
    "kableExtra"
  ),
  system_pkgs = c("quarto"),
  git_pkgs = NULL,
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
