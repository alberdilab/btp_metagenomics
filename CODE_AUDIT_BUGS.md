# Code audit — bug report

**Project:** BTP metagenomics (`btp_metagenomics`)  
**Last updated:** 2026-06-17 (audit round 8; chapter files renumbered 01–14 June 2026)  
**Scope:** Bookdown chapters `01`–`14`, `index.Rmd`, `_main.Rmd`, `R/plot_helpers.R`, `.cursor/scripts/*.R`, `archive/` (legacy HMSC chapters)

**Method:** Round 8 = **Pass 1** (parallel chapter audits ch01–19) + **Pass 2** (runtime verification, MD5 checks, fix verification) + **repairs** for critical/high bugs.

**Status legend:** `Open` | `Fixed` | `Partial` | `Refuted` | `Stale` | *needs human decision*

**Chapter renumbering (June 2026):** filenames now match bookdown order `01`–`14`. Pre-renumber labels in audit prose (e.g. “ch06” for beta) may still appear below; use the **File** column for current paths.

---

## Executive summary (round 8)

| Severity | Open | Fixed (all rounds) | Refuted/Stale |
|----------|-----:|-------------------:|--------------:|
| Critical | 0 | 12 | 0 |
| High | 16 | 14 | 3 |
| Medium | 40 | 0 | 4 |
| Low | 24 | 1 | 2 |
| Doc / consistency | 9 | 0 | 1 |

**Round 8 fixes applied:**
1. **R7-001** — ch06 ggplot chain + single NMDS fit per matrix
2. **HMSC-001** — `hmsc/model_tasmania` rebuilt (55 samples, 901 genomes)
3. **R7-002 / BUG-015** — ch05 functional alpha row alignment
4. **BUG-011 / R7-003** — ch07 ANCOM uses `physeq_genome_filtered`
5. **BUG-024** — F5 taxonomic tile uses proportions
6. **R7-007 / BUG-013** — ch08 Wilcoxon guards
7. **R8-001 / HMSC-002** — HMSC sample-count guards (ch15–18)
8. **R8-002** — ch11 EHI01340 dropped from count matrix

**Still open (high):** ch15 ERDA posterior mismatch (901 vs 939 genomes — HPC re-run needed); ch10 PERMANOVA pairing (*needs human decision*); HMSC-003/004 orphan `model_env` / r200 vs r400 buffer

**Verification (closed):** All round-8 fixes confirmed via `verify_round8_fixes.R` + `audit_publication_figures.R` PASS

---

## Critical (open)

*None — round 8 fixes applied.*

## Critical (fixed — round 8)

### R7-001 — Broken ggplot chain in `create_nmds_plot` (ch06) — **Fixed**
| **File** | `07_Functional_diffrences.Rmd` |
| **Fix** | Moved `env_nmds_labels` before ggplot chain; added `fit_nmds_ordination()` + cached `nmds_fits` to avoid double `metaMDS` per panel |

### HMSC-001 — `model_tasmania` artifact did not match Tasmania setup — **Fixed (unfitted)**
| **Files** | `hmsc/model_tasmania` rebuilt from ch13 Tasmania logic |
| **On-disk (post-fix)** | 55 samples, 901 genomes, MD5 `703d8c94…` (no longer identical to `model_r400`) |
| **Remaining** | ERDA fitted posterior still 939 genomes — ch15 stops with clear error until HPC re-fit |

## Critical (fixed — prior rounds)

