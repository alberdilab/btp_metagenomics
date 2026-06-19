#!/usr/bin/env Rscript
# Export F1–F5 publication PDFs (requires ERDA HMSC posterior download).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(stringr)
  library(ggplot2)
  library(patchwork)
  library(ape)
  library(Hmsc)
  library(distillR)
  library(purrr)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
phylum_colors <- load_phylum_colors_fallback()
gift_colors <- read_tsv("data/gift_colors.tsv") %>%
  mutate(legend = str_c(Code_function, " - ", Function))
load(file = "hmsc/model_final")

nSamples <- 250
thin <- 1000
transient <- nSamples * thin
support_threshold <- 0.9
spotlight_cols <- spotlight_palettes()
env_settings <- environment_plot_settings()

tmp <- tempfile(fileext = ".rds")
options(timeout = max(600, getOption("timeout")))
download.file(
  "https://sid.erda.dk/share_redirect/Gh0WbM42c4/Hmsc_model_final.rds",
  tmp,
  mode = "wb"
)
hpc_fit <- readRDS(tmp)
n_sp_fit <- ncol(hpc_fit$list[[1]][[1]]$Beta)
if (length(m$spNames) != n_sp_fit) {
  stop(
    "Unfitted model (", length(m$spNames), " genomes) does not match fitted posterior (",
    n_sp_fit, " genomes).", call. = FALSE
  )
}
fit_model_fig <- importPosteriorFromHPC(m, hpc_fit$list[1:4], nSamples, thin, transient)
unlink(tmp)

hmsc_tree <- genome_tree %>% keep.tip(tip = m$spNames)
post_estimates <- getPostEstimate(hM = fit_model_fig, parName = "Beta")$support %>%
  as.data.frame() %>%
  mutate(variable = m$covNames) %>%
  pivot_longer(!variable, names_to = "genome", values_to = "value") %>%
  mutate(value = case_when(
    value >= support_threshold ~ "Positive",
    value <= (1 - support_threshold) ~ "Negative",
    TRUE ~ "Neutral"
  ))

post_table <- post_estimates %>%
  mutate(genome = factor(genome, levels = rev(hmsc_tree$tip.label))) %>%
  mutate(value = factor(value, levels = c("Positive", "Neutral", "Negative"))) %>%
  pivot_wider(names_from = variable, values_from = value) %>%
  select(-`(Intercept)`) %>%
  column_to_rownames(var = "genome")

elements_response <- genome_gifts[rownames(post_table), colnames(genome_gifts) %in% GIFT_db$Code_bundle] %>%
  to.elements(., GIFT_db = GIFT_db) %>%
  as.data.frame() %>%
  rownames_to_column(var = "genome") %>%
  pivot_longer(!genome, names_to = "GIFT", values_to = "value") %>%
  left_join(post_table %>% rownames_to_column(var = "genome"), by = "genome")

varpart_fig <- computeVariancePartitioning(fit_model_fig)
association_counts_fig <- summarise_association_counts(post_table)
congruence_summary_fig <- summarise_devil_temp_congruence(post_table)
congruence_taxa_fig <- prepare_devil_temp_congruence_taxa(post_table, genome_metadata)
congruence_func_fig <- prepare_devil_temp_congruence_functional(elements_response, GIFT_db)

devil_beta_fig <- prepare_beta_support_data(fit_model_fig, m, "devil", genome_metadata, support_threshold)
temp_beta_fig <- prepare_beta_support_data(fit_model_fig, m, "temperature", genome_metadata, support_threshold)
devil_ci_fig <- prepare_covariate_ci(fit_model_fig, m, "devil", genome_metadata)
temp_ci_fig <- prepare_covariate_ci(fit_model_fig, m, "temperature", genome_metadata)
interaction_ci_fig <- prepare_covariate_ci(fit_model_fig, m, "devil:temperature", genome_metadata)
devil_ci_top_fig <- select_top_genomes_ci(devil_ci_fig, n_top = 20)
temp_ci_top_fig <- select_top_genomes_ci(temp_ci_fig, n_top = 20)
interaction_ci_top_fig <- select_top_genomes_ci(interaction_ci_fig, n_top = 20)
interaction_phylum_ci_fig <- aggregate_by_taxonomy(interaction_ci_fig, tax_level = "phylum")
functional_diff_devil_fig <- calculate_functional_differences(elements_response, "devil")
functional_diff_temp_fig <- calculate_functional_differences(elements_response, "temperature")
functional_diff_interaction_fig <- calculate_functional_beta_by_gift(
  interaction_ci_fig,
  elements_response,
  min_genomes = 10
)

