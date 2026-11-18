#!/usr/bin/env Rscript
# Rebuild plain-text analysis tables for the Ecology Letters deposit.
# Run from the project root: source("data/archive_deposit/code/00_export_archive_tables.R")

suppressPackageStartupMessages({
  if (!requireNamespace("ape", quietly = TRUE)) {
    stop("Package ape is required to write Newick trees.", call. = FALSE)
  }
})

out_dir <- "data/archive_deposit/tables"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

message("Loading analysis objects…")
load("data/data.Rdata")
load("data/publication_hmsc.Rdata")
load("hmsc/model_final")

meta_keep <- intersect(
  c(
    "sample", "sample_code", "species", "region", "sex", "country",
    "latitude", "longitude", "site", "island", "ENA_sample_accession",
    "Development", "Weight (g)", "Sampling date", "broad_environment",
    "local_environment", "reads_post_fastp", "host_reads",
    "metagenomic_bases", "singlem_fraction"
  ),
  names(sample_metadata)
)
write.csv(
  sample_metadata[, meta_keep, drop = FALSE],
  file.path(out_dir, "01_sample_metadata.csv"),
  row.names = FALSE
)

xdat <- m$XData
xdat$sample <- rownames(xdat)
sd <- as.data.frame(m$studyDesign)
sd$sample <- rownames(sd)
hmsc_cov <- merge(xdat, sd, by = "sample", all = TRUE)
hmsc_cov <- hmsc_cov[, c("sample", setdiff(names(hmsc_cov), "sample"))]
write.csv(hmsc_cov, file.path(out_dir, "02_hmsc_covariates.csv"), row.names = FALSE)

write.csv(genome_metadata, file.path(out_dir, "03_mag_taxonomy_quality.csv"), row.names = FALSE)
write.csv(
  data.frame(genome = colnames(m$Y)),
  file.path(out_dir, "04_hmsc_genomes.csv"),
  row.names = FALSE
)

rc <- read_counts
if (!("genome" %in% names(rc))) {
  rc <- cbind(genome = rownames(rc), as.data.frame(rc))
}
write.csv(rc, file.path(out_dir, "05_read_counts_genome_by_sample.csv"), row.names = FALSE)

Y <- as.data.frame(m$Y)
Y$sample <- rownames(Y)
Y <- Y[, c("sample", setdiff(names(Y), "sample"))]
write.csv(Y, file.path(out_dir, "06_hmsc_response_matrix_Y.csv"), row.names = FALSE)

gg <- genome_gifts
if (is.matrix(gg) || is.null(names(gg)) || !("genome" %in% names(as.data.frame(gg)))) {
  gg <- cbind(genome = rownames(as.data.frame(gg)), as.data.frame(gg))
}
write.csv(gg, file.path(out_dir, "07_genome_gifts.csv"), row.names = FALSE)

pt <- as.data.frame(post_table)
pt$genome <- rownames(pt)
pt <- pt[, c("genome", setdiff(names(pt), "genome"))]
write.csv(pt, file.path(out_dir, "08_hmsc_association_classes.csv"), row.names = FALSE)

vp <- varpart_fig$vals
vp_df <- as.data.frame(t(vp))
names(vp_df) <- make.names(rownames(vp), unique = TRUE)
vp_df$genome <- rownames(vp_df)
vp_df <- vp_df[, c("genome", setdiff(names(vp_df), "genome"))]
write.csv(vp_df, file.path(out_dir, "09_variance_partitioning.csv"), row.names = FALSE)

for (nm in c(
  "functional_diff_devil_fig",
  "functional_diff_temp_fig",
  "functional_diff_interaction_fig"
)) {
  if (exists(nm)) {
    write.csv(
      get(nm),
      file.path(out_dir, paste0("10_", nm, ".csv")),
      row.names = FALSE
    )
  }
}

ape::write.tree(hmsc_tree, file.path(out_dir, "11_hmsc_phylogeny.nwk"))
if (exists("genome_tree")) {
  ape::write.tree(genome_tree, file.path(out_dir, "11b_catalogue_phylogeny.nwk"))
}

if (file.exists("data/enviromental_var_ms.csv")) {
  file.copy(
    "data/enviromental_var_ms.csv",
    file.path(out_dir, "12_environment_multiscale.csv"),
    overwrite = TRUE
  )
}
if (file.exists("data/gift_colors.tsv")) {
  file.copy(
    "data/gift_colors.tsv",
    file.path(out_dir, "13_gift_function_colors.tsv"),
    overwrite = TRUE
  )
}

message("Wrote tables to ", normalizePath(out_dir))
message("Column dictionary: data/archive_deposit/tables/00_column_dictionary.csv")