| ID | File(s) | Fix applied |
|----|---------|-------------|
| **BUG-001** | `05_Enviroment_types.Rmd` | `load_sample_metadata_hsmc` defines `sample_metadata_tasmania` |
| **BUG-002** | `05_Enviroment_types.Rmd` | `Fcollapse` → `collapse` |
| **BUG-003** | `05_Enviroment_types.Rmd` | `load("data/data.Rdata")` + EHI01340 filter before Tasmania split |
| **BUG-004** | `07_Functional_diffrences.Rmd` | `beta_div` `eval=TRUE`; `load_missing_beta_mats()` stops on missing matrices |
| **BUG-005** | `14_hmsc_analysis_2.Rmd`, `15_hmsc_analysis_tasmania_env+ani.Rmd` | `post_table_14` / `post_table_16` chunks (`eval=TRUE`); intercept via `select(-\`(Intercept)\`)` |
| **BUG-006** | `13_hmsc_setup2.Rmd` (×4), `17_hmsc_setup_final.Rmd`, `rebuild_model_final.R` | Genome-length factors joined by `genome` ID |
| **BUG-032** | `07_Functional_diffrences.Rmd` | Uses local `genome_tree_beta` instead of overwriting `genome_tree` |
| **BUG-007** | `01_prepare_data.Rmd` + `data/data.Rdata` | `EHI01340` filtered in ch01 load |
| **BUG-034** | `05_Enviroment_types.Rmd` | `landcover_wide.csv` exported via `write_csv` |
| **BUG-071** | `05_Enviroment_types.Rmd` | `env_sites` derived from `data/sample_sites.csv` |
| **BUG-073** | `_main.Rmd` | Regenerated from chapter sources |

---

## High (open)

| ID | File | Lines | Issue |
|----|------|-------|-------|
| **R7-002** | `06_alpha_diversity.Rmd` | L79–88 | **Fixed** — `arrange(match(genome, rownames(dist)))` before `hilldiv` |
| **R7-003** | `08_microbiota_abundance_analysis_sex.Rmd` | L569–585 | **Fixed** — `ancom_rand_struct12` uses `physeq_genome_filtered` |
| **R7-004** | `07_Functional_diffrences.Rmd` | L152–176 | `landcover_wide.csv` required; only written in ch05 |
| **R7-005** | `07_Functional_diffrences.Rmd` | L335–566 | **Partial** — ch06 caches single fit per matrix; `plot_helpers.R` still refits when `nmds_obj` NULL |
| **R7-006** | `10_enviromental_permanova.Rmd` | L82–262 | Arbitrary env-Hill ↔ microbiome-β pairing in PERMANOVA/Mantel/NMDS |
| **R7-007** | `09_microbiota_functional_analysis.Rmd` | L385, L460 | **Fixed** — Wilcoxon guards in function + domain chunks |
| **BUG-011** | `08_microbiota_abundance_analysis_sex.Rmd` | L569–585 | **Fixed** (same as R7-003) |
| **BUG-013** | `09_microbiota_functional_analysis.Rmd` | L460 | **Fixed** — all Wilcoxon chunks guarded |
| **BUG-014** | `09_microbiota_functional_analysis.Rmd` | L260–265 | `1e-10` pseudocount; residual risk at exact zeros |
| **BUG-015** | `06_alpha_diversity.Rmd` | L88 | **Fixed** (root cause R7-002) |
| **BUG-016** | `R/plot_helpers.R` | L1550–1577, L5681–5685 | NMDS fitted twice when cache lacks `nmds_obj` |
| **BUG-017** | `R/plot_helpers.R` | L3135–3172 | `phylum_colors` only used when passed + phylum in data; else blue gradient |
| **BUG-018** | export scripts | — | Partially fixed — `load_phylum_colors_fallback()` in E/F/F6 exports |
| **BUG-024** | `R/plot_helpers.R` | L2369–2396 | **Fixed** — taxonomic panel uses `prop = n/sum(n)` per phylum |
| **BUG-027** | `04_community_composition.Rmd` | L179–181, L520–569 | `nmags` from unfiltered `genome_counts`, not analysis set |
| **BUG-038** | `05_Enviroment_types.Rmd` | L719–729 vs L948–954 | **Fixed** — viz uses `hill_long_viz`; saved `hill_long` schema unchanged |
| **BUG-041** | `10_enviromental_permanova.Rmd` | L82–262 | Same as R7-006 — *needs human decision* |
| **BUG-074** | `hmsc_setup.Rmd`, `1z3_hmsc_setup2.Rmd`, `_main.Rmd` | — | Legacy row-index genome-length normalization unfixed |
| **R7-028** | 5+ scripts | — | **Partial** — `build_hill_rdata.R` + load guards; commit `data/hill.Rdata` still recommended |
| **R7-029** | `14_publication_figures.Rmd` | L27–31, L171 | Network deps: GitHub `phylum_colors`, ch05 `landcover_wide.csv` |
| **HMSC-002** | `15_hmsc_analysis_tasmania_env+ani.Rmd` | L21 | **Partial** — unfitted model fixed; fitted posterior still mismatched until HPC |
| **R8-001** | ch15–18 | load_model | **Fixed** — sample-count guards added |
| **R8-002** | ch11 | L16–17 | **Fixed** — `EHI01340` dropped from `genome_counts_filt` |

