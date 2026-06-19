#!/usr/bin/env Rscript
# Export F6 phylo + GIFT heatmap PDF (requires ERDA HMSC posterior download).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(ggplot2)
  library(ape)
  library(Hmsc)
  library(distillR)
  library(ggtree)
  library(ggtreeExtra)
  library(ggnewscale)
  library(phytools)
  library(aplot)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
phylum_colors <- load_phylum_colors_fallback()
load(file = "hmsc/model_final")

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
fit_model_fig <- importPosteriorFromHPC(
  m, hpc_fit$list[1:4], 250, 1000, 250 * 1000
)
unlink(tmp)

support_threshold <- 0.9
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

phylo_gift_fig_data <- build_phylo_gift_fig_data(
  genome_tree = hmsc_tree,
  genome_metadata = genome_metadata,
  genome_gifts = genome_gifts,
  GIFT_db = GIFT_db,
  post_table = post_table,
  max_genomes = 120,
  beta_ci_list = spotlight_beta_ci_list(
    prepare_covariate_ci(fit_model_fig, m, "devil", genome_metadata),
    prepare_covariate_ci(fit_model_fig, m, "temperature", genome_metadata),
    prepare_covariate_ci(fit_model_fig, m, "devil:temperature", genome_metadata)
  )
)

if (is.null(phylo_gift_fig_data)) {
  stop("No spotlight-significant genomes for F6 export", call. = FALSE)
}

fig_F6 <- create_phylo_gift_heatmap_plot(
  phylo_tree = phylo_gift_fig_data$tree,
  phylum_matrix = phylo_gift_fig_data$phylum,
  gift_matrix = phylo_gift_fig_data$gift,
  beta_matrix = phylo_gift_fig_data$beta,
  phylum_colors = phylum_colors,
  tree_size = 0.22
)

dims <- phylo_gift_figure_dims(
  phylo_gift_fig_data$n_genomes,
  ncol(phylo_gift_fig_data$gift)
)

save_publication_figure(
  fig_F6,
  "fig_F6_phylo_gift_heatmap.pdf",
  width_mm = dims$width_mm,
  height_mm = dims$height_mm
)

phylo_gift_fig_data_stacked <- build_phylo_gift_fig_data(
  genome_tree = hmsc_tree,
  genome_metadata = genome_metadata,
  genome_gifts = genome_gifts,
  GIFT_db = GIFT_db,
  post_table = post_table,
  max_genomes = 120,
  beta_ci_list = spotlight_beta_ci_list(
    prepare_covariate_ci(fit_model_fig, m, "devil", genome_metadata),
    prepare_covariate_ci(fit_model_fig, m, "temperature", genome_metadata),
    prepare_covariate_ci(fit_model_fig, m, "devil:temperature", genome_metadata)
  ),
  gift_level = "element"
)

fig_F6b <- create_phylo_gift_heatmap_plot_stacked(
  phylo_tree = phylo_gift_fig_data_stacked$tree,
  phylum_matrix = phylo_gift_fig_data_stacked$phylum,
  gift_matrix = phylo_gift_fig_data_stacked$gift,
  GIFT_db = GIFT_db,
  beta_matrix = phylo_gift_fig_data_stacked$beta,
  phylum_colors = phylum_colors,
  tree_size = 0.22
)

dims_stacked <- phylo_gift_stacked_figure_dims(
  phylo_gift_fig_data_stacked$n_genomes,
  ncol(phylo_gift_fig_data_stacked$gift)
)

save_publication_figure(
  fig_F6b,
  "fig_F6b_phylo_gift_heatmap_stacked.pdf",
  width_mm = dims_stacked$width_mm,
  height_mm = dims_stacked$height_mm
)

cat(
  "Exported F6 (", phylo_gift_fig_data$n_genomes, " genomes) to figures/\n",
  "Exported F6b (", phylo_gift_fig_data_stacked$n_genomes, " genomes, ",
  ncol(phylo_gift_fig_data_stacked$gift), " GIFT elements) to figures/\n",
  sep = ""
)
