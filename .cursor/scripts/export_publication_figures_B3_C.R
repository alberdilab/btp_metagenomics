#!/usr/bin/env Rscript
# Export B3 and C2–C5 publication PDFs.

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

# B3
alpha_div_fig <- calculate_alpha_diversity(
  genome_counts_fig, genome_tree, genome_gifts, GIFT_db
)
alpha_env_hill_fig <- prepare_alpha_env_hill_data(alpha_div_fig, sample_metadata_fig)

fig_B3_panels <- tidyr::expand_grid(
  alpha_var = names(alpha_metric_labels),
  env_var = names(env_hill_column_map())
) %>%
  purrr::pmap(function(alpha_var, env_var) {
    create_alpha_env_hill_scatter(
      alpha_env_hill_fig,
      alpha_var = alpha_var,
      env_var = env_var,
      alpha_lab = alpha_metric_labels[[alpha_var]],
      env_lab = env_hill_metric_labels[[env_hill_column_map()[[env_var]]]],
      env_settings = env_settings,
      theme_fn = theme_publication
    ) +
      labs(title = alpha_metric_labels[[alpha_var]])
  })

fig_B3 <- patchwork::wrap_plots(fig_B3_panels, ncol = 3, nrow = 4) +
  plot_layout(guides = "collect")

save_publication_figure(fig_B3, "fig_B3_alpha_env_hill.pdf", height_mm = 200)

# C2
fig_C2_panels <- purrr::imap(
  beta_metric_labels,
  ~ create_nmds_plot(
    beta_matrix = beta_mats_fig[[.y]],
    sample_metadata = sample_metadata_fig,
    env_settings = env_settings,
    xlim = nmds_limits_fig$xlim,
    ylim = nmds_limits_fig$ylim,
    panel_tag = .x,
    show_ellipses = TRUE,
    theme_fn = theme_publication
  ) + theme(
    legend.position = if (.y == names(beta_metric_labels)[1]) "bottom" else "none",
    plot.title = element_text(size = 9, face = "bold", inherit.blank = TRUE)
  )
)

fig_C2 <- (fig_C2_panels[[1]] | fig_C2_panels[[2]]) /
  (fig_C2_panels[[3]] | fig_C2_panels[[4]]) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A")

save_publication_figure(fig_C2, "fig_C2_beta_nmds_ellipses.pdf", height_mm = 140)

# C3
env_hill_vars_fig <- names(env_hill_column_map())
fig_C3_panels <- purrr::imap(
  beta_metric_labels,
  ~ create_nmds_plot(
    beta_matrix = beta_mats_fig[[.y]],
    sample_metadata = sample_metadata_fig,
    env_settings = env_settings,
    xlim = nmds_limits_fig$xlim,
    ylim = nmds_limits_fig$ylim,
    panel_tag = .x,
    show_centroids = FALSE,
    env_vars = env_hill_vars_fig,
    theme_fn = theme_publication
  ) + theme(
    legend.position = if (.y == names(beta_metric_labels)[1]) "bottom" else "none",
    plot.title = element_text(size = 9, face = "bold", inherit.blank = TRUE)
  )
)

fig_C3 <- (fig_C3_panels[[1]] | fig_C3_panels[[2]]) /
  (fig_C3_panels[[3]] | fig_C3_panels[[4]]) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A")

save_publication_figure(fig_C3, "fig_C3_beta_nmds_envfit.pdf", height_mm = 140)

# C4
permanova_fig <- summarise_permanova_figures(beta_mats_fig, sample_metadata_fig)
fig_C4 <- create_permanova_r2_plot(permanova_fig, theme_fn = theme_publication)
save_publication_figure(fig_C4, "fig_C4_permanova_r2.pdf", height_mm = 120)

# C5
mantel_fig <- summarise_mantel_figures(beta_mats_fig, sample_metadata_fig)
fig_C5 <- create_mantel_summary_plot(mantel_fig, theme_fn = theme_publication)
save_publication_figure(fig_C5, "fig_C5_mantel_summary.pdf", height_mm = 100)

cat("Exported B3 and C2–C5 to figures/\n")
