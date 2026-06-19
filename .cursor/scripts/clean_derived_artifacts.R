#!/usr/bin/env Rscript
# Remove derived analysis artifacts so chapters can rebuild them from raw inputs.
# Does NOT delete pipeline outputs, pinned genome lists, or landcover GeoTIFFs.

args <- commandArgs(trailingOnly = TRUE)
dry_run <- "--dry-run" %in% args

if (!dir.exists("data") || !file.exists("_bookdown.yml")) {
  stop("Run this script from the project root (btp_metagenomics/).", call. = FALSE)
}
project_root <- normalizePath(".")

files_to_remove <- c(
  "data/data.Rdata",
  "data/beta.Rdata",
  "data/hill.Rdata",
  "data/publication_base.Rdata",
  "data/publication_hmsc.Rdata",
  "data/enviromental_var.Rdata",
  "landcover_wide.csv",
  "data/climate_ms.csv",
  "data/pop_density_ms.csv",
  "data/devil_density_baseline_ms.csv",
  "data/enviromental_var.csv",
  "data/enviromental_var.tsv",
  "data/enviromental_var_ms.csv",
  "data/animal_var.csv",
  "data/environment_var_r200.csv",
  "data/environment_var_r100.csv",
  "data/environment_var_r400.csv",
  "hmsc/model_final"
)

dirs_to_remove <- c(
  "data/hsmc_scales",
  "docs"
)

figure_glob <- list.files("figures", pattern = "^fig_.*\\.(pdf|png)$", full.names = TRUE)

cat(if (dry_run) "Dry run — would remove:\n" else "Removing derived artifacts:\n")

for (path in files_to_remove) {
  if (!file.exists(path)) next
  cat(" ", path, "\n", sep = "")
  if (!dry_run) unlink(path)
}

for (path in dirs_to_remove) {
  if (!dir.exists(path)) next
  cat(" ", path, "/\n", sep = "")
  if (!dry_run) unlink(path, recursive = TRUE)
}

for (path in figure_glob) {
  cat(" ", path, "\n", sep = "")
  if (!dry_run) unlink(path)
}

if (dry_run) {
  cat("\nRe-run without --dry-run to delete these files.\n")
} else {
  cat("\nDerived artifacts removed. Raw inputs unchanged.\n")
}
