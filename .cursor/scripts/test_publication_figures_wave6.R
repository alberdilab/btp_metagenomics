#!/usr/bin/env Rscript
# Verify wave-6 helpers: A1–A2 maps + F7 three-way congruence logic.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(sf)
  library(rnaturalearth)
  library(patchwork)
})

source("R/plot_helpers.R")
load("data/data.Rdata")

env_settings <- environment_plot_settings()
filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(broad_environment = factor(broad_environment, levels = env_settings$limits))

sample_points_map <- read_csv("sample_points.csv", show_col_types = FALSE) %>%
  rename(sample = id) %>%
  filter(sample != "EHI01340")

# --- A1 / A2 maps ---
tasmania_pts <- prepare_tasmania_map_points(sample_metadata_fig, sample_points_map)
stopifnot(nrow(tasmania_pts) > 0)
stopifnot(all(!is.na(tasmania_pts$longitude)), all(!is.na(tasmania_pts$latitude)))
stopifnot(!"EHI01340" %in% tasmania_pts$sample)

australia_map <- load_australia_map_sf()
fig_A1 <- create_tasmania_environment_map(
  tasmania_pts, env_settings, australia_map, theme_fn = theme_publication
)
stopifnot(inherits(fig_A1, "ggplot"))

env_r200 <- read_csv("data/environment_var_r200.csv", show_col_types = FALSE)
tasmania_devil <- prepare_tasmania_map_points(
  sample_metadata_fig,
  sample_points_map,
  env_variables = env_r200 %>% select(id, devil)
)
stopifnot("devil" %in% names(tasmania_devil))
stopifnot(sum(is.na(tasmania_devil$devil)) == 0)

fig_A1b <- create_tasmania_environment_map(
  tasmania_devil,
  env_settings,
  australia_map,
  devil_var = "devil",
  theme_fn = theme_publication
)
stopifnot(inherits(fig_A1b, "ggplot"))
stopifnot("devil_density" %in% names(aggregate_tasmania_map_sites(tasmania_devil, "devil")))

fig_A2 <- create_tasmania_devil_density_map(
  tasmania_devil, map_sf = australia_map, theme_fn = theme_publication
)
stopifnot(inherits(fig_A2, "ggplot"))

# --- F7 three-way congruence (synthetic post_table) ---
mock_post <- data.frame(
  devil = rep(c("Positive", "Negative", "Neutral"), length.out = 12),
  temperature = rep(c("Positive", "Negative", "Neutral"), each = 4),
  `devil:temperature` = rep(c("Positive", "Negative", "Neutral", "Positive"), 3),
  check.names = FALSE,
  row.names = paste0("g", seq_len(12))
)

mock_meta <- data.frame(
  genome = rownames(mock_post),
  phylum = rep(c("Bacteroidota", "Firmicutes"), length.out = 12),
  stringsAsFactors = FALSE
)

threeway_df <- prepare_threeway_congruence_genomes(mock_post, mock_meta)
stopifnot("pattern" %in% names(threeway_df))
stopifnot("triple_sig" %in% names(threeway_df))
stopifnot(sum(threeway_df$triple_sig) >= 1)

summary_df <- summarise_threeway_congruence(threeway_df)
fig_F7_a <- create_threeway_congruence_summary_plot(summary_df, theme_fn = theme_publication)
stopifnot(inherits(fig_F7_a, "ggplot"))

fig_F7_b <- create_threeway_interaction_tile_plot(threeway_df, theme_fn = theme_publication)
stopifnot(inherits(fig_F7_b, "ggplot"))

fig_F7_c <- create_threeway_phylum_congruence_plot(threeway_df, theme_fn = theme_publication)
stopifnot(inherits(fig_F7_c, "ggplot"))

cat("PASS: wave-6 publication figure helpers (A1–A2 maps + F7 three-way)\n")
