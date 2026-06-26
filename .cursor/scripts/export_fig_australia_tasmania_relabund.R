#!/usr/bin/env Rscript
# Composite: Australia + Tasmania context maps (upper) + faceted phylum bars (lower).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(patchwork)
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

all_map_points <- prepare_study_map_points(
  sample_metadata = sample_metadata_fig,
  sample_points = sample_points_map,
  env_variables = env_var_r200_fig %>% dplyr::select(id, devil)
)

tasmania_map_points <- prepare_study_map_points(
  sample_metadata = sample_metadata_fig,
  sample_points = sample_points_map,
  env_variables = env_var_r200_fig %>% dplyr::select(id, devil),
  island = "Tasmania"
)

fig_maps <- create_australia_tasmania_context_map(
  map_points_all = all_map_points,
  map_points_tasmania = tasmania_map_points,
  env_settings = env_settings,
  map_sf = australia_map_fig,
  devil_var = "devil",
  theme_fn = theme_publication
)

phylum_stack_fig <- prepare_phylum_stacked_data(
  genome_counts_fig,
  genome_metadata,
  sample_metadata_fig,
  sample_order = sample_order_fig
)

fig_E1b_wide <- create_phylum_stacked_bar(
  phylum_stack_fig,
  phylum_colors = phylum_colors,
  facet_env = TRUE,
  style = "chapter",
  wide_layout = TRUE,
  show_env_legend = FALSE
)

fig_composite <- compose_australia_tasmania_relabund_figure(
  map_panel = fig_maps,
  relabund_panel = fig_E1b_wide
)

composite_dims <- australia_tasmania_relabund_figure_dims(width_mm = 280)
export_dpi <- 1200L

save_publication_figure(
  plot = fig_composite,
  filename = "fig_australia_tasmania_context_E1b.png",
  width_mm = composite_dims$width_mm,
  height_mm = composite_dims$height_mm,
  dpi = export_dpi,
  tight_layout = TRUE
)

cat(
  "Exported figures/fig_australia_tasmania_context_E1b.png (",
  composite_dims$width_mm, " x ", composite_dims$height_mm, " mm @ ", export_dpi, " dpi)\n",
  sep = ""
)
