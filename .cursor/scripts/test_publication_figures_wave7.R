#!/usr/bin/env Rscript
# Verify wave-7 helpers: B3 alpha-env Hill + C2–C5 beta diversity figures.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(patchwork)
  library(vegan)
  library(ape)
  library(hilldiv2)
  library(distillR)
  library(purrr)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/beta.Rdata")
load("data/hill.Rdata")

env_settings <- environment_plot_settings()
filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(broad_environment = factor(broad_environment, levels = env_settings$limits))
genome_counts_fig <- filtered$genome_counts

hill_wide_fig <- hill_long %>%
  rename(sample = id) %>%
  filter(sample != "EHI01340") %>%
  pivot_wider(
    id_cols = sample,
    names_from = q,
    values_from = value,
    names_glue = "env_hill_{q}"
  )

sample_metadata_fig <- sample_metadata_fig %>%
  left_join(hill_wide_fig, by = "sample")

beta_mats_fig <- list(
  beta_q0n = beta_q0n,
  beta_q1n = beta_q1n,
  beta_q1p = beta_q1p,
  beta_q1f = beta_q1f
)

nmds_limits_fig <- calculate_nmds_limits(beta_mats_fig)

# --- B3 ---
alpha_div_fig <- calculate_alpha_diversity(
  genome_counts_fig, genome_tree, genome_gifts, GIFT_db
)
alpha_env_hill_fig <- prepare_alpha_env_hill_data(alpha_div_fig, sample_metadata_fig)
stopifnot(all(c("env_hill_h0", "env_hill_h1", "env_hill_h2") %in% names(alpha_env_hill_fig)))

fig_B3 <- create_alpha_env_hill_scatter(
  alpha_env_hill_fig,
  alpha_var = "richness",
  env_var = "env_hill_h0",
  env_settings = env_settings,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_B3, "ggplot"))

# --- C2 ellipses ---
fig_C2 <- create_nmds_plot(
  beta_q0n,
  sample_metadata_fig,
  env_settings = env_settings,
  show_ellipses = TRUE,
  xlim = nmds_limits_fig$xlim,
  ylim = nmds_limits_fig$ylim,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_C2, "ggplot"))

# --- C3 envfit ---
fig_C3 <- create_nmds_plot(
  beta_q0n,
  sample_metadata_fig,
  env_settings = env_settings,
  env_vars = names(env_hill_column_map()),
  xlim = nmds_limits_fig$xlim,
  ylim = nmds_limits_fig$ylim,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_C3, "ggplot"))

# --- C4 permanova ---
permanova_fig <- summarise_permanova_figures(beta_mats_fig, sample_metadata_fig)
stopifnot(nrow(permanova_fig) > 0)
stopifnot(all(c("term", "r2", "p_value", "beta_metric") %in% names(permanova_fig)))
fig_C4 <- create_permanova_r2_plot(permanova_fig, theme_fn = theme_publication)
stopifnot(inherits(fig_C4, "ggplot"))

# --- C5 mantel ---
mantel_fig <- summarise_mantel_figures(beta_mats_fig, sample_metadata_fig)
stopifnot(nrow(mantel_fig) == 12)
fig_C5 <- create_mantel_summary_plot(mantel_fig, theme_fn = theme_publication)
stopifnot(inherits(fig_C5, "ggplot"))

cat("PASS: wave-7 publication figure helpers (B3 + C2–C5)\n")
