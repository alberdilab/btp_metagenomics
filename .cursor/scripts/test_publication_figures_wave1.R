#!/usr/bin/env Rscript
# Verify wave-1 publication figure helpers produce expected outputs.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(ggpubr)
  library(patchwork)
  library(vegan)
  library(ape)
  library(hilldiv2)
  library(distillR)
  library(purrr)
  library(stringr)
})

source("R/plot_helpers.R")

load("data/data.Rdata")
load("data/beta.Rdata")

landcover_wide <- read_csv("landcover_wide.csv", show_col_types = FALSE) %>%
  rename(sample = id)

filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(
    broad_environment = factor(
      broad_environment,
      levels = environment_plot_settings()$limits
    )
  )
genome_counts_fig <- filtered$genome_counts
env_settings <- environment_plot_settings()

stopifnot(!"EHI01340" %in% sample_metadata_fig$sample)

# --- A3 landcover ---
landcover_plot_df <- prepare_landcover_plot_df(
  landcover_wide,
  sample_ids = sample_metadata_fig$sample
)
stopifnot(nrow(landcover_plot_df) > 0)
stopifnot(all(abs(landcover_plot_df %>% group_by(sample) %>% summarise(s = sum(pct)) %>% pull(s) - 100) < 0.01))
stopifnot(!any(landcover_plot_df$group == "Water", na.rm = TRUE))

fig_A3 <- create_landcover_stacked_bar(
  landcover_plot_df,
  sample_order = sample_metadata_fig %>% arrange(broad_environment, sample) %>% pull(sample) %>% unique(),
  theme_fn = theme_publication
)
stopifnot(inherits(fig_A3, "ggplot"))

# --- B1 alpha ---
alpha_div_fig <- calculate_alpha_diversity(
  genome_counts = genome_counts_fig,
  genome_tree = genome_tree,
  genome_gifts = genome_gifts,
  GIFT_db = GIFT_db
)
stopifnot(all(c("richness", "neutral", "phylogenetic", "functional") %in% names(alpha_div_fig)))
stopifnot(nrow(alpha_div_fig) == nrow(sample_metadata_fig))

fig_B1_test <- create_alpha_environment_plot(
  alpha_div = alpha_div_fig,
  sample_metadata = sample_metadata_fig,
  target_metric = "richness",
  env_settings = env_settings,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_B1_test, "ggplot"))

# --- C1 NMDS ---
beta_mats <- list(beta_q0n, beta_q1n, beta_q1p, beta_q1f)
nmds_limits <- calculate_nmds_limits(beta_mats)
stopifnot(!is.null(nmds_limits$xlim), !is.null(nmds_limits$ylim))

fig_C1_test <- create_nmds_plot(
  beta_matrix = beta_q0n,
  sample_metadata = sample_metadata_fig,
  env_settings = env_settings,
  xlim = nmds_limits$xlim,
  ylim = nmds_limits$ylim,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_C1_test, "ggplot"))

# Export smoke test
dir.create("figures", showWarnings = FALSE)
save_publication_figure(fig_A3, "test_fig_A3.pdf", height_mm = 80)
save_publication_figure(fig_B1_test, "test_fig_B1_panel.pdf", height_mm = 80)
save_publication_figure(fig_C1_test, "test_fig_C1_panel.pdf", height_mm = 80)
stopifnot(file.exists("figures/test_fig_A3.pdf"))

unlink(c("figures/test_fig_A3.pdf", "figures/test_fig_B1_panel.pdf", "figures/test_fig_C1_panel.pdf"))

cat("PASS: wave-1 publication figure helpers\n")
