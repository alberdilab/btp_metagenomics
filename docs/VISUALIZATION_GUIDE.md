# BTP Metagenomics — Visualization Guide

Publication figures for the BTP webbook are built in `15_publication_figures.Rmd` and exported to `figures/` via helpers in `R/plot_helpers.R`. This guide defines the visual language, reference papers, figure catalogue, and implementation rules.

**Related docs:** `HANDOVER_publication_figures.md` (agent handover), `.cursor/rules/r-coding-rules.md` (project-wide colour rules).

---

## Quick reference

| Item | Value |
|------|-------|
| Theme | `theme_publication()` |
| Export | `save_publication_figure(plot, "fig_XX.pdf", height_mm = …)` |
| Default size | 180 mm wide, 300 dpi, PDF → `figures/` |
| Environment colours | `environment_plot_settings()$colors` (MF/TW/XS/TS/C) |
| Phylum colours | EHI `phylum_colors` — never hardcode |
| GIFT colours | `data/gift_colors.tsv` |
| HMSC spotlight | `spotlight_palettes()` — devil / temperature / interaction |
| Congruence | green `#1B7837` / red `#D73027` |
| Landcover groups | `landcover_group_colors()` |
| Sample filter | Always exclude `EHI01340` |
| Multi-panel layout | `patchwork` + `plot_annotation(tag_levels = "A")` for hero figures |
| Visual benchmarks | `figures/xmaples from other paper/` — Aizpurua 2025 screenshots |
| Theme argument | Pass `theme_fn = theme_publication` (function, not pre-called object) |

---

## Narrative arc

Figures should tell this story in **manuscript order** (Aizpurua cat-paper logic):

```
Study context (Tasmania maps + landcover base)
  → Core diversity (alpha Hill + beta NMDS only)
  → Community phylogeny (circular MAG tree + phylum ring)
  → Composition (stacked phyla + dominant MAG tile)
  → Devil / temperature / interaction spotlight (HMSC + GIFT)
```

**Manuscript priority:** Block **F** carries the main message (devil density and devil × temperature interaction). Blocks A–G provide context; alpha/beta are supporting panels (cat Fig 1d/e), not the primary conclusion.

**Out of scope for chapter 15:** PERMANOVA/Mantel/envfit grids (C2–C5), alpha–env Hill scatters (B3), env-Hill/ANCOM deep dives (D1–D5), taxonomy jitter (E2), optional map supplements (A4–A5). Those remain in source chapters only.

---

## Reference papers

All PDFs live in `Papers as examples for visualisation basis /`.

| PDF | Paper | Role | Borrow | Do not copy |
|-----|-------|------|--------|-------------|
| `2025.aizpurua.mec.pdf` | Aizpurua et al. 2025, *Molecular Ecology* (cat feralisation) | **Primary style anchor** | Multi-panel composites, Hill q panels, minimal theme, functional/HMSC emphasis, stacked composition bars | Exact Fig 1 layout or colour choices unrelated to BTP |
| `DNA_metabarcoding_and_spatial_modelling_link_diet_.pdf` | Alberdi et al. 2020, *Nature Communications* (bats) | Landscape + Hill integration | Maps as study opener, regression scatters with stats on panels, Hill components kept in separate panels, multi-trait grids | Radial phylogeny at full MAG scale (576 genomes) |
| `Hologenomic_data_generation_and_analysis_in_wild_v.pdf` | Pietroni et al. 2025, *Methods in Ecology and Evolution* (EHI) | Methods credibility | QC stacked bars, sample-type comparisons, strict EHI taxonomy colour discipline | Full EHI taxonomic-class QC dashboard as a main figure |
| `Quantitative_Synthesis_of_Microbe-Driven_Acclimati.pdf` | Martin-Bideguren et al. 2024, *Evolutionary Applications* | Overview dashboards | Study-at-a-glance panel (map + taxa counts + timeline), stacked contribution bars | Review scoring heatmaps, PRISMA-style evidence tables |

**Rule:** Each paper informs *design choices*, not figure-for-figure copying. When in doubt, prefer the cat paper layout for multi-panel microbiome figures and the bat paper for map + Hill regression integration.

