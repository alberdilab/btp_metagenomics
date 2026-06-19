#!/usr/bin/env Rscript
# Export E1–E3 publication PDFs.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(patchwork)
  library(purrr)
  library(ggalluvial)
})

source("R/plot_helpers.R")

load("data/data.Rdata")
phylum_colors <- load_phylum_colors_fallback()

filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(
    broad_environment = factor(
      broad_environment,
      levels = environment_plot_settings()$limits
    )
  )
genome_counts_fig <- filtered$genome_counts

sample_order_fig <- sample_metadata_fig %>%
  arrange(broad_environment, sample) %>%
  pull(sample) %>%
  unique()

fig_E1 <- create_phylum_stacked_bar(
  prepare_phylum_stacked_data(
    genome_counts_fig, genome_metadata, sample_metadata_fig,
    sample_order = sample_order_fig, n_top = 12
  ),
  phylum_colors = phylum_colors,
  theme_fn = theme_publication
)

fig_E2 <- create_family_sankey_plot(
  prepare_family_sankey_data(genome_counts_fig, genome_metadata, n_top = 18),
  phylum_colors = phylum_colors,
  theme_fn = theme_publication
)

fig_E3 <- create_dominant_mag_tile_plot(
  prepare_dominant_mag_tile_data(
    genome_counts_fig, genome_metadata, sample_metadata_fig,
    n_mags = 35, sample_order = sample_order_fig
  ),
  phylum_colors = phylum_colors,
  theme_fn = theme_publication
)

save_publication_figure(fig_E1, "fig_E1_phylum_stacked.pdf", height_mm = 110)
save_publication_figure(fig_E2, "fig_E2_family_sankey.pdf", height_mm = 130)
save_publication_figure(fig_E3, "fig_E3_dominant_mag_tile.pdf", height_mm = 140)

cat("Exported E1–E3 to figures/\n")
