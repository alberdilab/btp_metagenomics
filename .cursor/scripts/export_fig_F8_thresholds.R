#!/usr/bin/env Rscript
# Export F2–F4 spotlight forests and F8 climate-stripe panels (one file per predictor).

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

if (!exists("functional_diff_diversity_fig")) {
  functional_diff_diversity_fig <- calculate_functional_differences(
    elements_response,
    "diversity"
  )
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

f8_panels <- list(
  list(
    data = functional_diff_devil_fig,
    label = "Devil density",
    slug = "devil",
    fc = 0.2,
    negative = "Negative association",
    positive = "Positive association"
  ),
  list(
    data = functional_diff_temp_fig,
    label = "Temperature",
    slug = "temperature",
    fc = 0.2,
    negative = "Negative association",
    positive = "Positive association"
  ),
  list(
    data = functional_diff_interaction_fig,
    label = "Devil x temperature",
    slug = "interaction",
    fc = 0.05,
    negative = "Negative interaction",
    positive = "Positive interaction"
  ),
  list(
    data = functional_diff_diversity_fig,
    label = "Diversity",
    slug = "diversity",
    fc = 0.2,
    negative = "Negative association",
    positive = "Positive association"
  )
)

for (panel in f8_panels) {
  panel_list <- stats::setNames(list(panel$data), panel$label)
  panel_data <- prepare_functional_predictor_comparison(
    functional_diff_list = panel_list,
    predictor_labels = panel$label,
    gift_colors = gift_colors,
    fc_threshold = panel$fc,
    trait_set = "per_panel",
    truncate_func_label = NULL
  )
  trait_labels <- if (nrow(panel_data) > 0L) {
    levels(panel_data$trait_label)
  } else {
    character()
  }
  dims <- functional_climate_stripe_dims_mm(
    functional_differences = panel$data,
    fc_threshold = panel$fc,
    trait_labels = trait_labels
  )

  fig <- create_functional_climate_stripe_figure(
    predictor_label = panel$label,
    functional_diff_list = panel_list,
    gift_colors = gift_colors,
    fc_threshold = panel$fc,
    trait_set = "per_panel",
    truncate_func_label = NULL,
    group_by_function = TRUE,
    negative_label = panel$negative,
    positive_label = panel$positive,
    theme_fn = theme_publication
  )
  base <- paste0("fig_F8_", panel$slug, "_hmsc_thresholds")
  save_publication_figure(
    fig,
    paste0(base, ".pdf"),
    width_mm = dims$width_mm,
    height_mm = dims$height_mm
  )
  save_publication_figure(
    fig,
    paste0(base, ".png"),
    width_mm = dims$width_mm,
    height_mm = dims$height_mm
  )
}

cat("Exported F2, F3, F4 and F8 panels (PDF + PNG) to figures/\n")