### Visual benchmarks (cat paper screenshots)

High-resolution panel references are stored in `figures/xmaples from other paper/` (three screenshots from Aizpurua et al. 2025). Use these as the **quality bar** when reviewing exports — not as assets to paste into the manuscript.

| Screenshot | Cat figure | What it shows | BTP target |
|------------|------------|---------------|------------|
| `…13.50.03.png` | **Fig 1** | Map with location pins → faceted stacked phylum bars → 4 alpha Hill boxplots → NMDS spider + centroids | A1, A3, B1, C1, G1 (context block) |
| `…13.50.15.png` | **Fig 2** | Domestic vs feral: alpha boxplots, NMDS spider, horizontal phylo + annotation tracks + aligned GIFT heatmap | B1, C1, F6 (integrated phylo + function) |
| `…13.50.50.png` | **Fig 3c–d** | **Functional-trait forest plots**: regression coefficient on *x*, individual traits on *y*, GIFT-coloured points + CIs, directional arrows, congruence label colours | **F2, F3, F4** (primary functional panel style) |

---

## Cat-paper design system (Aizpurua 2025)

These are the concrete choices that make the cat figures readable. Our helpers should converge on this — not on generic ggplot defaults.

### Global aesthetics

| Principle | Cat paper | BTP implementation |
|-----------|-----------|-------------------|
| Background | White panels, no chartjunk | `theme_publication()` — `theme_minimal`, light major grid only |
| Typography | Small sans-serif, bold panel tags (a–e) | `patchwork::plot_annotation(tag_levels = "A")`; avoid Unicode symbols in PDF labels (use `beta`, `>=`, `->`) |
| Colour discipline | One palette per categorical variable, reused across linked panels | `environment_plot_settings()`, `phylum_colors`, `gift_colors`, `spotlight_palettes()` — never ad hoc |
| Data–ink ratio | Grey for background / non-focus; saturated colour only for the message | HMSC scatter: grey all genomes, colour significant only; NMDS: grey spider segments |
| Panel linking | Same sample order, same colours, aligned tracks | Landcover/composition bars ordered by `broad_environment`; F6 rows = `tree$tip.label` order |
| Legends | Bottom or right; multi-row GIFT legend grouped Biosynthesis / Degradation / Structure | `gift_colors.tsv` codes B/D/S; use `ncol` and grouped breaks in functional legends |
| Height | Tall enough for trait/genome labels — never cram | `spotlight_figure_height_mm()`, `phylo_gift_figure_dims()`, `functional_significance_figure_height_mm()` |

### Figure-type recipes from the cat paper

#### Fig 1 — Study context (maps → composition → diversity)

1. **Map (Fig 1a):** Simple basemap; sample locations as coloured pins; thin lines from pins to a horizontal label strip that defines the colour key for later panels.  
   **BTP:** `create_tasmania_environment_map()`, `create_tasmania_devil_density_map()` — keep basemap muted, points saturated.

2. **Circular catalogue tree (Fig 1b):** Fan/circular layout; concentric rings for phylum, prevalence by group, origin. Separate legend blocks for Taxonomy / Location / Origin.  
   **BTP:** `create_circular_community_phylogeny_plot()` (G1) — phylum ring only for publication; avoid overcrowding 576 tips with >2 rings.

3. **Stacked composition (Fig 1c):** Faceted columns per group; each column = samples as thin stacked bars; y = relative abundance 0–1; phylum colours match tree.  
   **BTP:** `create_phylum_stacked_bar()` (E1) — samples ordered within environment; re-scale after dropping water.

4. **Alpha diversity (Fig 1d):** Four separate panels (Richness, Neutral, Phylogenetic, Functional); boxplots coloured by group + jittered points; shared y-axis label “Diversity”.  
   **BTP:** `create_alpha_environment_plot()` (B1) — Wilcoxon *p* on panels (bat-paper convention).

5. **Beta diversity (Fig 1e):** NMDS/PCoA with **spider plot**: grey segments from each point to its group centroid; hollow centroid marker; points coloured by group.  
   **BTP:** `create_nmds_plot(..., show_centroids = TRUE)` (C1) — shared limits via `calculate_nmds_limits()`.

