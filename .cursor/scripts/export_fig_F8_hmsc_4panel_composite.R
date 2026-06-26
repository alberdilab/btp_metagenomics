#!/usr/bin/env Rscript
# Composite: four F8 HMSC climate-stripe panels (temperature, devil, interaction, diversity).

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/publication_hmsc.Rdata")

gift_colors <- readr::read_tsv("data/gift_colors.tsv") %>%
  dplyr::mutate(legend = stringr::str_c(Code_function, " - ", Function))

if (!exists("functional_diff_diversity_fig")) {
  functional_diff_diversity_fig <- calculate_functional_differences(
    elements_response,
    "diversity"
  )
}

f8_panels <- list(
  list(
    data = functional_diff_temp_fig,
    label = "Temperature",
    fc = 0.2,
    negative = "Negative association",
    positive = "Positive association"
  ),
  list(
    data = functional_diff_devil_fig,
    label = "Devil density",
    fc = 0.2,
    negative = "Negative association",
    positive = "Positive association"
  ),
  list(
    data = functional_diff_interaction_fig,
    label = "Devil x temperature",
    fc = 0.05,
    negative = "Negative interaction",
    positive = "Positive interaction"
  ),
  list(
    data = functional_diff_diversity_fig,
    label = "Diversity",
    fc = 0.2,
    negative = "Negative association",
    positive = "Positive association"
  )
)

panel_figs <- vector("list", length(f8_panels))
panel_dims <- vector("list", length(f8_panels))

for (i in seq_along(f8_panels)) {
  panel <- f8_panels[[i]]
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
  panel_dims[[i]] <- dims
  panel_figs[[i]] <- create_functional_climate_stripe_figure(
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
}

width_mm <- max(vapply(panel_dims, `[[`, numeric(1), "width_mm")) * 2
height_mm <- max(vapply(panel_dims, `[[`, numeric(1), "height_mm")) * 2

fig_4panel <- patchwork::wrap_elements(full = panel_figs[[1]]) +
  patchwork::wrap_elements(full = panel_figs[[2]]) +
  patchwork::wrap_elements(full = panel_figs[[3]]) +
  patchwork::wrap_elements(full = panel_figs[[4]]) +
  patchwork::plot_layout(ncol = 2, nrow = 2) +
  patchwork::plot_annotation(
    tag_levels = "A",
    theme = ggplot2::theme(
      plot.tag = ggplot2::element_text(face = "bold", size = 16),
      plot.tag.position = "topleft"
    )
  )

save_publication_figure(
  plot = fig_4panel,
  filename = "fig_F8_hmsc_4panel_temperature_devil_interaction_diversity.png",
  width_mm = width_mm,
  height_mm = height_mm
)

cat(
  "Exported figures/fig_F8_hmsc_4panel_temperature_devil_interaction_diversity.png (",
  width_mm, " x ", height_mm, " mm)\n",
  sep = ""
)
