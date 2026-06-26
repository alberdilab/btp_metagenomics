#!/usr/bin/env Rscript
# Cross-check key manuscript numbers against current R caches and chapter logic.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(nlme)
  library(vegan)
  library(hilldiv2)
  library(distillR)
})

source("R/plot_helpers.R")

load("data/data.Rdata")
load("data/beta.Rdata")
load("data/publication_base.Rdata")
load("data/publication_hmsc.Rdata")

cat("=== SAMPLE / CATALOGUE ===\n")
cat("Samples (metadata):", nrow(sample_metadata), "\n")
cat("Tasmania:", sum(sample_metadata$island == "Tasmania"), "\n")
cat("Australia:", sum(sample_metadata$island == "Australia"), "\n")
cat("MAGs:", nrow(genome_metadata), "\n")
cat("Phyla:", n_distinct(genome_metadata$phylum), "\n")
cat("Bacterial phyla:", n_distinct(genome_metadata$phylum[genome_metadata$domain == "Bacteria"]), "\n")
cat("Archaeal phyla:", n_distinct(genome_metadata$phylum[genome_metadata$domain == "Archaea"]), "\n")

total_gb <- sum(sample_metadata$reads_post_fastp * 150 / 1e9)
per_gb <- sample_metadata$reads_post_fastp * 150 / 1e9
cat(sprintf("Total Gb: %.1f\n", total_gb))
cat(sprintf("Per sample Gb: %.2f ± %.2f\n", mean(per_gb), sd(per_gb)))

if ("completeness" %in% names(genome_metadata)) {
  cat(sprintf("CheckM completeness: %.1f ± %.1f\n", mean(genome_metadata$completeness), sd(genome_metadata$completeness)))
  cat(sprintf("CheckM contamination: %.2f ± %.2f\n", mean(genome_metadata$contamination), sd(genome_metadata$contamination)))
}

cat("\n=== ALPHA DIVERSITY (publication_base / ch06) ===\n")
ad <- alpha_div_fig %>%
  inner_join(sample_metadata %>% select(sample, broad_environment, region, island, sex), by = "sample")
for (met in c("richness", "neutral", "phylogenetic", "functional")) {
  cat(sprintf("%s overall: %.2f ± %.2f\n", met, mean(ad[[met]], na.rm = TRUE), sd(ad[[met]], na.rm = TRUE)))
}

# ch06-style functional from plot_helpers
ad_ch06 <- calculate_alpha_diversity(genome_counts_filt, genome_tree, genome_gifts, GIFT_db) %>%
  inner_join(sample_metadata %>% select(sample), by = "sample")
cat(sprintf("functional (recalc plot_helpers): %.2f ± %.2f\n",
            mean(ad_ch06$functional, na.rm = TRUE), sd(ad_ch06$functional, na.rm = TRUE)))

cat("\n=== LME broad_environment | random=region (ch06) ===\n")
for (met in c("richness", "neutral", "phylogenetic", "functional")) {
  d <- ad %>% filter(!is.na(.data[[met]]), !is.na(broad_environment), !is.na(region))
  fit <- lme(as.formula(paste(met, "~ broad_environment")), random = ~1 | region, data = d)
  a <- anova(fit)
  cat(sprintf("%s: F=%.2f numDF=%d denDF=%d p=%.4f\n",
              met, a$`F-value`[2], a$numDF[2], a$denDF[2], a$`p-value`[2]))
}

cat("\n=== PERMANOVA beta (ch07/ch10) ===\n")
meta_beta <- sample_metadata %>% filter(!is.na(broad_environment))
for (nm in c("beta_q0n", "beta_q1n", "beta_q1p", "beta_q1f")) {
  d <- as.dist(get(nm)$S)
  samples <- attr(d, "Labels")
  m <- meta_beta %>% filter(sample %in% samples) %>% arrange(match(sample, samples))
  fit <- adonis2(d ~ broad_environment, data = m, permutations = 999)
  cat(sprintf("%s: R2=%.3f p=%.3f n=%d\n", nm, fit$R2[1], fit$`Pr(>F)`[1], nrow(m)))
}

cat("\n=== HMSC association counts (ch14/15 cache) ===\n")
if (exists("association_counts_fig")) print(association_counts_fig)
if (exists("post_table")) {
  for (v in names(post_table)) {
    tbl <- post_table[[v]]
    cat(sprintf("%s: Pos=%d Neg=%d Neu=%d sum=%d\n", v,
                sum(tbl == "Positive", na.rm = TRUE),
                sum(tbl == "Negative", na.rm = TRUE),
                sum(tbl == "Neutral", na.rm = TRUE),
                length(tbl)))
  }
}

cat("\n=== HMSC model scope (ch13) ===\n")
if (file.exists("hmsc/model_final")) {
  e <- new.env()
  load("hmsc/model_final", envir = e)
  m <- get("m", e)
  cat("model_final samples:", nrow(m$XData), "genomes:", ncol(m$Y), "\n")
  cat("Formula:", as.character(m$XFormula), "\n")
}

cat("\n=== COMPOSITION phylum means (ch04 logic) ===\n")
create_taxonomy_summary <- function(tax_level, group_vars) {
  genome_counts_filt %>%
    mutate(across(-genome, ~ . / sum(.))) %>%
    pivot_longer(-genome, names_to = "sample", values_to = "count") %>%
    left_join(genome_metadata %>% select(genome, all_of(tax_level)), by = "genome") %>%
    group_by(sample, across(all_of(c(tax_level, group_vars)))) %>%
    summarise(relabun = sum(count), .groups = "drop")
}
phylum_df <- create_taxonomy_summary("phylum", "broad_environment") %>%
  inner_join(sample_metadata %>% select(sample, broad_environment), by = "sample")
for (p in c("Bacillota_A", "Bacillota", "Pseudomonadota")) {
  sub <- phylum_df %>% filter(phylum == p)
  if (nrow(sub)) cat(sprintf("%s: %.1f ± %.1f%%\n", p, mean(sub$relabun) * 100, sd(sub$relabun) * 100))
}
family_df <- create_taxonomy_summary("family", "broad_environment") %>%
  inner_join(sample_metadata %>% select(sample, broad_environment), by = "sample")
for (f in c("Lachnospiraceae", "CAG-288", "Oscillospiraceae")) {
  sub <- family_df %>% filter(family == f)
  if (nrow(sub)) cat(sprintf("%s: %.1f ± %.1f%%\n", f, mean(sub$relabun) * 100, sd(sub$relabun) * 100))
}
