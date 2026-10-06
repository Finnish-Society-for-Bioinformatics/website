library(rix)

rix(
  r_ver = "4.6.1",
  r_pkgs = c("quarto", "knitr", "readr", "rix", "rmarkdown", "yaml"),
  system_pkgs = c("quarto", "radian"),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
