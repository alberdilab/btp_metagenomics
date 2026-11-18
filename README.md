# btp_metagenomics
Code repository for the brush-tail possum metagenomics project (Ecology Letters Letter target).

The raw analysis code is in the root **Rmd** chapters; the bookdown webbook is meant to live at:

[https://alberdilab.github.io/btp_metagenomics/](https://alberdilab.github.io/btp_metagenomics/)

**Alignment with the manuscript (as of Nov 2026):** core HMSC quantities match the paper — 72 catalogue samples / 1,817 MAGs; HMSC 55 Tasmania × 576 genomes; formula `devil + temperature + devil:temperature + diversity + logseqdepth`; site + animal REs; CoverM ≥30% for presence/diversity; MCMC **4×250** verified in `hmsc/Hmsc_model_final.rds`, thin=1000 / transient 250k from launch/import path (`Paper manuscript/MCMC_PROVENANCE.md`); GIFT contrasts = Welch t-tests + BH. See `index.Rmd` and `Paper manuscript/CODE_PAPER_ALIGNMENT.md`.

**Caveats:** ANCOM-BC chapters remain for exploration but are **not** in the Letter Methods. Paper Figs 1–3 are the submission figures; ch15 also keeps developmental export IDs. `docs/` was re-rendered **2026-11-17** (narrative-fast mode: `BTP_WEBBOOK_FAST=1`, code chunks not re-executed). For a full compute knit set `BTP_WEBBOOK_FAST=0`.

**Submission freeze:** Pages freeze is on `New_Main` (`9e02b94`). Leave exploratory `15_` / figure edits out of Pages commits. Remaining author placeholders: ethics/permits, Zenodo DOI, INSDC (full cohort). GTDB **R214** is in the Word Methods; `index.Rmd` notes R214 locally (re-render/push only if you want Pages to match that one line).

Chapters are numbered **01–16** in `_bookdown.yml` (environment = ch05, alpha = ch06, beta = ch07, HMSC analysis = ch14, publication figures = ch15, HMSC group predictions = ch16). Heavy chunks use `eval=FALSE`. To re-render:

```r
library(bookdown)
library(htmlwidgets)
library(webshot)

render_book(input = ".", output_format = "bookdown::gitbook", output_dir = "docs")
```

