# Manuscript gaps checklist

**File audited:** `Manuscript/btp_manuscript-2.docx`  
**Cross-checked against:** `data/publication_hmsc.Rdata`, `data/publication_base.Rdata`, `data/hill.Rdata`, `hmsc/model_final`, audit scripts  
**Created:** 2025-06-24  

Use this as a working list. Items are grouped by priority. Check boxes as you go.

---

## P0 — Must fix before submission (substantive / methods)

### Methods §2.8 HMSC does not match fitted model

The manuscript describes a different model than `model_final` in `13_hmsc_setup_final.Rmd`.

| Manuscript (current §2.8) | Actual `model_final` |
|---|---|
| Fixed: devil, temperature, landcover heterogeneity, precipitation, vegetation density, population density | Fixed: `devil + temperature + diversity + logseqdepth + devil:temperature` |
| Sample effects: weight, development, sex | Not in fixed-effects formula |
| Random: site + individual | Random: site + animal ✓ |

**Action:** Rewrite §2.8 to match the fitted formula. Mention `logseqdepth`. Remove predictors not in the model unless you refit.

---

### Discussion paragraph incomplete

- Para ~102 ends with **“This suggests…”** — sentence is unfinished.

**Action:** Complete using interaction⁻ lipid/sugar degradation argument (see § HMSC gaps below) or delete the fragment.

---

## P1 — Results accuracy & key missing HMSC content

### Numeric fixes in §3.2

| Location | Current | Should be |
|---|---|---|
| Island R² | `0.13-015` | `0.13–0.15` (computed 0.128–0.150) |
| Functional β-diversity p | `0.755` | `0.74` (computed p = 0.744) |
| Fig. 3 reference | `Fig. X` | `Fig. 3` |

Land-cover heterogeneity R² (`0.027–0.045`) is **approximately correct** for env Hill h0/h1 on richness/neutral β (computed ~0.038–0.047). Optional minor update to `0.03–0.05` if you want tighter rounding.

---

### Variance partitioning — not reported anywhere

Mean explained variance across 576 genomes (`varpart_fig`):

| Term | Mean % |
|---|---|
| Random: animal | 61.2 |
| Random: site | 20.3 |
| devil | 7.4 |
| devil:temperature | 7.1 |
| logseqdepth | 2.2 |
| temperature | 1.5 |
| diversity | 0.4 |

**Gap:** Interaction explains almost as much as devil; temperature is the weakest fixed effect. Manuscript reads as if temperature is co-equal with devil.

**Action:** Add a short Results paragraph (or one sentence + supplementary table). Consider citing **Fig. F1** (variance partitioning panel) if you include publication figures.

---

### Devil × temperature functional overlap — not quantified

- Devil⁺ FDR elements: **52**
- Temp⁺ FDR elements: **55**
- **Shared devil⁺ & temp⁺: 45** (~87% of devil hits, ~82% of temp hits)

Top shared elements: B0218, B1004, D0502, D0213, D0212, B0703, D0604 (amino acids, antibiotics, polysaccharides, vitamins, nitrogen degradation).

**Action:** Add one sentence in Results linking devil and temperature to the **same metabolic module**, not independent programmes.

---

### Three-way genome structure — largely missing

| Pattern | n |
|---|---|
| Incomplete (≥1 neutral) | 388 |
| Main effects congruent, **interaction discordant** | **188** |
| Triple congruent | 0 |

Taxonomic overlap (already partly in text, strengthen):

- **102 of 119** interaction⁺ genomes are **devil⁻** (86%)
- **96 genomes** are interaction⁻ with **devil⁺ and temp⁺**

**Action:** New Results subsection or paragraph under interaction. Reference **Fig. F7** (three-way congruence) if available.

---

### logseqdepth — not discussed

- **565 of 576** genomes are logseqdepth-positive.

**Action:** One sentence in Methods (as covariate) + Limitations (detection bias vs ecology).

---

### Geographic / confounding context — underused

Tasmania HMSC samples (n = 55):

