#!/usr/bin/env Rscript
# Export HMSC functional volcano plots (one PDF + PNG per predictor).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(ggplot2)
  library(patchwork)
})

source("R/plot_helpers.R")
load("data/publication_hmsc.Rdata")

gift_colors <- read_tsv("data/gift_colors.tsv") %>%
  mutate(legend = str_c(Code_function, " - ", Function))

if (!exists("functional_diff_diversity_fig")) {
  functional_diff_diversity_fig <- calculate_functional_differences(
    elements_response,
    "diversity"
  )
}

defaults <- publication_figure_defaults()

volcano_panels <- list(
  list(
    data = functional_diff_devil_fig,
    label = "Devil density",
    slug = "devil",
    fc = 0.2,
    x_lab = "Mean difference (Positive \u2212 Negative)",
    volcano_metric = "abundance_diff"
  ),
  list(
    data = functional_diff_temp_fig,
    label = "Temperature",
    slug = "temperature",
    fc = 0.2,
    x_lab = "Mean difference (Positive \u2212 Negative)",
    volcano_metric = "abundance_diff"
  ),
  list(
    data = functional_diff_diversity_fig,
    label = "Landscape diversity",
    slug = "diversity",
    fc = 0.2,
    x_lab = "Mean difference (Positive \u2212 Negative)",
    volcano_metric = "abundance_diff"
  ),
  list(
    data = functional_diff_interaction_fig,
    label = "Devil \u00d7 temperature",
    slug = "interaction",
    fc = 0.05,
    x_lab = "Mean interaction \u03b2",
    volcano_metric = "interaction_beta"
  )
)

panel_figs <- vector("list", length(volcano_panels))

for (i in seq_along(volcano_panels)) {
  panel <- volcano_panels[[i]]
  fig <- create_volcano_plot(
    panel$data,
    variable_label = panel$label,
    gift_colors = gift_colors,
    fc_threshold = panel$fc,
    fdr_threshold = 0.05,
    x_lab = panel$x_lab,
    volcano_metric = panel$volcano_metric,
    highlight_thresholds = TRUE,
    show_legend = FALSE,
    theme_fn = theme_publication
  )
  panel_figs[[i]] <- fig

  base <- paste0("fig_hmsc_volcano_", panel$slug)
  save_publication_figure(
    fig,
    paste0(base, ".pdf"),
    width_mm = defaults$width_mm,
    height_mm = defaults$height_mm
  )
  save_publication_figure(
    fig,
    paste0(base, ".png"),
    width_mm = defaults$width_mm,
    height_mm = defaults$height_mm,
    dpi = defaults$dpi
  )
}

composite_dims <- hmsc_volcano_composite_dims_mm(
  width_mm = defaults$width_mm,
  height_mm = defaults$height_mm
)

fig_composite <- compose_hmsc_volcano_composite(
  panel_plots = panel_figs,
  gift_colors = gift_colors
)

save_publication_figure(
  fig_composite,
  "fig_hmsc_volcano_4panel.pdf",
  width_mm = composite_dims$width_mm,
  height_mm = composite_dims$height_mm
)
save_publication_figure(
  fig_composite,
  "fig_hmsc_volcano_4panel.png",
  width_mm = composite_dims$width_mm,
  height_mm = composite_dims$height_mm,
  dpi = defaults$dpi
)

cat(
  "Exported ", length(volcano_panels),
  " HMSC volcano panels + 4-panel composite (PDF + PNG at ", defaults$dpi, " dpi) to figures/\n",
  sep = ""
)
