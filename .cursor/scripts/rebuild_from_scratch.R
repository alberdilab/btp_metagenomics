#!/usr/bin/env Rscript
# Full clean rebuild: remove derived artifacts, knit chapters 01–13, cache HMSC
# publication data, then render the complete webbook (including chapter 15).
#
# Usage (from project root):
#   Rscript .cursor/scripts/rebuild_from_scratch.R
#   Rscript .cursor/scripts/rebuild_from_scratch.R --skip-clean
#   Rscript .cursor/scripts/rebuild_from_scratch.R --dry-run
#
# Expect several hours on a laptop (chapter 05 landcover extraction is the bottleneck).

args <- commandArgs(trailingOnly = TRUE)
dry_run <- "--dry-run" %in% args
skip_clean <- "--skip-clean" %in% args

if (!dir.exists("data") || !file.exists("_bookdown.yml")) {
  stop("Run this script from the project root (btp_metagenomics/).", call. = FALSE)
}
project_root <- normalizePath(".")

options(timeout = max(600, getOption("timeout")))

pandoc_dir <- file.path(project_root, "tools", "pandoc-3.6.4-arm64", "bin")
if (dir.exists(pandoc_dir)) {
  Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
}
if (!rmarkdown::pandoc_available()) {
  stop("Pandoc is required. Install pandoc or use tools/pandoc-3.6.4-arm64.", call. = FALSE)
}

raw_inputs <- c(
  "data/merged_metadata.tsv",
  "data/sample_sites.csv",
  "data/DMB0167_counts.tsv.gz",
  "data/DMB0167_mag_info.tsv.gz",
  "data/DMB0167_coverage.tsv.gz",
  "data/DMB0167.tree.gz",
  "data/model_final_genomes.tsv"
)
missing_raw <- raw_inputs[!file.exists(raw_inputs)]
if (length(missing_raw) > 0) {
  stop(
    "Missing raw pipeline inputs:\n  ",
    paste(missing_raw, collapse = "\n  "),
    "\n\nPlace pipeline outputs in data/ before rebuilding.",
    call. = FALSE
  )
}

if (!file.exists("data/genome_annotations.tsv.xz")) {
  message(
    "Note: data/genome_annotations.tsv.xz not found. ",
    "Chapter 01 will try to download from Airtable (requires network + token)."
  )
}

landcover_dir <- "Landcover/Tif"
if (!dir.exists(landcover_dir) || length(list.files(landcover_dir, pattern = "\\.tif$")) == 0) {
  message(
    "Note: ", landcover_dir, " GeoTIFFs not found. ",
    "Chapter 09 will download landcover rasters (slow, needs network)."
  )
}

if (dry_run) {
  cat("=== Dry run: rebuild_from_scratch ===\n\n")
  cat("1. clean_derived_artifacts.R", if (skip_clean) "(skipped)" else "", "\n")
  cat("2. bookdown render chapters 01–14\n")
  cat("3. (optional) cache_publication_data.R if ch14 HMSC cache missing\n")
  cat("4. bookdown render full webbook → docs/\n\n")
  system2("Rscript", c(".cursor/scripts/clean_derived_artifacts.R", "--dry-run"))
  quit(status = 0)
}

cat("=== Rebuild from scratch ===\n")
cat("Started:", format(Sys.time()), "\n")
cat("Working directory:", getwd(), "\n\n")

if (!skip_clean) {
  cat("--- Step 1/4: clean derived artifacts ---\n")
  status <- system2("Rscript", ".cursor/scripts/clean_derived_artifacts.R", stdout = "", stderr = "")
  if (!identical(status, 0L)) stop("clean_derived_artifacts.R failed.", call. = FALSE)
}

bookdown_yml <- file.path(project_root, "_bookdown.yml")
cfg <- yaml::read_yaml(bookdown_yml)
all_chapters <- cfg$rmd_files
chapters_01_14 <- all_chapters[seq_len(which(all_chapters == "14_hmsc_analysis_final.Rmd"))]

cat("\n--- Step 2/4: knit chapters 01–14 ---\n")
cat("Chapters:", paste(chapters_01_14, collapse = ", "), "\n\n")

suppressPackageStartupMessages(library(bookdown))

bookdown::render_book(
  input = ".",
  output_format = "bookdown::gitbook",
  output_dir = "docs",
  quiet = FALSE,
  config = list(bookdown = list(rmd_files = chapters_01_14))
)

required_after_14 <- c(
  "data/data.Rdata",
  "data/beta.Rdata",
  "landcover_wide.csv",
  "data/hill.Rdata",
  "data/publication_base.Rdata",
  "data/animal_var.csv",
  "data/environment_var_r200.csv",
  "hmsc/model_final",
  "data/publication_hmsc.Rdata"
)
missing_mid <- required_after_14[!file.exists(required_after_14)]
if (length(missing_mid) > 0) {
  stop(
    "Chapters 01–14 did not produce expected artifacts:\n  ",
    paste(missing_mid, collapse = "\n  "),
    call. = FALSE
  )
}

cat("\n--- Step 3/4: build publication HMSC cache (if chapter 14 did not) ---\n")
if (!file.exists("data/publication_hmsc.Rdata")) {
  status <- system2("Rscript", ".cursor/scripts/cache_publication_data.R", stdout = "", stderr = "")
  if (!identical(status, 0L)) {
    stop(
      "cache_publication_data.R failed. Check network access to ERDA ",
      "(https://sid.erda.dk/share_redirect/Gh0WbM42c4/Hmsc_model_final.rds).",
      call. = FALSE
    )
  }
} else {
  cat("publication_hmsc.Rdata already present (from chapter 14).\n")
}

cat("\n--- Step 4/4: knit full webbook (including chapter 15) ---\n")
bookdown::render_book(
  input = ".",
  output_format = "bookdown::gitbook",
  output_dir = "docs",
  quiet = FALSE
)

cat("\n=== Rebuild complete ===\n")
cat("Finished:", format(Sys.time()), "\n")
cat("Webbook output: docs/\n")
cat("Publication figures: figures/fig_*.pdf\n")
