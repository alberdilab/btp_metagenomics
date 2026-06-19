#!/usr/bin/env Rscript
# Verify F6 phylo + GIFT heatmap helpers.

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

fit_model_fig <- importPosteriorFromHPC(m, hpc_fit$list[1:4], nSamples, thin, transient)

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

sig_genomes <- select_spotlight_significant_genomes(post_table, method = "stratified")
stopifnot(length(sig_genomes) > 0, length(sig_genomes) <= 120)

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
stopifnot(!is.null(phylo_gift_fig_data))
stopifnot(
  nrow(phylo_gift_fig_data$phylum) == phylo_gift_fig_data$n_genomes,
  nrow(phylo_gift_fig_data$beta) == phylo_gift_fig_data$n_genomes,
  ncol(phylo_gift_fig_data$beta) == 3,
  nrow(phylo_gift_fig_data$gift) == phylo_gift_fig_data$n_genomes,
  ncol(phylo_gift_fig_data$gift) >= 15,
  ncol(phylo_gift_fig_data$gift) <= 25,
  identical(phylo_gift_fig_data$gift_level, "function")
)

fig_F6 <- create_phylo_gift_heatmap_plot(
  phylo_tree = phylo_gift_fig_data$tree,
  phylum_matrix = phylo_gift_fig_data$phylum,
  gift_matrix = phylo_gift_fig_data$gift,
  beta_matrix = phylo_gift_fig_data$beta,
  phylum_colors = phylum_colors
)
stopifnot(inherits(fig_F6, c("ggtree", "gg")))

dims <- phylo_gift_figure_dims(
  phylo_gift_fig_data$n_genomes,
  ncol(phylo_gift_fig_data$gift)
)
stopifnot(dims$height_mm >= 200, dims$width_mm >= 180)

dir.create("figures", showWarnings = FALSE)
save_publication_figure(
  fig_F6,
  "test_fig_F6.pdf",
  width_mm = dims$width_mm,
  height_mm = dims$height_mm
)
stopifnot(file.exists("figures/test_fig_F6.pdf"), file.info("figures/test_fig_F6.pdf")$size > 5000)
unlink("figures/test_fig_F6.pdf")

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
stopifnot(!is.null(phylo_gift_fig_data_stacked))
stopifnot(
  nrow(phylo_gift_fig_data_stacked$gift) == phylo_gift_fig_data_stacked$n_genomes,
  ncol(phylo_gift_fig_data_stacked$gift) >= 30,
  identical(phylo_gift_fig_data_stacked$gift_level, "element")
)

fig_F6b <- create_phylo_gift_heatmap_plot_stacked(
  phylo_tree = phylo_gift_fig_data_stacked$tree,
  phylum_matrix = phylo_gift_fig_data_stacked$phylum,
  gift_matrix = phylo_gift_fig_data_stacked$gift,
  GIFT_db = GIFT_db,
  beta_matrix = phylo_gift_fig_data_stacked$beta,
  phylum_colors = phylum_colors
)
stopifnot(inherits(fig_F6b, c("ggtree", "gg", "patchwork", "aplot")))

dims_stacked <- phylo_gift_stacked_figure_dims(
  phylo_gift_fig_data_stacked$n_genomes,
  ncol(phylo_gift_fig_data_stacked$gift)
)
stopifnot(dims_stacked$height_mm >= 220, dims_stacked$width_mm >= 180)

save_publication_figure(
  fig_F6b,
  "test_fig_F6b.pdf",
  width_mm = dims_stacked$width_mm,
  height_mm = dims_stacked$height_mm
)
stopifnot(file.exists("figures/test_fig_F6b.pdf"), file.info("figures/test_fig_F6b.pdf")$size > 5000)
unlink("figures/test_fig_F6b.pdf")

cat(
  "PASS: F6 phylo+GIFT helpers (",
  phylo_gift_fig_data$n_genomes, " genomes, ",
  ncol(phylo_gift_fig_data$gift), " GIFT functions); F6b stacked (",
  ncol(phylo_gift_fig_data_stacked$gift), " GIFT elements)\n",
  sep = ""
)
