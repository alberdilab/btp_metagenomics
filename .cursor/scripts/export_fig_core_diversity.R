#!/usr/bin/env Rscript
# Export B1 and C1 diversity figures (PDF + PNG) at publication resolution.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(purrr)
})

source("R/plot_helpers.R")
load("data/publication_base.Rdata")

env_settings <- environment_plot_settings()
fig_dims <- four_panel_diversity_figure_dims()

fig_B1_panels <- imap(
  alpha_metric_labels,
  ~ create_alpha_environment_plot(
    alpha_div = alpha_div_fig,
    sample_metadata = sample_metadata_fig,
    target_metric = .y,
    ylab = .x,
    env_settings = env_settings,
    show_legend = FALSE,
    theme_fn = theme_publication
  )
)

fig_C1_panels <- imap(
  beta_metric_labels,
  ~ create_nmds_plot(
    beta_matrix = beta_mats_fig[[.y]],
    sample_metadata = sample_metadata_fig,
    env_settings = env_settings,
    xlim = nmds_limits_fig$xlim,
    ylim = nmds_limits_fig$ylim,
    nmds_obj = nmds_fits_fig[[.y]],
    panel_tag = .x,
    show_centroids = TRUE,
    theme_fn = theme_publication
  )
)

fig_B1 <- compose_four_panel_environment_figure(
  panels = fig_B1_panels,
  env_settings = env_settings
)

fig_C1 <- compose_four_panel_environment_figure(
  panels = fig_C1_panels,
  env_settings = env_settings,
  show_island_legend = TRUE
)

for (spec in list(
  list(fig = fig_B1, base = "fig_B1_alpha_diversity"),
  list(fig = fig_C1, base = "fig_C1_beta_nmds")
)) {
  save_publication_figure(
    plot = spec$fig,
    filename = paste0(spec$base, ".pdf"),
    width_mm = fig_dims$width_mm,
    height_mm = fig_dims$height_mm
  )
  save_publication_figure(
    plot = spec$fig,
    filename = paste0(spec$base, ".png"),
    width_mm = fig_dims$width_mm,
    height_mm = fig_dims$height_mm
  )
}

cat(
  "Exported B1 and C1 (PDF + PNG) at ",
  publication_figure_defaults()$dpi,
  " dpi\n",
  sep = ""
)