#### Fig 2 — Group comparison + phylo–function integration

1. **Alpha / beta (Fig 2a–b):** Same as Fig 1d–e but for a binary contrast (domestic vs feral); two-colour palette carried through both panels.  
   **BTP analogue:** environment or devil-density contrasts — use `spotlight_palettes()$congruent` / `$discordant` for binary splits.

2. **Phylo + tracks + heatmap (Fig 2c–d):** Horizontal tree on top; aligned annotation strips (taxonomy, origin, behaviour); GIFT element heatmap below with rows grouped into Biosynthesis / Degradation / Structure; blue sequential fill for abundance.  
   **BTP:** `create_phylo_gift_heatmap_plot()` (F6) — linear tree + phylum strip + HMSC trend strip + GIFT heatmap; this is the cat Fig 2c–d pattern.

#### Fig 3 — HMSC functional results (the spotlight quality bar)

**Panels c–d are the target for F2–F4 functional panels.** Key features:

| Element | Specification |
|---------|---------------|
| Plot type | **Forest plot** (coefficient ± interval), not volcano and not diverging abundance bars |
| X-axis | `Regression coefficient` (or HMSC beta); **solid vertical line at 0** |
| Y-axis | Individual **GIFT functional traits** (element names), ordered by coefficient |
| Points & error bars | Colour = GIFT function category (`gift_colors`); horizontal CI bars, no cap width |
| Direction headers | Annotated arrows above plot: e.g. `<- Negative association` … `Positive association ->` aligned to negative/positive x |
| Significance | Show **only traits passing thresholds**; traits with CI excluding 0 (or FDR + effect-size rules) |
| Congruence coding | Y-axis label colour: **green** = congruent pattern, **red** = discordant (when comparing two factors) |
| Legends | **Top:** phylum/taxonomy strip legend (when relevant). **Bottom:** multi-row GIFT function legend (B/D/S groups) |
| Multi-panel | Side-by-side panels share x-axis limits when comparing predictors (cat: origin vs behaviour) |

**Important statistical note:** The cat paper plots trait-level **regression coefficients**. We use an equivalent readable framing: **mean abundance difference between HMSC-positive and HMSC-negative genomes, with 95% CI** — same forest grammar (point + interval + zero line), adapted to our cached HMSC outputs. Do not copy their exact statistic; match their **clarity**.

| Approach | Where used | Cat-quality readability? |
|----------|------------|--------------------------|
| Trait forest (mean diff + 95% CI, GIFT colours) | `create_functional_trait_forest_plot()` in F2–F4 | **Yes** — manuscript functional panel |
| Genome HMSC beta aggregated to GIFT function group | `aggregate_by_function()` + `create_forest_plot()` in ch 18 | Partial — coarser y-axis |
| Diverging bars / volcano (same underlying test) | `create_functional_significance_plot()`, `create_volcano_plot()` | Exploratory / webbook only |
| Climate-stripe comparison (3 predictors side by side) | `create_functional_climate_comparison_plot()` in F8 | **Yes** — Hawkins-style blue/red intensity |
| Genome beta vs posterior support scatter | `create_beta_support_scatter()` | Supplementary panel A in F2–F4 |

**F2–F4:** single-panel `create_functional_trait_forest_plot()` — no genome scatter or volcano. Genome support summary stays in **F1**.

`create_spotlight_threshold_figure(include_genome_panel = TRUE)` retains the two-panel layout for optional/supplementary use.

### Cat-quality checklist (run before locking a figure)

- [ ] Panel tags (A, B, C…) visible and consistent
- [ ] No clipped axis titles or subtitles (check PDF at 100% zoom)
- [ ] Categorical colours match across panels that share a variable
- [ ] Functional plots: reader can tell **positive vs negative association from x-axis and zero line**
- [ ] GIFT legend present and grouped; point colour matches legend
- [ ] NMDS uses spider segments + centroids when showing group separation
- [ ] Sufficient export height for all y-axis labels (no overlapping trait names)
- [ ] ASCII-safe labels in PDF exports

---

## Design system

### Theme

`theme_publication()` in `R/plot_helpers.R`:

