#!/usr/bin/env Rscript
# Build publication figure caches without knitting the full webbook.
# Requires: data/data.Rdata, data/beta.Rdata, hmsc/model_final, ERDA posterior for HMSC.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(Hmsc)
  library(ape)
  library(hilldiv2)
  library(distillR)
})

source("R/plot_helpers.R")
paths <- publication_cache_paths()

if (!save_publication_base_cache_from_disk(skip_if_no_landcover = FALSE)) {
  stop("Failed to build publication base cache.", call. = FALSE)
}
cat("Saved", paths$base, "\n")

nSamples <- 250
thin <- 1000
transient <- nSamples * thin
support_threshold <- 0.9

load(file = "hmsc/model_final")

tmp <- tempfile(fileext = ".rds")
options(timeout = max(600, getOption("timeout")))
download.file(
  "https://sid.erda.dk/share_redirect/Gh0WbM42c4/Hmsc_model_final.rds",
  tmp,
  mode = "wb",
  quiet = TRUE
)
hpc_fit <- readRDS(tmp)
unlink(tmp)

importFromHPC <- hpc_fit$list
n_sp_fit <- ncol(importFromHPC[[1]][[1]]$Beta)
if (length(m$spNames) != n_sp_fit) {
  stop(
    "Unfitted model (", length(m$spNames), " genomes) does not match fitted posterior (",
    n_sp_fit, " genomes). Use the canonical hmsc/model_final built from data/model_final_genomes.tsv.",
    call. = FALSE
  )
}

postList <- importFromHPC[1:4]
fit_model <- importPosteriorFromHPC(m, postList, nSamples, thin, transient)

hmsc_tree <- genome_tree %>% keep.tip(tip = m$spNames)

post_estimates <- getPostEstimate(hM = fit_model, parName = "Beta")$support %>%
  as.data.frame() %>%
  mutate(variable = m$covNames) %>%
  pivot_longer(!variable, names_to = "genome", values_to = "value")

post_table <- post_estimates %>%
  mutate(genome = factor(genome, levels = rev(hmsc_tree$tip.label))) %>%
  mutate(value = case_when(
    value >= support_threshold ~ "Positive",
    value <= (1 - support_threshold) ~ "Negative",
    TRUE ~ "Neutral"
  )) %>%
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

hmsc_cache <- build_publication_hmsc_cache(
  fit_model = fit_model,
  model_obj = m,
  post_table = post_table,
  elements_response = elements_response,
  genome_metadata = genome_metadata,
  genome_tree = genome_tree,
  GIFT_db = GIFT_db,
  support_threshold = support_threshold
)
save_publication_cache(hmsc_cache, paths$hmsc)
cat("Saved", paths$hmsc, "\n")
