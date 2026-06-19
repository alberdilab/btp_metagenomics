# Bookdown Project — chapter order

Active chapters are numbered **01–15** in `_bookdown.yml` (filenames match knit order):

| # | File | Topic |
|---|------|--------|
| 01 | `01_prepare_data.Rmd` | Data loading and cleaning |
| 02 | `02_data_statistics.Rmd` | Summary statistics |
| 03 | `03_mag_catalogue.Rmd` | MAG catalogue |
| 04 | `04_community_composition.Rmd` | Community composition |
| 05 | `05_Enviroment_types.Rmd` | Landcover, climate, env Hill numbers |
| 06 | `06_alpha_diversity.Rmd` | Microbiome alpha diversity |
| 07 | `07_Functional_diffrences.Rmd` | Beta diversity / NMDS |
| 08 | `08_microbiota_abundance_analysis_sex.Rmd` | Differential abundance (sex) |
| 09 | `09_microbiota_functional_analysis.Rmd` | Functional microbiome |
| 10 | `10_enviromental_permanova.Rmd` | Env Hill ↔ microbiome β |
| 11 | `11_enviromental_abundance_analyses.Rmd` | Env Hill ↔ abundance |
| 12 | `12_diversity_abundance_analysis.Rmd` | Diversity–abundance links |
| 13 | `13_hmsc_setup_final.Rmd` | HMSC model setup (`model_final`) |
| 14 | `14_hmsc_analysis_final.Rmd` | HMSC analysis + `publication_hmsc.Rdata` cache |
| 15 | `15_publication_figures.Rmd` | Manuscript figure exports |

**Dependency check:** `Rscript .cursor/scripts/check_chapter_order.R`

**Full rebuild:** `Rscript .cursor/scripts/rebuild_from_scratch.R`

---

## General tips

- Move repeated code into `R/plot_helpers.R` or `R/chapter_deps.R`.
- Name chunks clearly; use `echo = FALSE`, `message = FALSE`, `warning = FALSE` for clean output.
- Cache heavy computations with `cache = TRUE` where appropriate.

See `_bookdown.yml` for the canonical chapter list.
