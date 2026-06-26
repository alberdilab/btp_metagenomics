#!/usr/bin/env Rscript
# Comprehensive manuscript number audit — all caches and chapter logic.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(nlme)
  library(vegan)
  library(readr)
})

source("R/plot_helpers.R")

load("data/data.Rdata")
load("data/beta.Rdata")
load("data/publication_base.Rdata")
load("data/publication_hmsc.Rdata")

if (!exists("functional_diff_diversity_fig")) {
  functional_diff_diversity_fig <- calculate_functional_differences(elements_response, "diversity")
}

predictors <- read_csv("data/animal_var.csv", show_col_types = FALSE) %>%
  inner_join(read_csv("data/environment_var_r200.csv", show_col_types = FALSE), by = "id") %>%
  rename(sample = id) %>%
  inner_join(sample_metadata %>% select(sample, island), by = "sample")

tas_pred <- predictors %>% filter(island == "Tasmania")

cat("========== CATALOGUE ==========\n")
cat("Samples:", nrow(sample_metadata), "Tas:", sum(sample_metadata$island == "Tasmania"),
    "Aus:", sum(sample_metadata$island == "Australia"), "\n")
cat("MAGs:", nrow(genome_metadata), "\n")
cat("HMSC scope:", nrow(post_table), "genomes in post_table\n")
total_gb <- sum(sample_metadata$reads_post_fastp * 150 / 1e9)
cat(sprintf("Total Gb: %.1f; per sample: %.2f ± %.2f\n", total_gb, mean(sample_metadata$reads_post_fastp * 150 / 1e9), sd(sample_metadata$reads_post_fastp * 150 / 1e9)))
if ("completeness" %in% names(genome_metadata)) {
  cat(sprintf("CheckM: %.1f ± %.1f complete; %.2f ± %.2f contam\n",
              mean(genome_metadata$completeness), sd(genome_metadata$completeness),
              mean(genome_metadata$contamination), sd(genome_metadata$contamination)))
}

cat("\n========== COMPOSITION (rel abun %) ==========\n")
gc <- genome_counts_filt %>%
  pivot_longer(-genome, names_to = "sample", values_to = "count") %>%
  group_by(sample) %>%
  mutate(rel = count / sum(count)) %>%
  ungroup() %>%
  left_join(genome_metadata %>% select(genome, phylum, family), by = "genome")

