#!/usr/bin/env Rscript
# Second-pass audit: data integrity + parity checks for publication figures.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(stringr)
  library(ggplot2)
  library(patchwork)
  library(vegan)
  library(ape)
  library(hilldiv2)
  library(distillR)
  library(purrr)
})

source("R/plot_helpers.R")
load("data/data.Rdata")
load("data/beta.Rdata")
load("data/hill.Rdata")

gift_colors <- read_tsv("data/gift_colors.tsv") %>%
  mutate(legend = str_c(Code_function, " - ", Function))

landcover_wide <- read_csv("landcover_wide.csv", show_col_types = FALSE) %>%
  rename(sample = id)

env_settings <- environment_plot_settings()
filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
sample_metadata_fig <- filtered$metadata %>%
  mutate(broad_environment = factor(broad_environment, levels = env_settings$limits))
genome_counts_fig <- filtered$genome_counts

issues <- character()

# --- Sample hygiene ---
if ("EHI01340" %in% sample_metadata_fig$sample) {
  issues <- c(issues, "EHI01340 still present in sample_metadata_fig")
}
if ("EHI01340" %in% colnames(genome_counts_fig)) {
  issues <- c(issues, "EHI01340 still present in genome_counts_fig")
}

# --- A3 landcover ---
lc_df <- prepare_landcover_plot_df(landcover_wide, sample_ids = sample_metadata_fig$sample)
lc_sums <- lc_df %>% group_by(sample) %>% summarise(s = sum(pct), .groups = "drop")
if (any(abs(lc_sums$s - 100) > 0.05, na.rm = TRUE)) {
  issues <- c(issues, paste("A3: landcover pct sums not ~100 for", sum(abs(lc_sums$s - 100) > 0.05), "samples"))
}
if (any(lc_df$group == "Water", na.rm = TRUE)) {
  issues <- c(issues, "A3: Water group not fully removed")
}
missing_lc <- setdiff(sample_metadata_fig$sample, unique(lc_df$sample))
if (length(missing_lc) > 0) {
  issues <- c(issues, paste("A3: missing landcover for", length(missing_lc), "metadata samples"))
}

# --- A1/A2 Tasmania map filter (island arg must not shadow island column) ---
sample_points_audit <- readr::read_csv("sample_points.csv", show_col_types = FALSE) %>%
  dplyr::rename(sample = id) %>%
  dplyr::filter(sample != "EHI01340")
tas_map_pts <- prepare_tasmania_map_points(sample_metadata_fig, sample_points_audit)
if (nrow(tas_map_pts) != sum(sample_metadata_fig$island == "Tasmania", na.rm = TRUE)) {
  issues <- c(
    issues,
    paste0(
      "A1/A2: Tasmania map has ", nrow(tas_map_pts), " points; expected ",
      sum(sample_metadata_fig$island == "Tasmania", na.rm = TRUE),
      " (check island filter shadowing)"
    )
  )
}

# --- B1 alpha parity with ch5 pattern ---
alpha_new <- calculate_alpha_diversity(genome_counts_fig, genome_tree, genome_gifts, GIFT_db)
if (!all(c("richness", "neutral", "phylogenetic", "functional") %in% names(alpha_new))) {
  issues <- c(issues, "B1: missing alpha metric columns")
}
if (any(is.na(alpha_new))) {
  issues <- c(issues, paste("B1: NA values in alpha metrics:", sum(is.na(alpha_new))))
}
if (nrow(alpha_new) != length(intersect(alpha_new$sample, sample_metadata_fig$sample))) {
  issues <- c(issues, "B1: alpha sample count mismatch vs metadata overlap")
}

# Recompute ch5-style alpha for comparison on same samples
otus <- genome_counts_fig$genome
tree_pruned <- drop.tip(genome_tree, setdiff(genome_tree$tip.label, otus))
counts_mat <- genome_counts_fig %>%
  column_to_rownames("genome") %>%
  select(where(~ !all(. == 0)))