- `theme_minimal` base, light major grid, no minor grid
- Bold strip text, axis titles, and plot titles
- Legend at bottom by default
- Grey subtitle text for statistics (`rho`, `p`, Wilcoxon labels)

### Export

```r
save_publication_figure(
  plot = fig_XX,
  filename = "fig_XX_name.pdf",
  width_mm = 180,   # default
  height_mm = 140,  # adjust per figure
  dpi = 300         # default
)
```

Dynamic heights: phylo + heatmap figures use `phylo_gift_figure_dims()`; ANCOM barplots scale with `max(120, 40 * n_panels)`.

### Colour palettes

**Broad environment** (`environment_plot_settings()`):

| Code | Environment | Colour |
|------|-------------|--------|
| MF | Mixed forest | `#f56042` |
| TW | Temperate woodland | `#429ef5` |
| XS | Xeric shrubland | `#42f58d` |
| TS | Temperate shrubland | `#b142f5` |
| C | Cropland | `#FFA500` |

**HMSC spotlight** (`spotlight_palettes()`):

| Role | Colour |
|------|--------|
| Devil | `#B2182B` |
| Temperature | `#2166AC` |
| Interaction | `#762A83` |
| Diversity (covariate) | `#35978F` |
| Congruent | `#1B7837` |
| Discordant | `#D73027` |
| Neutral / non-significant | `grey75` |

**Phylum** — load from EHI Taxonomy Colour Profile (`ehi_phylum_colors.tsv`). See `.cursor/rules/r-coding-rules.md`.

**GIFT function** — `data/gift_colors.tsv` for volcanos and functional panels.

**Landcover groups** — `landcover_group_colors()` (chapter 5 grouping). Water is excluded from stacked bars; remaining groups are re-scaled to 100% per sample.

---

## Figure-type recipes

| Analysis question | Plot type | Helper / chapter | Paper inspiration |
|-----------------|-----------|------------------|-------------------|
| Where were samples collected? | Tasmania `geom_sf` map | Ch 2 (`02_data_statistics.Rmd`) | Alberdi maps |
| Landcover composition per sample | Stacked bars, ordered by env | `create_landcover_stacked_bar()` | Aizpurua / ch 5 |
| Alpha Hill by environment | 4-panel box + jitter + Wilcoxon | `create_alpha_environment_plot()` | Aizpurua Fig 1d |
| Beta turnover by environment | 4-panel NMDS, shared limits | `create_nmds_plot()` | Aizpurua Fig 1e |
| Environmental Hill distributions | Violin/box by q | `create_env_hill_distribution_plot()` | Alberdi Hill panels |
| Landcover % ↔ env Hill | Scatter + Spearman subtitle | `create_landcover_hill_scatter()` | Alberdi regressions |
| Fine vs broad landcover diversity | Side-by-side scatters | `create_fine_broad_hill_scatter()` | Ch 9 |
| Env diversity ↔ microbiome | ANCOM-BC volcano + barplots | `create_ancombc_volcano_plot()` | — |
| Phylum composition | Stacked bar + jitter + MAG tile | E1–E3 helpers | Aizpurua Fig 1c |
| HMSC genome associations | β vs support scatter | `create_beta_support_scatter()` | Ch 18 — supplementary to trait forest |
| HMSC top genomes | Forest + CI | `create_forest_plot()` | Ch 18 |
| HMSC functional groups | Function-group forest (3-letter GIFT) | `aggregate_by_function()` + `create_forest_plot()` | Ch 18 — coarser than cat Fig 3 |
| **HMSC functional traits (manuscript)** | **Trait-level forest** (mean diff + 95% CI) | `create_functional_trait_forest_plot()` | Aizpurua Fig 3c–d (adapted) |
| HMSC functional shifts (exploratory) | Volcano or diverging bars | `create_volcano_plot()`, `create_functional_significance_plot()` | Webbook / F8 grid only |
| HMSC spotlight composite | Genome support + trait forest (vertical) | `create_spotlight_threshold_figure()` | F2–F4 |
| Devil × temp agreement | Congruence tiles | `create_congruence_tile_plot()` | — |
| Circular community phylogeny | Fan layout + phylum ring | `create_circular_community_phylogeny_plot()` | Ch 3 / Aizpurua MAG context |
| HMSC significant MAG integration | Linear phylo + phylum strip + trend + GIFT heatmap | `create_phylo_gift_heatmap_plot()` | Ch 3 / Aizpurua |
| HMSC overview | Varpart + counts + congruence + forest | F1 composite | — |
| Study overview (optional) | Map + counts + timeline dashboard | Planned A1 + synthesis style | Martin-Bideguren |
| Data QC (supplement) | Stacked read/class bars | Ch 2 patterns | Pietroni |