phylum_mean <- gc %>% group_by(phylum) %>%
  summarise(mean_pct = 100 * mean(rel, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(mean_pct))
print(head(phylum_mean, 6))

fam_mean <- gc %>% group_by(family) %>%
  summarise(mean_pct = 100 * mean(rel, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(mean_pct))
print(head(fam_mean, 6))

cat("\n========== ALPHA DIVERSITY ==========\n")
ad <- alpha_div_fig %>%
  inner_join(sample_metadata %>% select(sample, broad_environment, region, island), by = "sample")
for (met in c("richness", "neutral", "phylogenetic", "functional")) {
  cat(sprintf("%s: %.2f ± %.2f\n", met, mean(ad[[met]], na.rm = TRUE), sd(ad[[met]], na.rm = TRUE)))
}

cat("\n--- LME broad_environment | random region ---\n")
for (met in c("richness", "neutral", "phylogenetic", "functional")) {
  d <- ad %>% filter(!is.na(.data[[met]]), !is.na(broad_environment), !is.na(region))
  fit <- lme(as.formula(paste(met, "~ broad_environment")), random = ~1 | region, data = d)
  a <- anova(fit)
  cat(sprintf("%s: F=%.2f df=%d,%d p=%.4f\n", met, a$`F-value`[2], a$numDF[2], a$denDF[2], a$`p-value`[2]))
}

cat("\n========== PERMANOVA ==========\n")
meta_beta <- sample_metadata %>% filter(!is.na(broad_environment))
for (nm in c("beta_q0n", "beta_q1n", "beta_q1p", "beta_q1f")) {
  d <- as.dist(get(nm)$S)
  samples <- attr(d, "Labels")
  m <- meta_beta %>% filter(sample %in% samples) %>% arrange(match(sample, samples))
  fit <- adonis2(d ~ broad_environment, data = m, permutations = 999)
  cat(sprintf("env %s: R2=%.3f p=%.3f\n", nm, fit$R2[1], fit$`Pr(>F)`[1]))
  fit2 <- adonis2(d ~ island, data = m, permutations = 999)
  cat(sprintf("island %s: R2=%.3f p=%.3f\n", nm, fit2$R2[1], fit2$`Pr(>F)`[1]))
}

cat("\n========== HMSC ASSOCIATION COUNTS ==========\n")
pt <- tibble::rownames_to_column(post_table, "genome") %>%
  left_join(genome_metadata %>% select(genome, phylum, family), by = "genome")
for (v in c("devil", "temperature", "diversity", "devil:temperature")) {
  tbl <- table(post_table[[v]])
  cat(v, ": ", paste(names(tbl), tbl, sep = "=", collapse = ", "), " sum=", sum(tbl), "\n")
}

cat("\n========== CONGRUENCE ==========\n")
print(summarise_devil_temp_congruence(post_table))

cat("\nDevil-temp cor Tasmania n=55:", round(cor(tas_pred$devil, tas_pred$temperature), 3), "\n")

cat("\n========== TAXA BY ASSOCIATION ==========\n")
for (assoc in c("devil", "temperature", "diversity")) {
  pos <- pt %>% filter(.data[[assoc]] == "Positive")
  neg <- pt %>% filter(.data[[assoc]] == "Negative")
  cat("\n", toupper(assoc), " POS n=", nrow(pos), "\n")
  cat("  Bacillota_A:", sum(pos$phylum == "p__Bacillota_A"), "\n")
  print(sort(table(pos$family), decreasing = TRUE)[1:4])
  cat(" NEG n=", nrow(neg), "\n")
  print(sort(table(neg$family), decreasing = TRUE)[1:4])
}

cat("\nTemp+ Bacillota_A:", sum(pt$temperature == "Positive" & pt$phylum == "p__Bacillota_A"), "/",
    sum(pt$temperature == "Positive"), "\n")
cat("Temp+ Lach:", sum(pt$temperature == "Positive" & pt$family == "f__Lachnospiraceae"), "\n")
cat("Temp+ Osc:", sum(pt$temperature == "Positive" & pt$family == "f__Oscillospiraceae"), "\n")
cat("Devil+ Lach:", sum(pt$devil == "Positive" & pt$family == "f__Lachnospiraceae"), "\n")
cat("Devil+ Osc:", sum(pt$devil == "Positive" & pt$family == "f__Oscillospiraceae"), "\n")
cat("Devil- CAG-508:", sum(pt$devil == "Negative" & pt$family == "f__CAG-508"), "\n")

cat("\n========== INTERACTION OVERLAP ==========\n")
cat("Int+ & devil-:", sum(pt$devil == "Negative" & pt[["devil:temperature"]] == "Positive"), "\n")
cat("Int- & devil+ & temp+:", sum(pt$devil == "Positive" & pt$temperature == "Positive" & pt[["devil:temperature"]] == "Negative"), "\n")

cat("\n========== FUNCTIONAL VOLCANO (FDR < 0.05) ==========\n")
sig_summary <- function(df, fc = NULL, label = "") {
  d <- df %>% filter(!is.na(p_adj), p_adj < 0.05)
  if (!is.null(fc)) d <- d %>% filter(abs(diff) >= fc)
  cat(label, " n=", nrow(d), " pos=", sum(d$diff > 0), " neg=", sum(d$diff < 0), "\n")
}
sig_summary(functional_diff_devil_fig, label = "devil FDR")
sig_summary(functional_diff_devil_fig, 0.2, "devil FDR+fc0.2")
sig_summary(functional_diff_temp_fig, label = "temp FDR")
sig_summary(functional_diff_temp_fig, 0.2, "temp FDR+fc0.2")
sig_summary(functional_diff_diversity_fig, label = "div FDR")
sig_summary(functional_diff_diversity_fig, 0.2, "div FDR+fc0.2")
sig_summary(functional_diff_interaction_fig, 0.05, "int FDR+fc0.05")

cat("\nDiversity pos GIFT (FDR):\n")
print(functional_diff_diversity_fig %>% filter(!is.na(p_adj), p_adj < 0.05, diff > 0) %>% select(GIFT, diff, p_adj))

cat("\nTemp marginal S03:\n")
print(functional_diff_temp_fig %>% filter(grepl("^S03", GIFT)) %>% arrange(p_adj) %>% select(GIFT, diff, p_adj) %>% head(3))

cat("\n========== MIRROR CHECK interaction abundance ==========\n")
fd_int_abund <- calculate_functional_differences(elements_response, "devil:temperature")
mirror <- audit_hmsc_spotlight_contrasts(post_table, functional_diff_devil_fig, fd_int_abund)
print(mirror[c("mirror_warning", "diff_correlation", "n_sig_devil", "n_sig_interaction")])

cat("\nDONE\n")