### High — fixed or refuted (round 7)

| ID | Status | Notes |
|----|--------|-------|
| **BUG-006-01** | Fixed | ch01 `left_join(..., by = "genome")` |
| **BUG-008** | Fixed | ch02 `mags_bases = mags * 150` |
| **BUG-009** | Refuted | EHI01340 absent from current `data.Rdata` |
| **BUG-010** | Refuted | ch06 colour = `broad_environment`, shape = `island` |
| **BUG-019** | Fixed | ch14/15/16/18 all use `Code_element` join |
| **BUG-020** | Fixed | ch16 `select(-\`(Intercept)\`)` |
| **BUG-021** | Mostly fixed | All chapters use `hpc_fit$list` + genome guard |
| **BUG-033** | Fixed | ch06 L89–98 aligns rows to `common_genomes` |
| **BUG-076** | Fixed | ch13 HPC path `model_tasmania` |
| **BUG-077** | Fixed in code | Artifact not rebuilt → **HMSC-001** |
| **NEW-13-01** | Fixed in source | `genome_counts_tasmania` for prevalence |
| **NEW-15-01** | Stale | ch15 loads `model_tasmania`; issue is HMSC-001/002 |
| **BUG-078** | Fixed | `test_priority1_joins.R` builds GIFT matrices when missing |

---

## Medium (open)