richness_ref <- counts_mat %>% hilldiv(., q = 0) %>% t() %>% as.data.frame() %>%
  rename(richness = 1) %>% rownames_to_column("sample")
cmp <- inner_join(alpha_new %>% select(sample, richness), richness_ref, by = "sample", suffix = c("_new", "_ref"))
if (!isTRUE(all.equal(cmp$richness_new, cmp$richness_ref, tolerance = 1e-6))) {
  issues <- c(issues, "B1: richness differs from ch5-style recomputation")
}

# --- C1 NMDS sample overlap (dist Labels, not rownames) ---
for (nm in c("beta_q0n", "beta_q1n", "beta_q1p", "beta_q1f")) {
  mat <- get(nm)$S
  labels <- attr(mat, "Labels")
  if (is.null(labels)) {
    issues <- c(issues, paste("C1:", nm, "distance matrix missing Labels attribute"))
    next
  }
  joined <- intersect(labels, sample_metadata_fig$sample)
  if (length(joined) == 0) {
    issues <- c(issues, paste("C1:", nm, "has zero sample overlap with metadata"))
  }
  if ("EHI01340" %in% labels) {
    issues <- c(issues, paste("C1:", nm, "still contains EHI01340 in Labels"))
  }
}

# --- G1 circular phylogeny overlap ---
filtered_audit <- filter_study_samples(sample_metadata, genome_counts_filt)
study_ids <- study_genome_ids(filtered_audit$genome_counts)
g1_overlap <- intersect(study_ids, genome_tree$tip.label)
if (length(g1_overlap) == 0) {
  issues <- c(issues, "G1: no study genomes overlap genome_tree tips")
}

# --- Publication figure caches ---
cache_paths <- publication_cache_paths()
for (cache_path in cache_paths) {
  if (!file.exists(cache_path)) {
    issues <- c(issues, paste("Missing publication cache:", cache_path))
  }
}

