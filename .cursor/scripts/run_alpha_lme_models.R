#!/usr/bin/env Rscript
# Compute alpha diversity (ch06) and LME/LM models for manuscript stats.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(stringr)
  library(nlme)
  library(emmeans)
  library(ape)
  library(hilldiv2)
  library(distillR)
})

outlier_sample <- "EHI01340"
sample_metadata <- read_tsv("data/merged_metadata.tsv") %>%
  rename(sample = 1) %>%
  filter(sample != outlier_sample)

sample_sites <- read_csv("data/sample_sites.csv", show_col_types = FALSE)
sample_metadata <- sample_metadata %>%
  left_join(sample_sites, by = c("sample" = "id")) %>%
  mutate(
    island = case_when(
      latitude < -38 & latitude > -45 &
        longitude > 140 & longitude < 150 ~ "Tasmania",
      TRUE ~ "Australia"
    ),
    broad_environment = factor(
      broad_environment,
      levels = c(
        "1000198 - Mixed forest",
        "1000221 - Temperate woodland",
        "1000218 - Xeric shrubland",
        "1000215 - Temperate shrubland",
        "1000245 - Cropland"
      )
    ),
    region = factor(region),
    sex = factor(sex)
  )

valid_samples <- sample_metadata$sample
read_counts <- read_tsv("data/DMB0167_counts.tsv.gz") %>%
  rename(genome = 1) %>%
  select(any_of(c("genome", valid_samples)))

genome_metadata <- read_tsv("data/DMB0167_mag_info.tsv.gz") %>%
  rename(length = mag_size) %>%
  semi_join(read_counts, by = "genome") %>%
  arrange(match(genome, read_counts$genome))

genome_coverage <- read_tsv("data/DMB0167_coverage.tsv.gz") %>%
  rename(genome = 1) %>%
  select(any_of(c("genome", valid_samples))) %>%
  semi_join(genome_metadata, by = "genome") %>%
  arrange(match(genome, read_counts$genome))

min_coverage <- 0.3
sample_cols <- setdiff(names(read_counts), "genome")
coverage_mask <- genome_coverage %>%
  mutate(across(where(is.numeric), ~ ifelse(. > min_coverage, 1, 0)))

read_counts_filt <- read_counts %>%
  left_join(coverage_mask, by = "genome", suffix = c("", "_mask"))

for (col in sample_cols) {
  mask_col <- paste0(col, "_mask")
  read_counts_filt[[col]] <- read_counts_filt[[col]] * read_counts_filt[[mask_col]]
}

read_counts_filt <- read_counts_filt %>%
  select(genome, all_of(sample_cols))

readlength <- 150
genome_length_lookup <- genome_metadata %>% select(genome, mag_length = length)
genome_counts_filt <- read_counts_filt %>%
  left_join(genome_length_lookup, by = "genome") %>%
  mutate(across(-c(genome, mag_length), ~ . / (mag_length / readlength))) %>%
  select(-mag_length)

genome_tree <- read.tree(gzfile("data/DMB0167.tree.gz"))
genome_tree$tip.label <- str_replace_all(genome_tree$tip.label, "'", "")
genome_tree <- keep.tip(genome_tree, genome_metadata$genome)
otus <- genome_counts_filt$genome
genome_tree_pruned <- drop.tip(genome_tree, setdiff(genome_tree$tip.label, otus))

message("Loading genome annotations for GIFT...")
genome_annotations <- read_tsv("data/genome_annotations.tsv.xz", show_col_types = FALSE) %>%
  rename(gene = 1, genome = 2, contig = 3)

message("Distilling GIFT traits...")
genome_gifts <- distill(
  genome_annotations, GIFT_db,
  genomecol = 2, annotcol = c(9, 10, 19), verbosity = FALSE
)

richness <- genome_counts_filt %>%
  column_to_rownames("genome") %>%
  select(where(~ !all(. == 0))) %>%
  hilldiv(., q = 0) %>%
  t() %>%
  as.data.frame() %>%
  rename(richness = 1) %>%
  rownames_to_column("sample")

neutral <- genome_counts_filt %>%
  column_to_rownames("genome") %>%
  select(where(~ !all(. == 0))) %>%
  hilldiv(., q = 1) %>%
  t() %>%
  as.data.frame() %>%
  rename(neutral = 1) %>%
  rownames_to_column("sample")

phylogenetic <- genome_counts_filt %>%
  column_to_rownames("genome") %>%
  select(where(~ !all(. == 0))) %>%
  hilldiv(., q = 1, tree = genome_tree_pruned) %>%
  t() %>%
  as.data.frame() %>%
  rename(phylogenetic = 1) %>%
  rownames_to_column("sample")

dist <- genome_gifts %>%
  to.elements(., GIFT_db) %>%
  traits2dist(., method = "gower")

functional <- genome_counts_filt %>%
  filter(genome %in% rownames(dist)) %>%
  arrange(match(genome, rownames(dist))) %>%
  column_to_rownames("genome") %>%
  select(where(~ !all(. == 0))) %>%
  hilldiv(., q = 1, dist = dist) %>%
  t() %>%
  as.data.frame() %>%
  rename(functional = 1) %>%
  rownames_to_column("sample") %>%
  filter(!is.nan(functional), !is.na(functional))

alpha_div <- richness %>%
  full_join(neutral, by = "sample") %>%
  full_join(phylogenetic, by = "sample") %>%
  full_join(functional, by = "sample")

alpha_div_meta <- alpha_div %>%
  inner_join(sample_metadata, by = "sample")

cat("Samples:", nrow(alpha_div_meta), "\n")
cat("Regions:", nlevels(alpha_div_meta$region), "\n")
cat(sprintf(
  "Functional alpha: %.2f ± %.2f\n",
  mean(alpha_div_meta$functional, na.rm = TRUE),
  sd(alpha_div_meta$functional, na.rm = TRUE)
))

metrics <- c("richness", "neutral", "phylogenetic", "functional")
results <- list()

for (met in metrics) {
  d <- alpha_div_meta %>%
    filter(
      !is.na(.data[[met]]),
      !is.na(broad_environment),
      !is.na(region),
      !is.na(sex)
    )

  fit_env <- lme(
    as.formula(paste(met, "~ broad_environment")),
    random = ~ 1 | region,
    data = d,
    method = "REML"
  )
  a_env <- anova(fit_env)

  fit_lm <- lm(
    as.formula(paste(met, "~ broad_environment + sex")),
    data = d
  )
  a_lm <- anova(fit_lm)

  fit_sex <- lme(
    as.formula(paste(met, "~ sex")),
    random = ~ 1 | broad_environment,
    data = d,
    method = "REML"
  )
  a_sex <- anova(fit_sex)

  cat("\n==========", toupper(met), "(n =", nrow(d), ") ==========\n")
  cat("LME broad_environment | random = region:\n")
  print(a_env)
  cat("LM broad_environment + sex:\n")
  print(a_lm)
  cat("LME sex | random = broad_environment:\n")
  print(a_sex)

  results[[met]] <- list(
    n = nrow(d),
    lme_env = a_env,
    lm = a_lm,
    lme_sex = a_sex
  )
}

invisible(results)
