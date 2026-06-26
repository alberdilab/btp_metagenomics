#!/usr/bin/env Rscript
# Composite overview: A1b + E1b (left) + E2b Sankey (right, shared phylum legend).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(patchwork)
  library(ggalluvial)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/publication_base.Rdata")

phylum_colors <- load_phylum_colors_fallback()
env_settings <- environment_plot_settings()

sample_points_map <- read_csv("sample_points.csv", show_col_types = FALSE) %>%
  dplyr::rename(sample = id) %>%
  dplyr::filter(sample != "EHI01340")

env_var_r200_fig <- read_csv("data/environment_var_r200.csv", show_col_types = FALSE)

australia_map_fig <- load_australia_map_sf()
tasmania_devil_map_fig <- prepare_tasmania_map_points(
  sample_metadata = sample_metadata_fig,
  sample_points = sample_points_map,
  env_variables = env_var_r200_fig %>% dplyr::select(id, devil)
)

fig_A1b <- create_tasmania_environment_map(
  tasmania_devil_map_fig,
  env_settings = env_settings,
  map_sf = australia_map_fig,
  title = NULL,
  devil_var = "devil",
  theme_fn = theme_publication
)

phylum_stack_fig <- prepare_phylum_stacked_data(
  genome_counts_fig,
  genome_metadata,
  sample_metadata_fig,
  sample_order = sample_order_fig
)

fig_E1b <- create_phylum_stacked_bar(
  phylum_stack_fig,
  phylum_colors = phylum_colors,
  facet_env = TRUE,
  style = "chapter"
)

fig_overview <- compose_study_context_overview_figure(
  panel_a = fig_A1b,
  panel_b = fig_E1b
)

overview_dims <- study_context_overview_figure_dims(width_mm = 200)
export_dpi <- 1200L

save_publication_figure(
  plot = fig_overview,
  filename = "fig_study_context_overview_A1b_E1b.png",
  width_mm = overview_dims$width_mm,
  height_mm = overview_dims$height_mm,
  dpi = export_dpi,
  tight_layout = TRUE
)

cat(
  "Exported figures/fig_study_context_overview_A1b_E1b.png (",
  overview_dims$width_mm, " x ", overview_dims$height_mm, " mm)\n",
  sep = ""
)

family_sankey_fig <- prepare_family_sankey_data(
  genome_counts_fig,
  genome_metadata,
  n_top = 18
)

fig_E1b_env_only <- create_phylum_stacked_bar(
  phylum_stack_fig,
  phylum_colors = phylum_colors,
  facet_env = TRUE,
  style = "chapter",
  show_phylum_legend = FALSE
)

fig_E2b_right <- create_family_sankey_plot(
  family_sankey_fig,
  phylum_colors = phylum_colors,
  legend_position = "right",
  theme_fn = theme_publication
)

fig_overview_sankey <- compose_study_context_sankey_figure(
  panel_a = fig_A1b,
  panel_b = fig_E1b_env_only,
  sankey_plot = fig_E2b_right
)

sankey_dims <- study_context_sankey_figure_dims(width_mm = 360)

save_publication_figure(
  plot = fig_overview_sankey,
  filename = "fig_study_context_overview_A1b_E1b_E2b.png",
  width_mm = sankey_dims$width_mm,
  height_mm = sankey_dims$height_mm,
  dpi = export_dpi,
  tight_layout = TRUE
)

cat(
  "Exported figures/fig_study_context_overview_A1b_E1b_E2b.png (",
  sankey_dims$width_mm, " x ", sankey_dims$height_mm, " mm @ ", export_dpi, " dpi)\n",
  sep = ""
)
