#!/usr/bin/env Rscript
# Test G1 (original) vs G1b (phylum + env presence + HMSC association rings).

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

setwd("/Users/lukasfix/Desktop/Backup for code/btp_metagenomics")
source("R/plot_helpers.R")

load("data/data.Rdata")
load("data/publication_base.Rdata")
load("data/publication_hmsc.Rdata")

if (!exists("phylum_colors")) {
  phylum_colors <- readr::read_tsv(
    "https://raw.githubusercontent.com/earthhologenome/EHI_taxonomy_colour/main/ehi_phylum_colors.tsv",
    show_col_types = FALSE
  ) %>% tibble::deframe()
}

filtered           <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata
genome_counts_fig  <- filtered$genome_counts
study_genomes_fig  <- study_genome_ids(genome_counts_fig)

cat("Study genomes:", length(study_genomes_fig), "\n")
cat("HMSC post_table genomes:", nrow(post_table), "\n")
cat("HMSC overlap with tree:", sum(rownames(post_table) %in% genome_tree$tip.label), "\n")
cat("Columns in post_table:", paste(colnames(post_table), collapse = ", "), "\n\n")

beta_ci_list <- prepare_hmsc_context_beta_ci_list(
  devil_ci = devil_ci_fig,
  temperature_ci = temp_ci_fig,
  diversity_ci = diversity_ci_fig,
  post_table = post_table
)

# ── G1: original (phylum + abundance bar) ───────────────────────────────────
cat("Building G1 (original)...\n")
fig_G1 <- create_circular_community_phylogeny_plot(
  genome_tree    = genome_tree,
  genome_metadata = genome_metadata,
  genome_ids     = study_genomes_fig,
  genome_counts  = genome_counts_fig,
  phylum_colors  = phylum_colors
)

# ── G1b env-only ────────────────────────────────────────────────────────────
cat("Building G1b (phylum + env presence)...\n")
fig_G1b_env <- create_circular_community_phylogeny_environment_plot(
  genome_tree     = genome_tree,
  genome_metadata = genome_metadata,
  genome_counts   = genome_counts_fig,
  sample_metadata = sample_metadata_fig,
  genome_ids      = study_genomes_fig,
  phylum_colors   = phylum_colors
)

# ── G1b env + HMSC ──────────────────────────────────────────────────────────
cat("Building G1b (phylum + env presence + HMSC)...\n")
fig_G1b_hmsc <- create_circular_community_phylogeny_environment_plot(
  genome_tree     = genome_tree,
  genome_metadata = genome_metadata,
  genome_counts   = genome_counts_fig,
  sample_metadata = sample_metadata_fig,
  post_table      = post_table,
  beta_ci_list    = beta_ci_list,
  genome_ids      = study_genomes_fig,
  phylum_colors   = phylum_colors
)

# Quick subset for visual inspection
test_tips <- intersect(
  rownames(post_table)[post_table$devil != "Neutral" | post_table$temperature != "Neutral"],
  study_genomes_fig
)
test_tips <- head(test_tips, 120)
cat("Building test subset (", length(test_tips), " tips with HMSC signal)...\n", sep = "")
fig_G1b_test <- create_circular_community_phylogeny_environment_plot(
  genome_tree     = genome_tree,
  genome_metadata = genome_metadata,
  genome_counts   = genome_counts_fig,
  sample_metadata = sample_metadata_fig,
  post_table      = post_table,
  beta_ci_list    = beta_ci_list,
  genome_ids      = test_tips,
  phylum_colors   = phylum_colors
)

if (is.null(fig_G1) || is.null(fig_G1b_env) || is.null(fig_G1b_hmsc) || is.null(fig_G1b_test)) {
  stop("One or more plots are NULL.", call. = FALSE)
}

g1_dims <- circular_phylogeny_figure_dims(n_tips = length(study_genomes_fig))
g1b_dims <- circular_phylogeny_detailed_figure_dims(n_tips = length(study_genomes_fig))
g1b_hmsc_dims <- circular_phylogeny_figure_dims(
  n_tips    = length(study_genomes_fig),
  legend_mm = 52
)
test_dims <- circular_phylogeny_figure_dims(
  n_tips    = length(test_tips),
  legend_mm = 52
)

save_publication_figure(
  plot      = fig_G1,
  filename  = "fig_G1_circular_phylogeny.pdf",
  width_mm  = g1_dims$width_mm,
  height_mm = g1_dims$height_mm
)
save_publication_figure(
  plot      = fig_G1b_env,
  filename  = "fig_G1b_circular_phylogeny_env_rings.pdf",
  width_mm  = g1b_dims$width_mm,
  height_mm = g1b_dims$height_mm
)
save_publication_figure(
  plot      = fig_G1b_hmsc,
  filename  = "fig_G1b_circular_phylogeny_env_hmsc_rings.pdf",
  width_mm  = g1b_hmsc_dims$width_mm,
  height_mm = g1b_hmsc_dims$height_mm
)
save_publication_figure(
  plot      = fig_G1b_test,
  filename  = "test_G1b_env_hmsc_rings.pdf",
  width_mm  = test_dims$width_mm,
  height_mm = test_dims$height_mm
)
save_publication_figure(
  plot      = fig_G1b_test,
  filename  = "test_G1b_env_hmsc_rings.png",
  width_mm  = test_dims$width_mm,
  height_mm = test_dims$height_mm,
  dpi       = 300
)

cat("\nExported:\n")
cat("  figures/fig_G1_circular_phylogeny.pdf                    (original)\n")
cat("  figures/fig_G1b_circular_phylogeny_env_rings.pdf       (phylum + env)\n")
cat("  figures/fig_G1b_circular_phylogeny_env_hmsc_rings.pdf  (phylum + env + HMSC)\n")
cat("  figures/test_G1b_env_hmsc_rings.pdf/.png               (120-tip HMSC test subset)\n")