---

## Layout rules

1. **Multi-panel heroes:** use `patchwork` with `plot_annotation(tag_levels = "A")` (F1). Supporting 4-panels (B1, C1) use `guides = "collect"` for a single shared legend.
2. **Shared axes:** NMDS panels share `calculate_nmds_limits()` across all four beta metrics (C1). Functional trait forests comparing predictors should share x-axis limits (cat Fig 3c–d).
3. **Sample order:** landcover and composition bars ordered by `broad_environment` then `sample` (A3, E1).
4. **Legends:** collect once per composite when panels share the same aesthetic; use `guides = "keep"` when legends differ (e.g. genome scatter vs GIFT forest in F2–F4). GIFT legends: bottom, multi-row, grouped B/D/S.
5. **Statistics on plots:** Spearman `rho`/`p` in scatter subtitles (D2); Wilcoxon labels on boxplots (B1) — follow bat-paper convention of showing test results on the panel.
6. **Uncertainty:** show CIs on forest plots (cat Fig 3); consider ±SE on Hill summaries for future D1/D3 refinements.
7. **NMDS spider plots:** grey `geom_segment` from each point to group centroid; hollow filled centroid marker (`show_centroids = TRUE`) — cat Fig 1e / 2b pattern (C1).
8. **HMSC scatter:** grey background points for all genomes; colour only significant genomes (F2–F4 panel A). Keep as **supporting** panel — not the main functional message.
9. **HMSC functional (manuscript):** prefer **forest plots** over volcano/diverging bars for F2–F4 panel B. Direction from x-axis position and zero line — no green/red background shading.
10. **Export height:** scale with number of traits/genomes (`spotlight_figure_height_mm()`, `functional_significance_figure_height_mm()`); default 120 mm is too short for ≥10 labelled traits.
11. **Post-processing:** reference papers sometimes finalise in Illustrator. Optional for manuscript; not required for webbook exports.

---

## Data integrity rules

Non-negotiable checks — several of these caused real bugs during implementation:

| Rule | Why |
|------|-----|
| `source("R/plot_helpers.R")` before `filter_study_samples()` | Helpers must load first |
| Exclude sample `EHI01340` everywhere | Study design decision |
| Beta matrix sample IDs from `attr(dist, "Labels")`, not `rownames()` | Beta objects store labels as attribute |
| Inside `pmap`, use `.data$q == q_level` not `q == q` | Bare `q == q` is always TRUE (D2 bug) |
| ANCOMBC2 table in `res$res` directly | Not `res$res$diff_abn` |
| F6 matrix rows must match `tree$tip.label` order | Use `order_matrix_by_tips()` |
| F6 ultrametric tree via `phytools::force.ultrametric` | Not `ape::force.ultrametric` |
| F6 heatmap via `ggtree::gheatmap` | Not `ggtreeExtra` |
| Landcover stacks: drop water, re-scale to 100% | Comparable bar heights |
| HMSC fitted `.rds` downloaded at knit; not in git | >100 MB, gitignored |

---

## Figure catalogue

**Locked manuscript set (20 PDFs):** A1–A3, B1, C1, G1, G1b, G2, E1–E3, F1–F8. Live checklist in `15_publication_figures.Rmd`.

### Manuscript figures (`figures/`)