- devil–temperature **r = −0.19**
- devil–precipitation **+0.35**
- devil–vegetation density **+0.40**

Quadrants (median split):

| Quadrant | n | Mean landscape diversity |
|---|---|---|
| High devil, high temp | 11 | 1.32 (lowest) |
| High devil, low temp | 18 | 2.24 |
| Low devil, high temp | 18 | 2.64 |
| Low devil, low temp | 8 | 2.65 |

**Action:** Expand limitations / interaction interpretation. Devil recovery is partially embedded in wetter, denser, less heterogeneous landscapes.

---

### Interaction functional panel — partial, interpretation thin

**16 FDR-significant interaction β elements:**

**Positive β (12):** D0608, D0601, D0607, D0613 (nitrogen degradation); D0512 (amino acid degradation); B0711 (vitamin); S0104, S0105, S0103 (structure); S0202 (appendages); D0705 (alcohol degradation)

**Negative β (4):** D0102 (lipid degradation); D0302 (sugar degradation); B0703 (vitamin); D0604 (nitrogen degradation)

**Action:** Tie negative-β lipid/sugar elements to the **96 devil⁺/temp⁺/interaction⁻** genomes and compounded-stress discussion.

---

### Cool / low-devil taxa — taxa named, functions not

Devil⁻ and temp⁻ FDR elements (n = 8 and 6, nearly identical):

- S0104, S0105 — cellular structure
- B0704 — vitamin biosynthesis (depleted among devil⁺/temp⁺)
- D0607, D0613, D0601, D0608 — nitrogen degradation (depleted)
- S0201/S0202 — appendages

Temp⁻ taxa (manuscript has names): Cyanobacteriota, Thermoplasmatota, Bacteroidota, Pseudomonadota.

**Action:** One sentence linking cool/low-devil assemblages to **structure-enriched, biosynthetically leaner** profiles vs the Bacillota_A compensation module.

---

## P2 — Structure, typos, placeholders

### Remove editorial debris

- [ ] Delete **“New Version 1.1”** from Introduction (para ~3)
- [ ] Fix abstract: `temperature,their` → space after comma

### Section numbering

| Issue | Fix |
|---|---|
| §3.3 heading | “Metabolic **capacitys**” → e.g. “Genome-resolved HMSC associations and functional context” |
| Devil / Temperature subsections | Unnumbered; add §3.4 parent + §3.4.1 / §3.4.2 |
| §3.4.3, §3.4.4 exist | Add missing §3.4 heading and §3.4.1–3.4.2 |
| Discussion | 4.1 → **4.3** → **4.3** (duplicate) → 4.4 → 4.5 → **4.7** — renumber (missing 4.2, 4.6) |

### Figure placeholders

- [ ] §3.2: `Fig. X` → `Fig. 3`
- [ ] Discussion: `Fig X, Supplementary. Sankey Plot` → correct figure number

### Figure caption consistency

Mixed styles: `Figure 1:`, `Fig3:`, `fig4)`, `Fig. 5.` — standardise to journal format (e.g. `Fig. 1`).

### Typos in Results (non-exhaustive)

| Current | Fix |
|---|---|
| tahn | than |
| positiv / negativ (unhyphenated) | positive / negative |
| where (devil genomes where) | were |
| CVag-508 | CAG-508 |
| Lachnospiraccae | Lachnospiraceae |
| Firmicus | Firmicutes |
| cotnributions, associaotns, phyllum-unfiorm, lineagas, degredatitv | correct spellings |
| biosynthesiss, polysachharide, degredation | correct spellings |
| vairability, higer | variability, higher |
| pyhlum, linages | phylum, lineages |
| genom-by-genome | genome-by-genome |
| southwest australia | southwest Australia |

### Methods minor

- [ ] §2.8: `landcover` → `land-cover` / `landscape diversity` (match Results)
- [ ] Posterior support threshold 0.9 is in pipeline but not stated clearly in §2.8

---

## P3 — Figures in pipeline not referenced in manuscript