# --- HMSC / F-block checks (from publication cache) ---
if (file.exists(cache_paths$hmsc)) {
  hmsc_env <- new.env()
  load(cache_paths$hmsc, envir = hmsc_env)

  post_table <- hmsc_env$post_table
  elements_response <- hmsc_env$elements_response
  hmsc_tree <- hmsc_env$hmsc_tree

  required_cols <- c("devil", "temperature", "devil:temperature", "diversity", "logseqdepth")
  missing_cols <- setdiff(required_cols, colnames(post_table))
  if (length(missing_cols) > 0) {
    issues <- c(issues, paste("F-block: post_table missing columns:", paste(missing_cols, collapse = ", ")))
  }

  if (is.null(attr(hmsc_env$functional_diff_interaction_fig, "comparison_note"))) {
    issues <- c(
      issues,
      "F4: functional_diff_interaction_fig should use calculate_functional_beta_by_gift (abundance contrast mirrors devil)"
    )
  } else {
    mirror_check <- audit_hmsc_spotlight_contrasts(
      post_table,
      hmsc_env$functional_diff_devil_fig,
      calculate_functional_differences(elements_response, "devil:temperature"),
      fc_threshold = 0.2,
      fdr_threshold = 0.05
    )
    if (!isTRUE(mirror_check$mirror_warning)) {
      issues <- c(issues, "F4: expected mirror_warning for old abundance interaction method")
    }
    beta_int <- hmsc_env$functional_diff_interaction_fig
    sig_beta <- beta_int %>%
      dplyr::filter(!is.na(.data$p_adj), .data$p_adj < 0.05, abs(.data$diff) >= 0.05)
    if (nrow(sig_beta) == 0) {
      issues <- c(issues, "F4: no significant interaction beta-by-GIFT traits in cache")
    }
    if (sum(sig_beta$diff > 0) == 0 || sum(sig_beta$diff < 0) == 0) {
      issues <- c(issues, "F4: interaction beta-by-GIFT lacks mixed positive/negative effects")
    }
  }

  fd_int <- tryCatch(
    calculate_functional_beta_by_gift(
      hmsc_env$interaction_ci_fig,
      elements_response,
      min_genomes = 10
    ),
    error = function(e) e
  )
  if (inherits(fd_int, "error")) {
    issues <- c(issues, paste("F4: calculate_functional_beta_by_gift failed:", fd_int$message))
  }

  if (is.null(hmsc_env$varpart_fig)) {
    issues <- c(issues, "F1: varpart_fig missing from publication_hmsc cache")
  } else {
    vp_vars <- rownames(hmsc_env$varpart_fig$vals)
    missing_vp <- setdiff(vp_vars, hmsc_varpart_levels())
    if (length(missing_vp) > 0) {
      issues <- c(issues, paste("F1: varpart variables missing from level order:", paste(missing_vp, collapse = ", ")))
    }
  }

  gift_colors_audit <- readr::read_tsv("data/gift_colors.tsv", show_col_types = FALSE) %>%
    dplyr::mutate(legend = stringr::str_c(.data$Code_function, " - ", .data$Function))
  f8_plot_data <- prepare_functional_predictor_comparison(
    functional_diff_list = list(
      devil = hmsc_env$functional_diff_devil_fig,
      temperature = hmsc_env$functional_diff_temp_fig,
      interaction = hmsc_env$functional_diff_interaction_fig
    ),
    predictor_labels = c("Devil density", "Temperature", "Devil x temperature"),
    gift_colors = gift_colors_audit,
    fc_threshold = c(0.2, 0.2, 0.05),
    fdr_threshold = 0.05,
    trait_set = "per_panel"
  )
  f8_gift_sets <- f8_plot_data %>%
    dplyr::group_by(.data$predictor_label) %>%
    dplyr::summarise(gifts = list(sort(.data$GIFT)), .groups = "drop")
  if (length(unique(f8_gift_sets$gifts)) < 3L) {
    issues <- c(issues, "F8: per-panel GIFT sets are not distinct across predictors")
  }
  f8_x_sums <- vapply(
    c("Devil density", "Temperature", "Devil x temperature"),
    function(lab) {
      p <- create_functional_climate_stripe_panel(f8_plot_data, lab, NULL, show_non_sig = FALSE)
      b <- ggplot2::ggplot_build(p)
      hit <- b$data[[which.max(vapply(b$data, function(d) {
        if ("width" %in% names(d)) max(d$width, na.rm = TRUE) else 0
      }, numeric(1)))]]
      sum(hit$x, na.rm = TRUE)
    },
    numeric(1)
  )
  if (length(unique(round(f8_x_sums, 4))) < 3) {
    issues <- c(
      issues,
      paste0(
        "F8: climate panels identical (dplyr arg shadowing?) — x sums: ",
        paste(round(f8_x_sums, 4), collapse = ", ")
      )
    )
  }

  if (nrow(hmsc_env$association_counts_fig) == 0) {
    issues <- c(issues, "F1: association_counts empty")
  }

  cong_func <- hmsc_env$congruence_func_fig
  if (nrow(cong_func) == 0) {
    issues <- c(issues, "F5: functional congruence data empty")
  }
  if (any(cong_func$mean_val < 0, na.rm = TRUE)) {
    issues <- c(issues, "F5: negative mean_val in functional congruence (alpha scale risk)")
  }

  if (nrow(hmsc_env$devil_beta_fig) == 0) {
    issues <- c(issues, "F2: devil_beta_fig empty in cache")
  }

  if (nrow(hmsc_env$devil_ci_top_fig) > 40) {
    issues <- c(issues, paste("F2: top genomes returned", nrow(hmsc_env$devil_ci_top_fig), "> 40"))
  }

  phylo_gift <- build_phylo_gift_fig_data(
    hmsc_tree, genome_metadata, genome_gifts, GIFT_db, post_table, max_genomes = 120,
    beta_ci_list = spotlight_beta_ci_list(
      hmsc_env$devil_ci_fig, hmsc_env$temp_ci_fig, hmsc_env$interaction_ci_fig
    )
  )
  if (is.null(phylo_gift)) {
    issues <- c(issues, "F6: no spotlight-significant genomes")
  } else {
    tips <- phylo_gift$tree$tip.label
    if (!identical(rownames(phylo_gift$phylum), tips) ||
        !identical(rownames(phylo_gift$beta), tips) ||
        !identical(rownames(phylo_gift$gift), tips)) {
      issues <- c(issues, "F6: annotation matrix row order mismatch vs tree tips")
    }
    if (ncol(phylo_gift$beta) != 4) {
      issues <- c(issues, "F6: beta matrix should have 3 HMSC columns")
    }
    if (ncol(phylo_gift$gift) == 0) {
      issues <- c(issues, "F6: empty GIFT element matrix")
    }
  }

  fake_ancom <- list(res = tibble::tibble(
    taxon = rownames(post_table)[1:3],
    lfc_env_div_group0High = c(0.5, -0.2, 0.1),
    p_env_div_group0High = c(0.01, 0.2, 0.5)
  ))
  d4_tbl <- extract_ancombc_diff_table(fake_ancom)
  if (is.null(d4_tbl) || sum(d4_tbl$sig) != 1) {
    issues <- c(issues, "ANCOM helper: extract_ancombc_diff_table failed on mock output")
  }
} else {
  issues <- c(issues, "HMSC audit skipped: publication_hmsc cache not found")
}