| ID | File | Lines | Issue |
|----|------|-------|-------|
| **BUG-025** | `03_mag_catalogue.Rmd` | 16–17 | Metadata filtered; count columns not subset |
| **BUG-026** | `03_mag_catalogue.Rmd` | 137–139 | Mutates global `genome_metadata` |
| **R7-008** | `03_mag_catalogue.Rmd` | 52, 290 | `eval=FALSE` hides `genome_ring` / `function_heatmap`; wrong `y` aesthetic in heatmap |
| **BUG-028** | `04_community_composition.Rmd` | — | **Refuted** — uses `mean(relabun)` |
| **BUG-029** | `04_community_composition.Rmd` | — | **Refuted** — `phylum_colors[-8]` not present |
| **BUG-030** | `04_community_composition.Rmd` | 339–396 | Ambiguous family→phylum join (`slice_max`) |
| **BUG-031** | `06_alpha_diversity.Rmd` | 127–175 | Prose says Wilcoxon; code uses `kruskal.test` for 5 environments |
| **R7-009** | `06_alpha_diversity.Rmd` | 387–430 | Notes promise mixed models; code uses `lm()` only |
| **R7-010** | `06_alpha_diversity.Rmd` | 258–298 | Sex-facet Wilcoxon without empty-group guard |
| **R7-011** | `07_Functional_diffrences.Rmd` | 113–147 | `save_beta` can persist stale matrices after partial failure |
| **R7-012** | ch05 vs ch06 | L12 vs L11 | Inconsistent `treatment_colors` (Cropland differs) |
| **R7-013** | `08_microbiota_abundance_analysis_sex.Rmd` | 531–563 | Notes say eval=FALSE; chunks run on knit |
| **R7-014** | `08_microbiota_abundance_analysis_sex.Rmd` | 43–47 | Taxonomy via `select(1:7)` assumes fixed column order |
| **R7-015** | `08_microbiota_abundance_analysis_sex.Rmd` | 197–209 | UpSet queries omit Temperate shrubland (TS in sets, not queries) |
| **R7-016** | `08_microbiota_abundance_analysis_sex.Rmd` | 167–170 | UpSet: samples missing from metadata → NA group |
| **R7-017** | ch07, ch08, ch11, ch12 | — | Global mutation of `sample_metadata` / `genome_counts_filt` |
| **BUG-035** | `08_microbiota_abundance_analysis_sex.Rmd` | 155–157 | Dead/misleading sex UpSet section title |
| **BUG-036** | `09_microbiota_functional_analysis.Rmd` | 44–51 | Fragile `transpose_and_convert` |
| **BUG-037** | `05_Enviroment_types.Rmd` | 597–632 | Hard-coded climate NA imputation | *needs human decision* |
| **BUG-039** | `05_Enviroment_types.Rmd` | 1023–1048 | Duplicate `visualisations7`/`8` chunks |
| **BUG-040** | `10_enviromental_permanova.Rmd` | 82–85 | `beta_q1p` loaded but never analyzed | *needs human decision* |
| **BUG-043** | ch11 vs ch12 | — | `env_div_group*` vs `env_group_q*` naming |
| **BUG-044** | `12_diversity_abundance_analysis.Rmd` | 33–35, 130–133 | Mutates global `genome_counts_filt` |
| **BUG-045** | `17_hmsc_setup_final.Rmd` | 58–59 vs 73 | Unused `precipitation`, `density` in `XData` |
| **BUG-046** | ch13, ch17 | — | `EHI01340` dropped only via implicit `inner_join` |
| **HMSC-005** | `13_hmsc_setup2.Rmd` | L22–504 | Prevalence from `genome_counts_filt`; Y from unfiltered `read_counts` |
| **HMSC-006** | `16_hmsc_analysis_tasmania_env_only.Rmd` | L99–110 | Varpart plot hardcodes covariates absent from `model_env` (`eval=FALSE`) |
| **BUG-047** | `R/plot_helpers.R` | 1274–1287 | `create_forest_plot` no phylum colour fallback |
| **BUG-048** | `R/plot_helpers.R` | 3–16 | `filter_study_samples` inconsistent return type |
| **BUG-049** | `R/plot_helpers.R` | 1616–1619 | NMDS silent sample loss on `inner_join` |
| **BUG-050** | `R/plot_helpers.R` | 5777–5789 | `save_publication_figure` cwd-relative `figures/` |
| **BUG-051** | `build_and_push.R` | 52–54 | Blind `git add -A` |
| **BUG-052** | `R/plot_helpers.R`, ch19 | L5735–5737 | `interaction_beta_fig` prepared, never plotted |
| **BUG-053** | `cache_publication_data.R` | 49–56 | ERDA download only; no offline fallback |
| **BUG-055** | `R/plot_helpers.R` | 95–97, 2054–2056 | `right_join` CI gaps |
| **BUG-056** | `R/plot_helpers.R` | 2312–2323 | Varpart drops unknown components silently |
| **BUG-066** | `12_diversity_abundance_analysis.Rmd` | 218–225 | Structural-zero both-all-zero → labelled `"High"` |
| **BUG-079** | `14_publication_figures.Rmd` | — | **Stale** — no duplicate CSV read |
| **NEW-001** | `01_prepare_data.Rmd` | 104–106 | Coverage mask uses genome join (fixed); `_mask` suffix pattern OK |
| **NEW-06-01** | `07_Functional_diffrences.Rmd` | 152–176 | Same as R7-004 |
| **NEW-09-02** | `05_Enviroment_types.Rmd` | 1210–1221 | `r200_h1_aus` computed but never saved |
| **NEW-12-01** | `12_diversity_abundance_analysis.Rmd` | 444–448 | Partially mitigated with `tryCatch` |
| **NEW-001 (cache)** | `cache_publication_data.R` | 60–62 | HMSC import without genome-count guard |
| **R7-018** | `11_enviromental_abundance_analyses.Rmd` | 16–17 | `genome_counts_filt` not subset for EHI01340 |
| **R7-019** | `11_enviromental_abundance_analyses.Rmd` | 476 | `rand_formula = "~1"` dubious in ANCOM-BC2 |
| **R7-020** | export scripts | — | F2–F4 export forest-only; checklist says threshold composite |
| **R7-021** | `cache_publication_data.R` | 92 | `elements_response` filters via `Code_bundle` not `Code_element` |

