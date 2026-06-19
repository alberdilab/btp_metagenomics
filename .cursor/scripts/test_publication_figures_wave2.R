#!/usr/bin/env Rscript
# Verify wave-2 HMSC spotlight helpers (F1–F5).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(patchwork)
  library(tibble)
  library(ape)
  library(Hmsc)
  library(distillR)
  library(purrr)
})

source("R/plot_helpers.R")

load("data/data.Rdata")
gift_colors <- readr::read_tsv("data/gift_colors.tsv") %>%
  dplyr::mutate(legend = stringr::str_c(Code_function, " - ", Function))
load(file = "hmsc/model_final")

nSamples <- 250
thin <- 1000
transient <- nSamples * thin
support_threshold <- 0.9

tmp <- tempfile(fileext = ".rds")
options(timeout = max(600, getOption("timeout")))
download.file(
  "https://sid.erda.dk/share_redirect/Gh0WbM42c4/Hmsc_model_final.rds",
  tmp,
  mode = "wb"
)
hpc_fit <- readRDS(tmp)
unlink(tmp)

importFromHPC <- hpc_fit$list
postList <- importFromHPC[1:4]
fit_model_fig <- importPosteriorFromHPC(m, postList, nSamples, thin, transient)

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

spotlight_cols <- spotlight_palettes()

varpart_fig <- computeVariancePartitioning(fit_model_fig)
stopifnot(!is.null(varpart_fig$vals))

association_counts_fig <- summarise_association_counts(post_table)
stopifnot(nrow(association_counts_fig) > 0)

congruence_summary_fig <- summarise_devil_temp_congruence(post_table)
congruence_taxa_fig <- prepare_devil_temp_congruence_taxa(post_table, genome_metadata)
congruence_func_fig <- prepare_devil_temp_congruence_functional(elements_response, GIFT_db)

devil_beta_fig <- prepare_beta_support_data(fit_model_fig, m, "devil", genome_metadata, support_threshold)
devil_ci_fig <- prepare_covariate_ci(fit_model_fig, m, "devil", genome_metadata)
devil_ci_top_fig <- select_top_genomes_ci(devil_ci_fig, n_top = 10)
functional_diff_devil_fig <- calculate_functional_differences(elements_response, "devil")

stopifnot(inherits(create_varpart_summary_plot(varpart_fig, spotlight_cols), "ggplot"))
stopifnot(inherits(create_association_count_plot(association_counts_fig, spotlight_cols), "ggplot"))
stopifnot(inherits(create_congruence_summary_plot(congruence_summary_fig, spotlight_cols), "ggplot"))
stopifnot(inherits(create_beta_support_scatter(devil_beta_fig, "Devil β", phylum_colors), "ggplot"))
stopifnot(inherits(
  create_functional_trait_forest_plot(functional_diff_devil_fig, gift_colors, "Devil"),
  "ggplot"
))
stopifnot(inherits(
  create_congruence_tile_plot(congruence_taxa_fig, facet_var = "phylum", congruence_colors = spotlight_cols),
  "ggplot"
))

dir.create("figures", showWarnings = FALSE)
save_publication_figure(
  create_varpart_summary_plot(varpart_fig, spotlight_cols),
  "test_fig_F1_panel.pdf",
  height_mm = 80
)
unlink("figures/test_fig_F1_panel.pdf")

cat("PASS: wave-2 HMSC spotlight helpers\n")
