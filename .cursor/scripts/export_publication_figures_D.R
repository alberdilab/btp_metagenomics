#!/usr/bin/env Rscript
# Export D1–D4 publication PDFs.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(ggplot2)
  library(patchwork)
  library(purrr)
  library(phyloseq)
  library(ANCOMBC)
  library(microbiome)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/hill.Rdata")

if (!exists("phylum_colors")) {
  phylum_colors <- read_tsv(
    "https://raw.githubusercontent.com/earthhologenome/EHI_taxonomy_colour/main/ehi_phylum_colors.tsv"
  ) %>% deframe()
}

landcover_wide <- read_csv("landcover_wide.csv", show_col_types = FALSE) %>% rename(sample = id)
env_settings <- environment_plot_settings()
filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(broad_environment = factor(broad_environment, levels = env_settings$limits))
genome_counts_fig <- filtered$genome_counts

hill_long_fig <- hill_long %>% rename(sample = id) %>% filter(sample != "EHI01340")
hill_wide_fig <- hill_long_fig %>%
  pivot_wider(id_cols = sample, names_from = q, values_from = value, names_glue = "env_hill_{q}")

sample_metadata_fig <- sample_metadata_fig %>%
  left_join(landcover_wide, by = "sample")

hill_landcover_fig <- hill_long_fig %>%
  left_join(
    sample_metadata_fig %>% select(sample, any_of(names(landcover_summary_vars()))),
    by = "sample"
  )
fine_broad_hill_fig <- prepare_fine_broad_hill_compare(
  hill_long_fig, landcover_wide, sample_metadata_fig$sample
)

# D1
save_publication_figure(
  create_env_hill_distribution_plot(hill_long_fig, theme_fn = theme_publication),
  "fig_D1_env_hill_distributions.pdf",
  height_mm = 90
)

# D2
landcover_hill_vars <- c("Cultivated_Total", "Native_Terrestrial_Total")
fig_D2_panels <- tidyr::expand_grid(
  q = names(env_hill_metric_labels),
  lc_var = landcover_hill_vars
) %>%
  purrr::pmap(function(q_level, lc_var) {
    plot_df <- hill_landcover_fig %>% dplyr::filter(.data$q == q_level)
    create_landcover_hill_scatter(
      plot_df, lc_var, landcover_summary_vars()[[lc_var]],
      y_lab = env_hill_metric_labels[[q_level]],
      theme_fn = theme_publication
    ) + labs(title = env_hill_metric_labels[[q_level]])
  })
save_publication_figure(wrap_plots(fig_D2_panels, ncol = 2, nrow = 3), "fig_D2_landcover_env_hill.pdf", height_mm = 150)

# D3
fig_D3_panels <- imap(env_hill_metric_labels, ~ create_fine_broad_hill_scatter(
  fine_broad_hill_fig, .y, theme_publication
) + labs(title = .x))
save_publication_figure(fig_D3_panels[[1]] | fig_D3_panels[[2]] | fig_D3_panels[[3]], "fig_D3_fine_broad_hill.pdf", height_mm = 90)

# D4
inputs <- prepare_env_ancom_inputs(sample_metadata_fig, genome_counts_fig, hill_wide_fig)
ancom_results <- run_env_ancombc(build_env_ancom_phyloseq(inputs, genome_metadata), inputs)
tables <- imap(ancom_results, ~ extract_ancombc_diff_table(.x, genome_metadata))
volcanos <- compact(imap(tables, ~ create_ancombc_volcano_plot(.x, paste("ANCOM-BC2 — env Hill", .y), theme_publication)))
if (length(volcanos) > 0) {
  save_publication_figure(wrap_plots(volcanos, ncol = 3), "fig_D4_ancombc_volcano.pdf", height_mm = 90)
  bars <- compact(imap(tables, ~ create_ancombc_barplot(.x, 10, paste("Top DA — env Hill", .y), phylum_colors, theme_publication)))
  if (length(bars) > 0) {
    save_publication_figure(wrap_plots(bars, ncol = 1), "fig_D4_ancombc_barplots.pdf", height_mm = max(120, 40 * length(bars)))
  }
} else {
  cat("D4 skipped: ANCOMBC2 returned no results\n")
}

cat("Exported D1–D4 to figures/\n")