| ID | Description | Output file | Aizpurua analogue |
|----|-------------|-------------|-------------------|
| **A1** | Tasmania sample map | `fig_A1_tasmania_environment_map.pdf` | Study map |
| **A2** | Devil density map (200 m) | `fig_A2_tasmania_devil_density_map.pdf` | — |
| **A3** | Stacked landcover per sample | `fig_A3_landcover_stacked.pdf` | Land context |
| **B1** | 4-panel alpha Hill by environment | `fig_B1_alpha_diversity.pdf` | Fig 1d |
| **C1** | 4-panel NMDS (q0/q1n/q1p/q1f) | `fig_C1_beta_nmds.pdf` | Fig 1e |
| **G1** | Circular community phylogeny + phylum ring | `fig_G1_circular_phylogeny.pdf` | MAG/community tree |
| **E1** | Phylum stacked barplot | `fig_E1_phylum_stacked.pdf` | Fig 1c (stacked) |
| **E3** | Dominant MAG tile plot | `fig_E3_dominant_mag_tile.pdf` | Fig 1c (tile) |
| **F1** | HMSC hero (varpart + counts + congruence + forest) | `fig_F1_hmsc_hero.pdf` | Functional spotlight |
| **F2** | Devil functional trait forest | `fig_F2_devil_spotlight.pdf` | Cat Fig 3c (adapted) |
| **F3** | Temperature functional trait forest | `fig_F3_temperature_spotlight.pdf` | Cat Fig 3c |
| **F4** | Interaction functional trait forest | `fig_F4_interaction_spotlight.pdf` | **Key finding** |
| **F5** | Devil × temperature congruence tiles | `fig_F5_devil_temp_congruence.pdf` | Congruence label colours (cat Fig 3) |
| **F6** | Phylogeny + GIFT heatmap (HMSC sig MAGs) | `fig_F6_phylo_gift_heatmap.pdf` | **Cat Fig 2c–d** |
| **F7** | Three-way congruence | `fig_F7_threeway_congruence.pdf` | Interaction synthesis |
| **F8** | Functional climate-stripe comparison (devil / temp / interaction) | `fig_F8_hmsc_thresholds.pdf` | Cat Fig 3c–d (side-by-side, stripe intensity) |

### Webbook-only (not exported from chapter 15)

| ID | Description | Source chapter |
|----|-------------|----------------|
| **B2–B4** | Alpha supplements | 5, 12 |
| **C2–C5** | NMDS ellipses, envfit, PERMANOVA, Mantel | 6, 10 |
| **D1–D5** | Env Hill, landcover regressions, ANCOM | 9, 11, 12 |
| **E2** | Phylum/genus jitter | 4 |
| **A4–A5** | Landcover tile / cultivated vs native | 9 |

### Optional / methods supplement only

- Data QC stacked bars (Pietroni / ch 2) — credibility for methods, not main narrative
- Study-overview hero dashboard (Martin-Bideguren) — map + sample counts + timeline

### Explicitly out of scope

- Synthesis-paper evidence scoring heatmaps
- Full 576-genome radial tree with quality/size rings (ch 3 catalogue figure; G1 is study-filtered, publication-simplified)
- Generic MetaDAVis / microeco tool documentation

---

## Implementation workflow

For each new figure:

1. Add or reuse a helper in `R/plot_helpers.R` (keep chunks in `15_publication_figures.Rmd` thin).
2. Prepare data in a setup chunk or reuse objects from chapter setup (`sample_metadata_fig`, `hill_long_fig`, etc.).
3. Build ggplot with `theme_fn = theme_publication`.
4. Combine panels with `patchwork` if multi-panel.
5. Display in knit output.
6. Export via `save_publication_figure()`.
7. Add a wave test script under `.cursor/scripts/` and run audit.

### Publication figure caches

Chapter 14 loads precomputed results instead of re-running HMSC or alpha/beta calculations:

| File | Built by | Contents |
|------|----------|----------|
| `data/publication_base.Rdata` | Chapters 5 + 7 | `sample_metadata_fig`, `genome_counts_fig`, `alpha_div_fig`, `beta_mats_fig`, `nmds_limits_fig` |
| `data/publication_hmsc.Rdata` | `cache_publication_data.R` (`model_final`) | All F-block tables (`post_table`, `varpart_fig`, CI/β/congruence summaries, etc.) |

Rebuild without knitting: `.cursor/scripts/cache_publication_data.R`

### Manuscript export checklist

Knit `15_publication_figures.Rmd` → verify PDFs with `.cursor/scripts/audit_publication_figures.R`.