---

## Low (open)

| ID | File | Issue |
|----|------|-------|
| **BUG-054** | `compare_refactored_code.R` | Missing `library(dplyr)` |
| **BUG-057** | `01_prepare_data.Rmd` | Fixed — `any_of()` replaces `one_of()` |
| **BUG-058** | ch04, ch06, ch07 | Deprecated `mutate_at` / `select_if` |
| **BUG-059** | `02_data_statistics.Rmd` | **Stale** — now `Sample_maps.pdf` |
| **BUG-060** | `03_mag_catalogue.Rmd` | `nrow()` vs unique genes |
| **BUG-061** | `08_microbiota_abundance_analysis_sex.Rmd` | Volcano uses natural log, not log10 |
| **BUG-062** | `05_Enviroment_types.Rmd` | Embedded newline in landcover label |
| **BUG-063** | ch15, ch16 | Chunk labels `*_hmsc_16`/`17` off by one from chapter numbers |
| **BUG-064** | `index.Rmd` | URL/repo name mismatch — see DOC-007 |
| **BUG-067** | `R/plot_helpers.R` | `create_association_count_plot` ignores `spotlight_cols` |
| **BUG-068** | `R/plot_helpers.R` | `create_threeway_phylum_congruence_plot` ignores `phylum_colors` |
| **BUG-069** | `R/plot_helpers.R` | G1/G2 dims use pre-intersection tip count |
| **BUG-070** | `R/plot_helpers.R` | F2/F3 height driven by interaction panel count |
| **BUG-082** | `compare_refactored_code.R` | Same as BUG-054 |
| **BUG-083** | ch13, ch17 | `hmsc.r` referenced but not in repo (`eval=FALSE`) |
| **R7-022** | `09_microbiota_functional_analysis.Rmd` | `scale_color_manual` relies on factor level order |
| **R7-023** | `10_enviromental_permanova.Rmd` | NMDS without `set.seed` (heatmap subset seeded) |
| **R7-024** | `test_circular_phylogeny_env_rings.R` | Hardcoded absolute `setwd()` |
| **R7-025** | `render_full_webbook.R` | No project-root guard; arm64 pandoc path |
| **R7-026** | `rebuild_model_final.R` | Loads `model_env`, saves `model_final` — silent mismatch risk |
| **R7-027** | ch03–06 | Redundant EHI01340 re-filtering (harmless) |

---

## Documentation / consistency (open)

| ID | File | Issue |
|----|------|-------|
| DOC-001 | `14_publication_figures.Rmd` | E2 listed Done and out of scope |
| DOC-002 | `HANDOVER_publication_figures.md` vs ch19 | Figure count/set mismatch (E2, G2, F8) |
| DOC-003 | `_main.Rmd` | Fixed (round 4) |
| DOC-004 | `gitignore.R` | Incomplete patterns; wrong filename |
| DOC-005 | `audit_publication_figures.R` | Expects E2 PDF while handover omits it |
| DOC-006 | `hmsc_analysis.Rmd` | Legacy `rename(intercept=2)` pattern |
| DOC-007 | `index.Rmd` | URL points to `calotriton_metagenomics` |
| DOC-008 | `14_publication_figures.Rmd` | E2 contradictory Done vs out-of-scope footnote |
| DOC-009 | `VISUALIZATION_GUIDE.md` vs ch19 | F2–F4 described as threshold composites; code exports forest-only |

---

## Suspicious / needs human decision

