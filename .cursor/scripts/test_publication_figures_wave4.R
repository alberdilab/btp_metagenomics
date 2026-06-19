#!/usr/bin/env Rscript
# Verify wave-4 community composition helpers (E1–E3).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(patchwork)
  library(purrr)
  library(stringr)
  library(ggalluvial)
})

source("R/plot_helpers.R")

load("data/data.Rdata")

filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(
    broad_environment = factor(
      broad_environment,
      levels = environment_plot_settings()$limits
    )
  )
genome_counts_fig <- filtered$genome_counts

stopifnot(!"EHI01340" %in% sample_metadata_fig$sample)

sample_order_fig <- sample_metadata_fig %>%
  arrange(broad_environment, sample) %>%
  pull(sample) %>%
  unique()

# --- E1 phylum stacked ---
phylum_stack_fig <- prepare_phylum_stacked_data(
  genome_counts_fig,
  genome_metadata,
  sample_metadata_fig,
  sample_order = sample_order_fig,
  n_top = 12
)
stopifnot(nrow(phylum_stack_fig) > 0)
stopifnot(all(abs(phylum_stack_fig %>% group_by(sample) %>% summarise(s = sum(relabun)) %>% pull(s) - 1) < 0.01))

fig_E1 <- create_phylum_stacked_bar(
  phylum_stack_fig,
  phylum_colors = phylum_colors,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_E1, "ggplot"))

# --- E2 family Sankey ---
family_sankey_fig <- prepare_family_sankey_data(
  genome_counts_fig,
  genome_metadata,
  n_top = 18
)
stopifnot(nrow(family_sankey_fig) > 0)
stopifnot(abs(sum(family_sankey_fig$relabun) - 1) < 0.01)

fig_E2 <- create_family_sankey_plot(
  family_sankey_fig,
  phylum_colors = phylum_colors,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_E2, "ggplot"))

# --- jitter helpers (source chapter only) ---
phylum_summary_fig <- prepare_taxonomy_relabun(
  genome_counts_fig,
  genome_metadata,
  sample_metadata_fig,
  tax_level = "phylum",
  group_vars = "broad_environment"
)
fig_E2_jitter <- create_taxonomy_jitter_plot(
  phylum_summary_fig,
  tax_col = "phylum",
  n_top = 15,
  phylum_colors = phylum_colors,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_E2_jitter, "ggplot"))

# --- E3 dominant MAG tile ---
dominant_mag_fig <- prepare_dominant_mag_tile_data(
  genome_counts_fig,
  genome_metadata,
  sample_metadata_fig,
  n_mags = 35,
  sample_order = sample_order_fig
)
stopifnot(nrow(dominant_mag_fig) > 0)
stopifnot(length(unique(dominant_mag_fig$genome)) == 35)

fig_E3 <- create_dominant_mag_tile_plot(
  dominant_mag_fig,
  phylum_colors = phylum_colors,
  theme_fn = theme_publication
)
stopifnot(inherits(fig_E3, "ggplot"))

# --- D4 extraction smoke (structure only, no full ANCOM run) ---
fake_res <- list(
  res = tibble::tibble(
    taxon = c("g1", "g2"),
    lfc_env_div_group0High = c(0.5, -0.3),
    p_env_div_group0High = c(0.01, 0.2)
  )
)
dt <- extract_ancombc_diff_table(fake_res)
stopifnot(!is.null(dt), nrow(dt) == 2, sum(dt$sig) == 1)

dir.create("figures", showWarnings = FALSE)
save_publication_figure(fig_E1, "test_fig_E1.pdf", height_mm = 80)
save_publication_figure(fig_E2, "test_fig_E2.pdf", height_mm = 80)
save_publication_figure(fig_E3, "test_fig_E3.pdf", height_mm = 80)
stopifnot(file.exists("figures/test_fig_E1.pdf"), file.exists("figures/test_fig_E2.pdf"))

unlink(c("figures/test_fig_E1.pdf", "figures/test_fig_E2.pdf", "figures/test_fig_E3.pdf"))

cat("PASS: wave-4 publication figure helpers (E1–E3 + D4 extract)\n")