---

## Helpers in `R/plot_helpers.R`

**Core:** `filter_study_samples()`, `theme_publication()`, `spotlight_palettes()`, `environment_plot_settings()`, `save_publication_figure()`

**Landscape:** `landcover_group_colors()`, `prepare_landcover_plot_df()`, `create_landcover_stacked_bar()`

**Alpha / beta:** `calculate_alpha_diversity()`, `create_alpha_environment_plot()`, `calculate_nmds_limits()`, `create_nmds_plot()`

**Env / landcover diversity:** `create_env_hill_distribution_plot()`, `create_landcover_hill_scatter()`, `create_fine_broad_hill_scatter()`, ANCOM-BC helpers

**Composition / phylogeny:** `study_genome_ids()`, `create_circular_community_phylogeny_plot()`, `prepare_phylum_stacked_data()`, `create_dominant_mag_tile_plot()`

**HMSC:** `create_beta_support_scatter()`, `create_forest_plot()`, `create_volcano_plot()`, `create_functional_trait_forest_plot()`, `create_varpart_summary_plot()`, `create_association_count_plot()`, `create_congruence_tile_plot()`, `create_phylo_gift_heatmap_plot()`, `aggregate_by_function()`, `create_functional_significance_plot()`, `create_spotlight_threshold_figure()`, `spotlight_figure_height_mm()`, etc.

**Maps:** still inline in `02_data_statistics.Rmd` — copy patterns for A1/A2.

---

## Verification scripts

```
.cursor/scripts/test_publication_figures_wave1.R   # A3, B1, C1
.cursor/scripts/test_publication_figures_wave2.R   # F1–F5
.cursor/scripts/test_publication_figures_wave3.R   # D1–D3
.cursor/scripts/test_publication_figures_wave4.R   # E1–E3, D4
.cursor/scripts/test_publication_figures_wave5_F6.R # F6
.cursor/scripts/test_publication_figures_wave6.R   # A1–A2, F7 logic
.cursor/scripts/audit_publication_figures.R
.cursor/scripts/diag_publication_figures.R
```

Run audit after adding or changing any publication figure helper.

---

## HMSC spotlight (`model_final`)

- **Formula:** `~ devil + temperature + diversity + logseqdepth + devil:temperature`
- **Random:** `animal`, `site`
- **Samples:** Tasmania only (55); genomes: 576
- **Support:** ≥ 0.9 positive, ≤ 0.1 negative
- **Fitted posterior:** downloaded from ERDA at knit time (not in git)
- **F6:** up to 120 spotlight-significant genomes; phylum annotation strip + HMSC trend strip + GIFT element heatmap (cat Fig 2c–d pattern)
- **F2–F4 functional panel:** `create_functional_trait_forest_plot()` via `create_spotlight_threshold_figure()` — cat-inspired forest (mean diff + 95% CI), not a literal copy

### `create_functional_trait_forest_plot()` (F2–F4 panel B)

Readable functional panel adapted from the cat paper (Fig 3c–d) using our HMSC + GIFT data:

- **X:** mean abundance difference between positive vs negative associated genomes, with **95% Welch CI** error bars
- **Y:** GIFT element labels (`B0221 - Amino acid biosynthesis`)
- **Fill:** GIFT function category (`gift_colors`)
- **Filtering:** |diff| >= 0.2 and FDR < 0.05 (same thresholds as before)
- **Direction:** position relative to zero + shaded regions + header labels (not a second redundant legend)
- **Composite:** vertical stack with genome support scatter on top (optional via `create_spotlight_threshold_figure(include_genome_panel = TRUE)`)

**F8** uses `create_functional_climate_comparison_plot()`: three panels (devil, temperature, interaction) for the union of significant GIFT traits. Bar fill follows a blue-white-red climate-stripe palette (deeper colour = stronger association; grey = not significant for that predictor). Shared x limits across panels.

`create_functional_significance_plot()` remains for webbook exploration.

---

*Guide created June 2026. Visual benchmarks added from `figures/xmaples from other paper/` (Aizpurua 2025 screenshots). Update the figure catalogue when new figures are exported.*