devil_beta_fig <- enrich_beta_support_data(devil_beta_fig, support_threshold)
temp_beta_fig <- enrich_beta_support_data(temp_beta_fig, support_threshold)
interaction_beta_fig <- prepare_beta_support_from_post_table(
  post_table, interaction_ci_fig, "devil:temperature", support_threshold
)

threshold_panel <- function(beta_data, x_lab, func_data, func_label) {
  create_spotlight_threshold_figure(
    beta_support_data = beta_data,
    functional_differences = func_data,
    x_lab = x_lab,
    variable_label = func_label,
    phylum_colors = phylum_colors,
    gift_colors = gift_colors,
    support_threshold = support_threshold,
    spotlight_cols = spotlight_cols,
    theme_fn = theme_publication
  )
}

fig_F1 <- (
  create_varpart_summary_plot(
    varpart_fig, spotlight_cols = spotlight_cols, theme_fn = theme_publication
  ) |
    create_association_count_plot(
      association_counts_fig, spotlight_cols = spotlight_cols, theme_fn = theme_publication
    )
) / (
  create_congruence_summary_plot(
    congruence_summary_fig, congruence_colors = spotlight_cols, theme_fn = theme_publication
  ) |
    devil_ci_top_fig %>% create_forest_plot(
      color_var = "phylum", color_values = phylum_colors,
      x_lab = "Devil β coefficient", y_lab = NULL, base_size = 8,
      errorbar_width = 0, show_legend = FALSE, theme_fn = theme_publication
    ) + labs(title = "Top devil-associated genomes")
) + plot_annotation(tag_levels = "A")

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

phyla_top <- congruence_taxa_fig %>%
  group_by(phylum) %>% summarise(total = sum(n), .groups = "drop") %>%
  slice_max(total, n = 8) %>% pull(phylum)

fig_F5 <- (
  congruence_taxa_fig %>% filter(phylum %in% phyla_top) %>%
    create_congruence_tile_plot(
      facet_var = "phylum", value_var = "prop",
      congruence_colors = spotlight_cols, theme_fn = theme_publication
    ) +
    labs(title = "Taxonomic congruence")
) / (
  congruence_func_fig %>%
    create_congruence_tile_plot(
      facet_var = "Code_function", value_var = "mean_val",
      congruence_colors = spotlight_cols, theme_fn = theme_publication
    ) +
    labs(title = "Functional congruence")
) +
  plot_layout(heights = c(1, 1.2)) +
  plot_annotation(tag_levels = "A")

spotlight_fig_dims <- spotlight_panel_set_dims_mm(list(
  devil = functional_diff_devil_fig,
  temperature = functional_diff_temp_fig,
  interaction = functional_diff_interaction_fig
), fc_threshold = c(0.2, 0.2, 0.05))

save_publication_figure(fig_F1, "fig_F1_hmsc_hero.pdf", height_mm = 160)
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
save_publication_figure(fig_F5, "fig_F5_devil_temp_congruence.pdf", height_mm = 150)

threeway_genomes_fig <- prepare_threeway_congruence_genomes(post_table, genome_metadata)
threeway_summary_fig <- summarise_threeway_congruence(threeway_genomes_fig)

fig_F7_a <- create_threeway_congruence_summary_plot(
  threeway_summary_fig,
  spotlight_cols = spotlight_cols,
  theme_fn = theme_publication
)
fig_F7_b <- create_threeway_interaction_tile_plot(
  threeway_genomes_fig,
  congruence_colors = spotlight_cols,
  theme_fn = theme_publication
)
fig_F7_c <- create_threeway_phylum_congruence_plot(
  threeway_genomes_fig,
  phylum_colors = phylum_colors,
  n_top = 8,
  theme_fn = theme_publication
)

if (is.null(fig_F7_b)) {
  fig_F7 <- fig_F7_a / fig_F7_c +
    plot_layout(heights = c(1, 1.2)) +
    plot_annotation(tag_levels = "A")
} else {
  fig_F7 <- (fig_F7_a | fig_F7_b) / fig_F7_c +
    plot_layout(heights = c(1, 1.1)) +
    plot_annotation(tag_levels = "A")
}

save_publication_figure(fig_F7, "fig_F7_threeway_congruence.pdf", height_mm = 150)

cat("Exported F1–F5 and F7 to figures/\n")
