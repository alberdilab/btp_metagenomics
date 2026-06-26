#!/usr/bin/env Rscript
# Export A1–A2 Tasmania map PDFs.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(sf)
  library(rnaturalearth)
})

source("R/plot_helpers.R")
load("data/data.Rdata")

landcover_wide <- read_csv("landcover_wide.csv", show_col_types = FALSE) %>%
  rename(sample = id)

sample_points_map <- read_csv("sample_points.csv", show_col_types = FALSE) %>%
  rename(sample = id) %>%
  filter(sample != "EHI01340")

env_settings <- environment_plot_settings()
filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(broad_environment = factor(broad_environment, levels = env_settings$limits))

australia_map_fig <- load_australia_map_sf()

tasmania_map_points_fig <- prepare_tasmania_map_points(
  sample_metadata_fig,
  sample_points_map
)

env_var_r200_fig <- read_csv("data/environment_var_r200.csv", show_col_types = FALSE)

tasmania_devil_map_fig <- prepare_tasmania_map_points(
  sample_metadata_fig,
  sample_points_map,
  env_variables = env_var_r200_fig %>% select(id, devil)
)

fig_A1 <- create_tasmania_environment_map(
  tasmania_map_points_fig,
  env_settings = env_settings,
  map_sf = australia_map_fig,
  theme_fn = theme_publication
)

fig_A1b <- create_tasmania_environment_map(
  tasmania_devil_map_fig,
  env_settings = env_settings,
  map_sf = australia_map_fig,
  title = NULL,
  devil_var = "devil",
  theme_fn = theme_publication
)

fig_A2 <- create_tasmania_devil_density_map(
  tasmania_devil_map_fig,
  map_sf = australia_map_fig,
  theme_fn = theme_publication
)

save_publication_figure(fig_A1, "fig_A1_tasmania_environment_map.pdf", width_mm = 200, height_mm = 120)
save_publication_figure(
  fig_A1b,
  "fig_A1b_tasmania_environment_map_devil_border.pdf",
  width_mm = 200,
  height_mm = 120
)
save_publication_figure(
  fig_A1b,
  "fig_A1b_tasmania_environment_map_devil_border.png",
  width_mm = 200,
  height_mm = 120
)
save_publication_figure(fig_A2, "fig_A2_tasmania_devil_density_map.pdf", width_mm = 200, height_mm = 120)

cat("Exported A1, A1b, A2 to figures/\n")
