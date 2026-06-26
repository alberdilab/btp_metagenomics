#!/usr/bin/env Rscript
# Export G1, G1b (env-only + env+HMSC), and G2 circular community phylogeny figures.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(ggtree)
  library(ggtreeExtra)
  library(ggnewscale)
  library(cowplot)
  library(patchwork)
  library(phytools)
  library(ape)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/publication_base.Rdata")
load("data/publication_hmsc.Rdata")

if (!exists("phylum_colors")) {
  phylum_colors <- readr::read_tsv(
    "https://raw.githubusercontent.com/earthhologenome/EHI_taxonomy_colour/main/ehi_phylum_colors.tsv",
    show_col_types = FALSE
  ) %>%
    tibble::deframe()
}

study_genomes_fig <- study_genome_ids(genome_counts_fig)
beta_ci_list <- prepare_hmsc_context_beta_ci_list(
  devil_ci = devil_ci_fig,
  temperature_ci = temp_ci_fig,
  diversity_ci = diversity_ci_fig,
  post_table = post_table
)

cat("Study genomes:", length(study_genomes_fig), "\n")
cat("Tree overlap:", length(intersect(study_genomes_fig, genome_tree$tip.label)), "\n")

fig_G1 <- create_circular_community_phylogeny_plot(
  genome_tree = genome_tree,
  genome_metadata = genome_metadata,
  genome_ids = study_genomes_fig,
  genome_counts = genome_counts_fig,
  phylum_colors = phylum_colors
)

if (is.null(fig_G1)) {
  stop("G1 plot is NULL — no overlapping tips.", call. = FALSE)
}

g1_dims <- circular_phylogeny_figure_dims(n_tips = length(study_genomes_fig))
save_publication_figure(
  plot = fig_G1,
  filename = "fig_G1_circular_phylogeny.pdf",
  width_mm = g1_dims$width_mm,
  height_mm = g1_dims$height_mm,
  tight_layout = TRUE
)
cat("Exported figures/fig_G1_circular_phylogeny.pdf\n")

fig_G1b_env <- create_circular_community_phylogeny_environment_plot(
  genome_tree = genome_tree,
  genome_metadata = genome_metadata,
  genome_counts = genome_counts_fig,
  sample_metadata = sample_metadata_fig,
  genome_ids = study_genomes_fig,
  phylum_colors = phylum_colors
)

if (is.null(fig_G1b_env)) {
  stop("G1b env-only plot is NULL — no overlapping tips.", call. = FALSE)
}

g1b_dims <- circular_phylogeny_detailed_figure_dims(n_tips = length(study_genomes_fig))
save_publication_figure(
  plot = fig_G1b_env,
  filename = "fig_G1b_circular_phylogeny_env_rings.pdf",
  width_mm = g1b_dims$width_mm,
  height_mm = g1b_dims$height_mm,
  tight_layout = TRUE
)
save_publication_figure(
  plot = fig_G1b_env,
  filename = "fig_G1b_circular_phylogeny_env_rings.png",
  width_mm = g1b_dims$width_mm,
  height_mm = g1b_dims$height_mm,
  tight_layout = TRUE
)
cat("Exported figures/fig_G1b_circular_phylogeny_env_rings.pdf\n")
cat("Exported figures/fig_G1b_circular_phylogeny_env_rings.png\n")

fig_G1b_hmsc <- create_circular_community_phylogeny_environment_plot(
  genome_tree = genome_tree,
  genome_metadata = genome_metadata,
  genome_counts = genome_counts_fig,
  sample_metadata = sample_metadata_fig,
  post_table = post_table,
  beta_ci_list = beta_ci_list,
  genome_ids = study_genomes_fig,
  phylum_colors = phylum_colors
)

if (is.null(fig_G1b_hmsc)) {
  stop("G1b env+HMSC plot is NULL — no overlapping tips.", call. = FALSE)
}

g1b_hmsc_dims <- circular_phylogeny_g1b_figure_layout(
  n_tips = length(study_genomes_fig),
  show_hmsc_legend = TRUE
)
save_publication_figure(
  plot = fig_G1b_hmsc,
  filename = "fig_G1b_circular_phylogeny_env_hmsc_rings.pdf",
  width_mm = g1b_hmsc_dims$width_mm,
  height_mm = g1b_hmsc_dims$height_mm,
  tight_layout = TRUE
)
save_publication_figure(
  plot = fig_G1b_hmsc,
  filename = "fig_G1b_circular_phylogeny_env_hmsc_rings.png",
  width_mm = g1b_hmsc_dims$width_mm,
  height_mm = g1b_hmsc_dims$height_mm,
  tight_layout = TRUE
)
cat("Exported figures/fig_G1b_circular_phylogeny_env_hmsc_rings.pdf\n")
cat("Exported figures/fig_G1b_circular_phylogeny_env_hmsc_rings.png\n")

fig_G2 <- create_circular_community_phylogeny_detailed_plot(
  genome_tree = genome_tree,
  genome_metadata = genome_metadata,
  genome_ids = study_genomes_fig,
  phylum_colors = phylum_colors
)

if (is.null(fig_G2)) {
  stop("G2 plot is NULL — no overlapping tips.", call. = FALSE)
}

g2_dims <- circular_phylogeny_detailed_figure_dims(n_tips = length(study_genomes_fig))
save_publication_figure(
  plot = fig_G2,
  filename = "fig_G2_circular_phylogeny_rings.pdf",
  width_mm = g2_dims$width_mm,
  height_mm = g2_dims$height_mm,
  tight_layout = TRUE
)
cat("Exported figures/fig_G2_circular_phylogeny_rings.pdf\n")
