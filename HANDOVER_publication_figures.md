# Handover: Publication Figures Chapter (`15_publication_figures.Rmd`)

**Copy everything below into a new Agent-mode chat to continue building manuscript figures.**

**Full style guide:** see [`VISUALIZATION_GUIDE.md`](VISUALIZATION_GUIDE.md) for design system, reference papers, figure recipes, and integrity rules.

---

## Project goal

Build **manuscript-quality figures only** for the BTP metagenomics paper, styled after Aizpurua et al. 2025 (cat metagenomics) as the primary anchor. Chapter 15 exports a **locked set of PDFs** — not every webbook visualisation.

**Spotlight findings:** devil density + devil × temperature interaction (`model_final`).

**Manuscript order:** A (maps + landcover) → B (alpha) → C (beta) → G (circular phylogeny) → E (composition) → F (HMSC).

**Deliverable:** ggplot chunks in `15_publication_figures.Rmd` that knit cleanly and export PDFs to `figures/` via `save_publication_figure()`.

---

## Repo & branch

- **Path:** `/Users/lukasfix/Desktop/Backup for code/btp_metagenomics`
- **Branch:** `New_Main`
- **Bookdown order:** `01`–`15` in `_bookdown.yml` (index + 15 numbered chapters)
- **Knit order:** ch05 (environment) → ch06–09 (microbiome) → ch10–14 (env links + HMSC) → ch15 (figures)

---

## Current state

### Manuscript set (20 PDFs + G1b PNG)

| Block | Figures |
|-------|---------|
| A | A1, A2, A3 |
| B | B1 |
| C | C1 |
| G | G1, G1b (PDF+PNG), G1b+HMSC, G2 |
| E | E1, E2, E3 |
| F | F1, F2, F3, F4, F5, F6, F6b, F7, F8 |

**Removed from chapter 15** (webbook-only): B2–B4, C2–C5, D1–D5, A4–A5.

### Verification

Knit chapter 15 after chapters **1, 5, 7, 13, 14** (or run `rebuild_from_scratch.R`).

| Cache file | Built by | Used by ch15 for |
|------------|----------|------------------|
| `data/publication_base.Rdata` | Ch 7 | A–C, G, E blocks |
| `data/publication_hmsc.Rdata` | Ch 14 | F block + G1b HMSC ring |

---

## Key files

| File | Role |
|------|------|
| `VISUALIZATION_GUIDE.md` | **Canonical** style + catalogue + rules |
| `15_publication_figures.Rmd` | Figure chunks + knit setup |
| `13_hmsc_setup_final.Rmd` | Canonical `model_final` setup |
| `14_hmsc_analysis_final.Rmd` | HMSC analysis + `publication_hmsc.Rdata` |
| `07_Functional_diffrences.Rmd` | Saves `publication_base.Rdata` |
| `R/plot_helpers.R` | `load_publication_figure_caches()`, plot builders |
| `R/chapter_deps.R` | `ensure_gift_db()`, `ensure_hill_rdata()` |

---

## HMSC model (`model_final` spotlight)

- **Formula:** `~ devil + temperature + diversity + logseqdepth + devil:temperature`
- **Random:** `animal`, `site`
- **Samples:** Tasmania only (55); **Genomes:** 576
- **Fitted posterior:** ERDA download at knit — `hmsc/Hmsc_model_final.rds` is gitignored
- **Support threshold:** 0.9 (positive), ≤0.1 (negative)

---

## Objects ready after setup chunks knit

```r
sample_metadata_fig, genome_counts_fig, genome_metadata, genome_tree, genome_gifts, GIFT_db
landcover_wide, sample_points_map, hill_long_fig, hill_wide_fig
m, fit_model_fig, post_table, elements_response, hmsc_tree
spotlight_cols, fig_defaults, env_settings, gift_colors, phylum_colors
```

**Sample filter:** always exclude `EHI01340`.

---

## Constraints for the agent

- **Do not commit** unless explicitly asked
- **Minimise scope** — focused figure chunks only
- Reuse `R/plot_helpers.R`; see `VISUALIZATION_GUIDE.md` for colour and layout rules
- Keep sample exclusion `EHI01340` consistent
- Run `.cursor/scripts/audit_publication_figures.R` after changes

---

*Handover updated June 2026.*
