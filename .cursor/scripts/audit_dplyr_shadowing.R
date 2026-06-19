#!/usr/bin/env Rscript
# Flag dplyr filters where a function argument can be shadowed by a data column.

scan_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  issues <- character()

  # .data$col == col (RHS is exactly the same identifier, not .env$col)
  idx <- grep("\\.data\\$([A-Za-z_.]+) == \\1([^A-Za-z_.]|$)", lines, perl = TRUE)
  for (ln in idx) {
    issues <- c(issues, sprintf("%s:%d %s", path, ln, trimws(lines[ln])))
  }

  issues
}

paths <- c(
  "R/plot_helpers.R",
  "15_publication_figures.Rmd",
  "14_hmsc_analysis_final.Rmd"
)
paths <- paths[file.exists(paths)]

all_issues <- unlist(lapply(paths, scan_file), use.names = FALSE)

if (length(all_issues) == 0) {
  cat("Shadowing scan PASS: no .data$col == col patterns without .env$\n")
  quit(status = 0)
}

cat("Shadowing scan FAIL (", length(all_issues), "):\n", sep = "")
for (x in all_issues) cat(" ", x, "\n", sep = "")
quit(status = 1)
