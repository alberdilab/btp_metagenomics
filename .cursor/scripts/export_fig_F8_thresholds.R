#!/usr/bin/env Rscript
# Export F2–F4 and F8 threshold-focused HMSC PDFs from publication cache.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(stringr)
  library(ggplot2)
  library(patchwork)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/publication_hmsc.Rdata")

gift_colors <- read_tsv("data/gift_colors.tsv") %>%
  mutate(legend = str_c(Code_function, " - ", Function))

if (!exists("phylum_colors")) {
  phylum_colors <- read_tsv(
    "https://raw.githubusercontent.com/earthhologenome/EHI_taxonomy_colour/main/ehi_phylum_colors.tsv"
  ) %>%
    deframe()
}

spotlight_cols <- spotlight_palettes()

devil_beta_fig <- enrich_beta_support_data(devil_beta_fig, support_threshold = support_threshold)
temp_beta_fig <- enrich_beta_support_data(temp_beta_fig, support_threshold = support_threshold)

if (!exists("interaction_beta_fig")) {
  interaction_beta_fig <- prepare_beta_support_from_post_table(
    post_table,
    interaction_ci_fig,
    "devil:temperature",
    support_threshold = support_threshold
  )
} else {
  interaction_beta_fig <- enrich_beta_support_data(
    interaction_beta_fig,
    support_threshold = support_threshold
  )
}

spotlight_fig_dims <- spotlight_panel_set_dims_mm(list(
  devil = functional_diff_devil_fig,
  temperature = functional_diff_temp_fig,
  interaction = functional_diff_interaction_fig
), fc_threshold = c(0.2, 0.2, 0.05))

fig_F2 <- create_functional_trait_forest_plot(
  functional_diff_devil_fig,
  gift_colors = gift_colors,
  variable_label = "Devil density",
  spotlight_cols = spotlight_cols,
  theme_fn = theme_publication
)

fig_F3 <- create_functional_trait_forest_plot(
  functional_diff_temp_fig,
  gift_colors = gift_colors,
  variable_label = "Temperature",
  spotlight_cols = spotlight_cols,
  theme_fn = theme_publication
)

fig_F4 <- create_functional_trait_forest_plot(
  functional_diff_interaction_fig,
  gift_colors = gift_colors,
  variable_label = "Devil x temperature",
  fc_threshold = 0.05,
  fdr_threshold = 0.05,
  negative_label = "Negative interaction",
  positive_label = "Positive interaction",
  x_lab = "Mean interaction beta (95% CI)",
  spotlight_cols = spotlight_cols,
  theme_fn = theme_publication
)

fig_F8 <- create_functional_climate_comparison_plot(
  functional_diff_list = list(
    devil = functional_diff_devil_fig,
    temperature = functional_diff_temp_fig,
    interaction = functional_diff_interaction_fig
  ),
  predictor_labels = c("Devil density", "Temperature", "Devil x temperature"),
  gift_colors = gift_colors,
  fc_threshold = c(0.2, 0.2, 0.05),
  fdr_threshold = 0.05,
  shared_limits = FALSE,
  theme_fn = theme_publication
) +
  plot_annotation(
    tag_levels = "A",
    title = "Functional trait associations across HMSC predictors",
    subtitle = "Devil/temp: abundance contrast; interaction: mean beta per GIFT (|effect| >= threshold, FDR < 0.05)"
  )

save_publication_figure(
  fig_F2, "fig_F2_devil_spotlight.pdf",
  width_mm = spotlight_fig_dims$width_mm,
  height_mm = spotlight_fig_dims$height_mm
)
save_publication_figure(
  fig_F3, "fig_F3_temperature_spotlight.pdf",
  width_mm = spotlight_fig_dims$width_mm,
  height_mm = spotlight_fig_dims$height_mm
)
save_publication_figure(
  fig_F4, "fig_F4_interaction_spotlight.pdf",
  width_mm = spotlight_fig_dims$width_mm,
  height_mm = spotlight_fig_dims$height_mm
)
save_publication_figure(
  fig_F8,
  "fig_F8_hmsc_thresholds.pdf",
  width_mm = 200,
  height_mm = functional_comparison_height_mm(
    list(
      devil = functional_diff_devil_fig,
      temperature = functional_diff_temp_fig,
      interaction = functional_diff_interaction_fig
    ),
    fc_threshold = c(0.2, 0.2, 0.05)
  )
)

cat("Exported F2, F3, F4, F8 to figures/\n")
