#!/usr/bin/env Rscript
# Render the full bookdown webbook (all chapters, eval-enabled R chunks).

options(timeout = max(600, getOption("timeout")))

pandoc_dir <- file.path(getwd(), "tools", "pandoc-3.6.4-arm64", "bin")
if (dir.exists(pandoc_dir)) {
  Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
}
if (!rmarkdown::pandoc_available()) {
  stop("Pandoc is required. Install pandoc or run tools/pandoc setup.", call. = FALSE)
}

suppressPackageStartupMessages({
  if (!requireNamespace("bookdown", quietly = TRUE)) {
    stop("Package 'bookdown' is required. Install it with install.packages('bookdown').", call. = FALSE)
  }
})

cat("Starting full webbook render at", format(Sys.time()), "\n")
cat("Working directory:", getwd(), "\n")

bookdown::render_book(
  input = ".",
  output_format = "bookdown::gitbook",
  output_dir = "docs",
  quiet = FALSE
)

cat("Finished full webbook render at", format(Sys.time()), "\n")