From `15_publication_figures.Rmd` / caches — consider citing or moving to supplement:

| Figure | Content | Relevance to gaps |
|---|---|---|
| **F1** | Variance partitioning + association counts + congruence + top devil genomes | P1 varpart gap |
| **F5** | Devil × temp congruence tiles (taxonomic + functional) | Congruence story |
| **F7** | Three-way congruence (188 interaction-discordant) | P1 three-way gap |
| **F8** | Functional climate-stripe panels by predictor | Functional group overview |

---

## Verified correct — no change needed

These manuscript numbers match the pipeline:

- 352.3 Gb, 72 samples, 1,817 MAGs, 13+2 phyla
- Read partitioning %, CheckM stats, EHI01340 exclusion note
- Composition (Bacillota_A 60.7%, families, genera)
- α-diversity, LME, PERMANOVA (environment + island)
- HMSC association counts (130/105/341, etc.)
- Taxa breakdowns (Lach 55, Osc 46, temp Bacillota_A 128/139, etc.)
- Functional FDR counts: 60 devil, 61 temp, 69 diversity, 16 interaction
- Congruence: 207 genomes; 112 ++ / 95 −−
- Diversity-positive: S0301, B0401, S0104
- Cropland/xeric highest MAG richness (Discussion claim)

---

## Suggested draft text (optional starting points)

### Variance partitioning (Results)

> Genome-level variance was dominated by individual animal (mean 61%) and site (20%) random effects. Among fixed predictors, devil density (7.4%) and the devil × temperature interaction (7.1%) explained comparable fractions of variance, whereas mean annual temperature (1.5%) and landscape diversity (0.4%) contributed less.

### Functional overlap (Results)

> Devil-positive and temperature-positive MAGs carried largely overlapping functional profiles: 45 of 52 and 45 of 55 FDR-significant GIFT elements were shared, enriched for amino acid and vitamin biosynthesis alongside polysaccharide, nitrogenous and antibiotic degradation.

### Three-way + interaction (Results)

> Although 207 genomes showed congruent devil and temperature responses, 188 genomes displayed congruent main-effect signs with a discordant interaction coefficient. Interaction-positive genomes were concentrated among devil-negative lineages (102 of 119), whereas 96 devil-positive, temperature-positive genomes carried negative interaction coefficients.

### Interpretation sketch (Discussion)

**Devil⁺/temp⁺ module:** Bacillota_A fermenters with dual biosynthetic + degradative enrichment → microbial nutrient provisioning and PSM/xenobiotic processing under predation and thermal pressure.

**Devil⁻/temp⁻ module:** Taxonomically diverse, structure-enriched, biosynthetically leaner → low-compensation refugia in cooler, low-devil, more heterogeneous landscapes.

**Interaction layer:** Positive interaction β on devil⁻ genomes = non-additive adjustment when both pressures co-vary; negative interaction β on devil⁺/temp⁺ genomes with lipid/sugar degradation = narrowed catabolic flexibility under compound stress (11 high-devil/high-temp samples).

---

## Workflow note

Revision scripts in `.cursor/scripts/revise_manuscript_*.py` target `Manuscript/btp_manuscript.docx`, but the current file is **`btp_manuscript-2.docx`**. Either:

- Point scripts at `-2.docx`, or  
- Rename/copy before running automated revision passes.

---

## Suggested order for tomorrow

1. Fix §2.8 HMSC Methods (P0)  
2. Add variance partitioning + functional overlap + three-way paragraphs (P1)  
3. Complete “This suggests…” Discussion paragraph (P0)  
4. Numeric/placeholder fixes in §3.2 (P1)  
5. Section renumbering + typo pass (P2)  
6. Figure references F1/F5/F7/F8 (P3)  
7. Final read-through: abstract, limitations (confounding, logseqdepth)

---

*Generated from agent audit session. Re-run `Rscript .cursor/scripts/audit_manuscript_comprehensive.R` after edits to re-verify numbers.*
