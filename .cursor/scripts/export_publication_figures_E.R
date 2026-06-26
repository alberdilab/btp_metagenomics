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
env_order <- phylum_stacked_environment_order(filtered$metadata)
sample_metadata_fig <- filtered$metadata %>%
  mutate(
    broad_environment = factor(
      broad_environment,
      levels = env_order
    )
  )
genome_counts_fig <- filtered$genome_counts

sample_order_fig <- sample_metadata_fig %>%
  arrange(broad_environment, sample) %>%
  pull(sample) %>%
  unique()

phylum_stack_fig <- prepare_phylum_stacked_data(
  genome_counts_fig, genome_metadata, sample_metadata_fig,
  sample_order = sample_order_fig
)

fig_E1 <- create_phylum_stacked_bar(
  phylum_stack_fig,
  phylum_colors = phylum_colors,
  facet_env = FALSE,
  style = "chapter"
)

fig_E1b <- create_phylum_stacked_bar(
  phylum_stack_fig,
  phylum_colors = phylum_colors,
  facet_env = TRUE,
  style = "chapter"
)

family_sankey_fig <- prepare_family_sankey_data(
  genome_counts_fig, genome_metadata, n_top = 18
)

fig_E2 <- create_family_sankey_plot(
  family_sankey_fig,
  phylum_colors = phylum_colors,
  legend_position = "bottom",
  theme_fn = theme_publication
)

fig_E2b <- create_family_sankey_plot(
  family_sankey_fig,
  phylum_colors = phylum_colors,
  legend_position = "left",
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

e1_dims <- phylum_stacked_figure_dims(facet_env = FALSE)
e1b_dims <- phylum_stacked_figure_dims(facet_env = TRUE)

save_publication_figure(
  fig_E1, "fig_E1_phylum_stacked.pdf",
  width_mm = e1_dims$width_mm, height_mm = e1_dims$height_mm
)
save_publication_figure(
  fig_E1, "fig_E1_phylum_stacked.png",
  width_mm = e1_dims$width_mm, height_mm = e1_dims$height_mm
)
save_publication_figure(
  fig_E1b, "fig_E1b_phylum_stacked_faceted.pdf",
  width_mm = e1b_dims$width_mm, height_mm = e1b_dims$height_mm
)
save_publication_figure(
  fig_E1b, "fig_E1b_phylum_stacked_faceted.png",
  width_mm = e1b_dims$width_mm, height_mm = e1b_dims$height_mm
)
save_publication_figure(fig_E2, "fig_E2_family_sankey.pdf", height_mm = 145)
save_publication_figure(fig_E2, "fig_E2_family_sankey.png", height_mm = 145)
save_publication_figure(fig_E2b, "fig_E2b_family_sankey_legend_left.pdf", height_mm = 145)
save_publication_figure(fig_E2b, "fig_E2b_family_sankey_legend_left.png", height_mm = 145)
save_publication_figure(fig_E3, "fig_E3_dominant_mag_tile.pdf", height_mm = 140)

cat("Exported E1–E3 to figures/\n")