| ID | Location | Question |
|----|----------|----------|
| S-01 | `01_prepare_data.Rmd` L107–108 | Unfiltered `genome_counts` branch intentional? |
| S-02 | `01_prepare_data.Rmd` L148–150 | Non-Tasmania → `"Australia"` includes mainland outlier |
| S-03 | `02_data_statistics.Rmd` L308–310 | SingleM `< mags_proportion` → `NA` intentional? |
| S-04 | `05_Enviroment_types.Rmd` L469–471 | Devil density outside domain → 0 |
| S-05 | `05_Enviroment_types.Rmd` | Resolved — `env_sites` from `data/sample_sites.csv` |
| S-06 | `10_enviromental_permanova.Rmd` | Omit `beta_q1p` from PERMANOVA intentionally? |
| S-07 | `18_hmsc_analysis_final.Rmd` | ERDA download required; posterior gitignored |
| S-08 | ch15 vs ch16 | Which Tasmania model is canonical: `model_tasmania`, `model_env`, or `model_final`? |

---

## Runtime verification (round 7)

| Check | Result |
|-------|--------|
| `audit_publication_figures.R` | **PASS** (local tree has `data/hill.Rdata`) |
| `data/hill.Rdata` in git | **Absent** — breaks fresh clone (R7-028) |
| `hmsc/model_tasmania` MD5 | **Identical to `model_r400`** (HMSC-001) |
| `hmsc/model_env` / `model_final` | 576 genomes, 55 samples |
| `hmsc/model_r200` / `model_r400` | 939 genomes, 72 samples |
| ch06 ggplot chain (R7-001) | **Broken** at L398–416 |
| ch06 beta row alignment (BUG-033) | **Fixed** L89–98 |
| ch16 GIFT join (BUG-019) | **Fixed** `Code_element` L288–290 |
| ch07 phyloseq mismatch (BUG-011) | **Open** L571 vs L583 |
| ch05 functional alpha alignment (R7-002) | **Open** L79–88 |
| `test_priority1_joins.R` | **Runs** with GIFT fallback |
| `EHI01340` in `data/data.Rdata` | **Absent** ✓ |

---

## Recommended fix order (round 7)

1. **R7-001** — Fix ch06 `create_nmds_plot()` ggplot syntax (unblocks NMDS)
2. **HMSC-001 / HMSC-002** — Re-run ch13 Tasmania block; verify 55 samples; align ch15
3. **R7-002** — ch05: reorder `genome_counts_filt` to `rownames(dist)` before `hilldiv`
4. **BUG-011 / R7-003** — ch07: use `physeq_genome_filtered` in `ancom_rand_struct12`
5. **BUG-016 / R7-005** — Single NMDS fit per matrix in ch06 + `plot_helpers.R`
6. **BUG-024** — Normalize F5 congruence panels consistently
7. **R7-007** — Add Wilcoxon guards in ch08 function/domain chunks
8. **R7-028** — Commit `data/hill.Rdata` or remove dependency from scripts
9. **HMSC-003 / HMSC-004** — Document/rebuild `model_env`; standardize r200 vs r400 buffer
10. **BUG-027, BUG-030** — ch04 composition denominators and family colours

---

## Files reviewed (inventory)

**Active bookdown:** `index.Rmd`, `01_prepare_data.Rmd`–`14_publication_figures.Rmd`, `_bookdown.yml`  
**Archived HMSC:** see `archive/README.md` (setup2, env-only, analysis chapters, legacy launch scripts)

**Support:** `R/plot_helpers.R`, `build_and_push.R`, `gitignore.R`, `.Rprofile`

**Scripts (22):** `.cursor/scripts/audit_publication_figures.R`, `cache_publication_data.R`, `export_publication_figures_*.R`, `export_fig_F8_thresholds.R`, `test_publication_figures_wave*.R`, `rebuild_model_final.R`, `render_full_webbook.R`, `diag_publication_figures.R`, `compare_refactored_code.R`, `test_priority1_joins.R`, `test_circular_phylogeny_env_rings.R`

**Legacy:** `hmsc_setup.Rmd`, `hmsc_analysis.Rmd`, `1z3_hmsc_setup2.Rmd`, `Microbiome_Study.Rmd`, `NN_MAGS_Catalouge_alternative_version.Rmd`

---

*Re-run after fixes: `Rscript .cursor/scripts/audit_publication_figures.R` and a clean bookdown knit from chapter 01.*
