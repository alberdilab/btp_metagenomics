#!/usr/bin/env Rscript
# Composite: B1 alpha diversity + C1 beta NMDS with shared legends on the right.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(purrr)
})

source("R/plot_helpers.R")
load("data/publication_base.Rdata")

env_settings <- environment_plot_settings()

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

fig_AB_bundle <- compose_alpha_beta_diversity_composite(
  alpha_panels = fig_B1_panels,
  beta_panels = fig_C1_panels,
  env_settings = env_settings
)

for (ext in c("pdf", "png")) {
  save_publication_figure(
    plot = fig_AB_bundle$plot,
    filename = paste0("fig_AB_alpha_beta_composite.", ext),
    width_mm = fig_AB_bundle$width_mm,
    height_mm = fig_AB_bundle$height_mm
  )
}

cat(
  "Exported figures/fig_AB_alpha_beta_composite.{pdf,png} (",
  fig_AB_bundle$width_mm, " x ", fig_AB_bundle$height_mm, " mm)\n",
  sep = ""
)
