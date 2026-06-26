#!/usr/bin/env Rscript
# Extended diagnostics beyond audit_publication_figures.R

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(ggplot2)
  library(ape)
  library(vegan)
  library(hilldiv2)
  library(distillR)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/beta.Rdata")
load("data/hill.Rdata")

issues <- character()
landcover_wide <- read_csv("landcover_wide.csv", show_col_types = FALSE) %>%
  rename(sample = id)
filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
meta <- filtered$metadata %>%
  mutate(broad_environment = factor(broad_environment, levels = environment_plot_settings()$limits))
counts <- filtered$genome_counts

if ("EHI01340" %in% meta$sample) issues <- c(issues, "EHI01340 in metadata")
if ("EHI01340" %in% colnames(counts)) issues <- c(issues, "EHI01340 in counts")

stack <- prepare_phylum_stacked_data(counts, genome_metadata, meta)
stack_sums <- stack %>% group_by(sample) %>% summarise(s = sum(count), .groups = "drop")
if (max(abs(stack_sums$s - 1)) > 0.01) {
  issues <- c(issues, "E1: phylum stacks do not sum to 1")
}

phylum_sum <- prepare_taxonomy_relabun(counts, genome_metadata, meta, "phylum", "broad_environment")
genus_sum <- prepare_taxonomy_relabun(counts, genome_metadata, meta, "genus", c("phylum", "broad_environment"))
if (nrow(phylum_sum) == 0 || nrow(genus_sum) == 0) {
  issues <- c(issues, "E2: empty taxonomy summaries")
}

dom <- prepare_dominant_mag_tile_data(counts, genome_metadata, meta, n_mags = 35)
if (length(unique(dom$genome)) != 35) {
  issues <- c(issues, "E3: wrong MAG count")
}

hill_long_fig <- hill_long %>% rename(sample = id) %>% filter(sample != "EHI01340")
hill_landcover <- hill_long_fig %>%
  left_join(meta %>% select(sample, any_of(names(landcover_summary_vars()))), by = "sample")
expected_d2 <- nrow(hill_landcover) / length(env_hill_metric_labels)
for (ql in names(env_hill_metric_labels)) {
  n <- hill_landcover %>% filter(.data$q == ql) %>% nrow()
  if (n != expected_d2) {
    issues <- c(issues, sprintf("D2: wrong rows for %s: %d (expected %d)", ql, n, expected_d2))
  }
}

mock <- list(
  res = tibble(
    taxon = counts$genome[1:5],
    lfc_env_div_group0High = runif(5, -1, 1),
    p_env_div_group0High = runif(5, 0, 1)
  )
)
dt <- extract_ancombc_diff_table(mock, genome_metadata)
if (is.null(dt) || !"sig" %in% names(dt)) {
  issues <- c(issues, "D4: extract_ancombc_diff_table failed on mock output")
}

pdfs <- list.files("figures", pattern = "^fig_.*\\.pdf$", full.names = TRUE)
small <- pdfs[file.info(pdfs)$size < 2000]
if (length(small) > 0) {
  issues <- c(issues, paste("Small PDFs (<2KB):", paste(basename(small), collapse = ", ")))
}

rmd <- readLines("15_publication_figures.Rmd")
src <- grep('source\\("R/plot_helpers.R"\\)', rmd)[1]
flt <- grep("filter_study_samples", rmd)[1]
if (length(src) == 0 || length(flt) == 0 || src > flt) {
  issues <- c(issues, "Rmd: plot_helpers must be sourced before filter_study_samples")
}

# beta scatter visibility: significant points should be minority but non-zero
if (file.exists("hmsc/model_final")) {
  suppressPackageStartupMessages(library(Hmsc))
  load(file = "hmsc/model_final")
  tmp <- tempfile(fileext = ".rds")
  options(timeout = max(600, getOption("timeout")))
  tryCatch({
    download.file(
      "https://sid.erda.dk/share_redirect/Gh0WbM42c4/Hmsc_model_final.rds",
      tmp, mode = "wb", quiet = TRUE
    )
    fit <- importPosteriorFromHPC(m, readRDS(tmp)$list[1:4], 250, 1000, 250000)
    unlink(tmp)
    post_estimates <- getPostEstimate(hM = fit, parName = "Beta")$support %>%
      as.data.frame() %>%
      mutate(variable = m$covNames) %>%
      pivot_longer(!variable, names_to = "genome", values_to = "value") %>%
      mutate(value = case_when(
        value >= 0.9 ~ "Positive",
        value <= 0.1 ~ "Negative",
        TRUE ~ "Neutral"
      ))
    post_table <- post_estimates %>%
      mutate(value = factor(value, levels = c("Positive", "Neutral", "Negative"))) %>%
      pivot_wider(names_from = variable, values_from = value) %>%
      select(-`(Intercept)`) %>%
      column_to_rownames("genome")

    devil_beta <- prepare_beta_support_data(fit, m, "devil", genome_metadata, 0.9)
    n_sig <- sum(devil_beta$significant, na.rm = TRUE)
    if (n_sig == 0) issues <- c(issues, "F2: zero significant devil genomes")
    if (n_sig == nrow(devil_beta)) issues <- c(issues, "F2: all genomes marked significant")

    elements_response <- genome_gifts[rownames(post_table), colnames(genome_gifts) %in% GIFT_db$Code_bundle] %>%
      to.elements(., GIFT_db = GIFT_db) %>%
      as.data.frame() %>%
      rownames_to_column("genome") %>%
      pivot_longer(!genome, names_to = "GIFT", values_to = "value") %>%
      left_join(post_table %>% rownames_to_column("genome"), by = "genome")

    cong_func <- prepare_devil_temp_congruence_functional(elements_response, GIFT_db)
    if (any(cong_func$mean_val > 1, na.rm = TRUE)) {
      issues <- c(issues, "F5: functional congruence mean_val > 1 (alpha scale risk)")
    }
  }, error = function(e) {
    issues <<- c(issues, paste("HMSC extended checks skipped:", e$message))
  })
}

if (length(issues) == 0) {
  cat("DIAG PASS: no issues\n")
} else {
  cat("DIAG ISSUES (", length(issues), "):\n", sep = "")
  for (i in seq_along(issues)) cat(i, ". ", issues[i], "\n", sep = "")
  quit(status = 1)
}
