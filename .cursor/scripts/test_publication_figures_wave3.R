#!/usr/bin/env Rscript
# Verify wave-3 landcover / env Hill helpers (D1–D3); D4 ANCOM optional.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(ggplot2)
  library(patchwork)
  library(purrr)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/hill.Rdata")

landcover_wide <- read_csv("landcover_wide.csv", show_col_types = FALSE) %>%
  rename(sample = id)

filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata
genome_counts_fig <- filtered$genome_counts

hill_long_fig <- hill_long %>%
  rename(sample = id) %>%
  filter(sample != "EHI01340")

hill_wide_fig <- hill_long_fig %>%
  pivot_wider(
    id_cols = sample,
    names_from = q,
    values_from = value,
    names_glue = "env_hill_{q}"
  )

sample_metadata_fig <- sample_metadata_fig %>%
  left_join(
    landcover_wide %>% select(sample, any_of(names(landcover_summary_vars()))),
    by = "sample"
  )

hill_landcover_fig <- hill_long_fig %>%
  left_join(
    sample_metadata_fig %>% select(sample, any_of(names(landcover_summary_vars()))),
    by = "sample"
  )

fine_broad_hill_fig <- prepare_fine_broad_hill_compare(
  hill_long_fig,
  landcover_wide,
  sample_ids = sample_metadata_fig$sample
)

stopifnot(nrow(fine_broad_hill_fig) == nrow(hill_long_fig))
stopifnot(all(c("value_fine", "value_broad") %in% names(fine_broad_hill_fig)))
stopifnot(cor(fine_broad_hill_fig$value_fine, fine_broad_hill_fig$value_broad) > 0)

stopifnot(inherits(create_env_hill_distribution_plot(hill_long_fig), "ggplot"))
stopifnot(inherits(
  create_landcover_hill_scatter(
    filter(hill_landcover_fig, q == "h1"),
    "Cultivated_Total",
    "Cultivated (%)"
  ),
  "ggplot"
))
stopifnot(inherits(create_fine_broad_hill_scatter(fine_broad_hill_fig, "h1"), "ggplot"))

# D2 panel filter must subset one Hill level per panel (not q == q column self-compare)
d2_panel_rows <- purrr::pmap(
  expand_grid(q = names(env_hill_metric_labels), lc_var = c("Cultivated_Total", "Native_Terrestrial_Total")),
  function(q_level, lc_var) {
    hill_landcover_fig %>% dplyr::filter(.data$q == q_level) %>% nrow()
  }
) %>% unlist()
stopifnot(all(d2_panel_rows == nrow(hill_landcover_fig) / length(env_hill_metric_labels)))

dir.create("figures", showWarnings = FALSE)
save_publication_figure(
  create_env_hill_distribution_plot(hill_long_fig),
  "test_fig_D1.pdf",
  height_mm = 80
)
unlink("figures/test_fig_D1.pdf")

if (requireNamespace("ANCOMBC", quietly = TRUE) &&
    requireNamespace("phyloseq", quietly = TRUE)) {
  suppressPackageStartupMessages({ library(phyloseq); library(ANCOMBC) })
  inputs <- prepare_env_ancom_inputs(
    sample_metadata_fig %>% left_join(hill_wide_fig, by = "sample"),
    genome_counts_fig,
    hill_wide_fig
  )
  stopifnot(length(inputs) == 3)
  ps_list <- build_env_ancom_phyloseq(inputs, genome_metadata)
  stopifnot(length(ps_list) == 3)
  cat("D4 prep structures OK (ANCOMBC run skipped in quick test)\n")
}

cat("PASS: wave-3 env/landcover figure helpers\n")
