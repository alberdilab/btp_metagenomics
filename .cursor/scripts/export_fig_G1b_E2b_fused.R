#!/usr/bin/env Rscript
# Fused G1b circular phylogeny + E2b family Sankey (shared phylum legend on G1b only).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(patchwork)
  library(cowplot)
  library(ggalluvial)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/publication_base.Rdata")

phylum_colors <- load_phylum_colors_fallback()
study_genomes_fig <- study_genome_ids(genome_counts_fig)

fig_G1b <- create_circular_community_phylogeny_environment_plot(
  genome_tree = genome_tree,
  genome_metadata = genome_metadata,
  genome_counts = genome_counts_fig,
  sample_metadata = sample_metadata_fig,
  genome_ids = study_genomes_fig,
  phylum_colors = phylum_colors
)

if (is.null(fig_G1b)) {
  stop("G1b plot is NULL — no overlapping tree tips.", call. = FALSE)
}

family_sankey_fig <- prepare_family_sankey_data(
  genome_counts_fig,
  genome_metadata,
  n_top = 18
)

fig_E2b_no_legend <- create_family_sankey_plot(
  family_sankey_fig,
  phylum_colors = phylum_colors,
  legend_position = "none",
  theme_fn = theme_publication
)

fig_fused <- compose_phylogeny_family_sankey_figure(
  phylogeny_plot = fig_G1b,
  sankey_plot = fig_E2b_no_legend
)

fused_dims <- phylogeny_family_sankey_figure_dims(n_tips = length(study_genomes_fig))

save_publication_figure(
  plot = fig_fused,
  filename = "fig_G1b_E2b_phylogeny_family_sankey.png",
  width_mm = fused_dims$width_mm,
  height_mm = fused_dims$height_mm
)

cat(
  "Exported figures/fig_G1b_E2b_phylogeny_family_sankey.png (",
  fused_dims$width_mm, " x ", fused_dims$height_mm, " mm)\n",
  sep = ""
)