# --- PDF existence ---
expected_pdfs <- c(
  "fig_A1_tasmania_environment_map.pdf",
  "fig_A2_tasmania_devil_density_map.pdf",
  "fig_A3_landcover_stacked.pdf",
  "fig_B1_alpha_diversity.pdf",
  "fig_C1_beta_nmds.pdf",
  "fig_G1_circular_phylogeny.pdf",
  "fig_E1_phylum_stacked.pdf",
  "fig_E1b_phylum_stacked_faceted.pdf",
  "fig_E2_family_sankey.pdf",
  "fig_E3_dominant_mag_tile.pdf",
  "fig_F1_hmsc_hero.pdf",
  "fig_F2_devil_spotlight.pdf",
  "fig_F3_temperature_spotlight.pdf",
  "fig_F4_interaction_spotlight.pdf",
  "fig_F5_devil_temp_congruence.pdf",
  "fig_F6_phylo_gift_heatmap.pdf",
  "fig_F7_threeway_congruence.pdf",
  "fig_F8_devil_hmsc_thresholds.pdf",
  "fig_F8_temperature_hmsc_thresholds.pdf",
  "fig_F8_interaction_hmsc_thresholds.pdf",
  "fig_F8_diversity_hmsc_thresholds.pdf"
)
missing_pdfs <- expected_pdfs[!file.exists(file.path("figures", expected_pdfs))]
if (length(missing_pdfs) > 0) {
  issues <- c(issues, paste("Missing PDFs:", paste(missing_pdfs, collapse = ", ")))
}

small_pdfs <- expected_pdfs[file.exists(file.path("figures", expected_pdfs)) &
  file.info(file.path("figures", expected_pdfs))$size < 2000]
if (length(small_pdfs) > 0) {
  issues <- c(issues, paste("Suspiciously small PDFs (<2KB):", paste(small_pdfs, collapse = ", ")))
}

if (length(issues) == 0) {
  cat("AUDIT PASS: no issues found\n")
} else {
  cat("AUDIT ISSUES (", length(issues), "):\n", sep = "")
  for (i in seq_along(issues)) cat(i, ". ", issues[i], "\n", sep = "")
  quit(status = 1)
}
