# Data and code archive (Ecology Letters deposit package)

Working package for the brushtail possum gut-microbiome manuscript. This folder is the content that should be uploaded to Zenodo or Dryad at submission (private-for-peer-review link), with the resulting DOI inserted into the manuscript data statement.

## Contents

```
archive_deposit/
  README.md                          # this file
  tables/
    00_column_dictionary.csv         # units and column descriptions (task 34)
    01_sample_metadata.csv
    02_hmsc_covariates.csv           # predictors + random levels used in HMSC
    03_mag_taxonomy_quality.csv
    04_hmsc_genomes.csv              # 576 genomes in the fitted model
    05_read_counts_genome_by_sample.csv
    14_DMB0167_coverage.tsv.gz          # CoverM horizontal coverage fractions (genome × sample)
    06_hmsc_response_matrix_Y.csv    # modelled Y (length-normalised, +1, log)
    07_genome_gifts.csv              # genome × GIFT completeness
    08_hmsc_association_classes.csv
    09_variance_partitioning.csv
    10_functional_diff_*.csv
    11_hmsc_phylogeny.nwk
    11b_catalogue_phylogeny.nwk
    12_environment_multiscale.csv
    13_gift_function_colors.tsv
  code/
    00_export_archive_tables.R       # rebuilds tables/ from project caches
    01_retrieve_environmental_layers.R
```

## How the tables map to the paper

| Result | Primary tables |
| --- | --- |
| MAG catalogue (1,817 genomes) | `03`, `05`, `11b` |
| Tasmania HMSC model (55 samples × 576 genomes) | `02`, `04`, `06`, `08`, `09`, `11` |
| Functional volcano / GIFT contrasts | `07`, `08`, `10_*`, `13` |
| Environmental context / maps | `01`, `02`, `12` |

## Coverage filter

CoverM horizontal coverage fractions are deposited as `14_DMB0167_coverage.tsv.gz`. A genome is treated as present in a sample only if horizontal coverage is ≥ 30% (`CoverM --min-covered-fraction 0.3`). Downstream Hill richness (q = 0) and other presence/diversity analyses use that filtered representation. The HMSC response matrix is built from length-normalised pipeline read counts for the pinned 576-genome set (not the 30% zeroed presence matrix): table `05` is the pipeline count table; table `06` is the exact HMSC Y after length normalisation, +1 and log transform (`13_hmsc_setup_final.Rmd`).

## External data sources (cite in manuscript and deposit)

1. **WorldClim v2.1** bioclimatic variables (BIO1 temperature; precipitation) — Fick & Hijmans (2017). Retrieved via `geodata::worldclim_country()`.
2. **Digital Earth Australia / Geoscience Australia land cover** (class raster tiles; calendar-year product styled as `landcover_class_cyear_4`) — extracted in 100/200/400 m buffers; primary analysis scale = **200 m**.
3. **Tasmanian devil density** surfaces `predictionStack_devils_1985to2035.tif` (2021–2023 mean within 200 m) — Cunningham et al. (2021) and associated monitoring products.
4. **WorldPop** Australia population density 2020 (1 km) — https://www.worldpop.org / data.worldpop.org.
5. **Map outlines** in figures use **Natural Earth** country boundaries via `rnaturalearth` (public domain).

## Reproduce locally

From the project root (`btp_metagenomics/`):

```r
source("data/archive_deposit/code/00_export_archive_tables.R")
```

Heavy HMSC fitting is not re-run by these scripts. The fitted posterior object lives outside this lightweight deposit (`hmsc/Hmsc_model_final.rds` / ERDA). Analysis notebooks are `01_prepare_data.Rmd`–`16_hmsc_group_prediction.Rmd`; rendered overview: https://alberdilab.github.io/btp_metagenomics/

Environmental layer download (requires network and local disk):

```r
source("data/archive_deposit/code/01_retrieve_environmental_layers.R")
```

## Taxonomy release

MAG taxonomy in this deposit follows **GTDB release R214** (GTDB-Tk; EHI-standard pipeline), matching the manuscript Methods.

## Still required before journal submission

- Ethics / collection permit numbers in the manuscript Methods
- INSDC BioProject / run / MAG accessions printed in the manuscript (when fully assigned)
- Real Zenodo/Dryad DOI replacing the placeholder in Methods (upload this package)
- MAG FASTA and raw reads in INSDC or linked from the deposit README
- Optional: ship `hmsc/Hmsc_model_final.rds` if the repository size limit allows, or link the ERDA mirror in the README

## Export timestamp

Tables were generated from `data/data.Rdata`, `data/publication_hmsc.Rdata` and `hmsc/model_final` in the project working tree. Package zip refreshed **2026-11-18** for Zenodo readiness (table row checks: 72 samples, 55 HMSC covariates, 576 HMSC genomes, 1,817 catalogue MAGs).
