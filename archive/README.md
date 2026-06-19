# Archived HMSC chapters and scripts

Legacy HMSC material removed from the active bookdown build. The **canonical** workflow is:

1. **`13_hmsc_setup_final.Rmd`** — build unfitted `hmsc/model_final` (Tasmania, 576 genomes, devil × temperature)
2. **`14_hmsc_analysis_final.Rmd`** — import ERDA posterior, run analyses, write `data/publication_hmsc.Rdata`
3. **`15_publication_figures.Rmd`** — export figures from `data/publication_*.Rdata` caches

To rebuild HMSC caches without knitting the analysis chapter:

```bash
Rscript .cursor/scripts/cache_publication_data.R
```

## Archived analysis chapters

| File | Former ch. | Model | Why archived |
|------|------------|-------|--------------|
| `14_hmsc_analysis_2.Rmd` | 14 | `model_r200` (72 samples, 939 genomes) | Unfitted ≠ ERDA posterior (583 genomes) |
| `15_hmsc_analysis_tasmania_env+ani.Rmd` | 15 | `model_tasmania` | ERDA posterior missing; wrong scope |
| `14_hmsc_analysis_tasmania_env_only.Rmd` | 14→16 | `model_env` (55 samples, 576 genomes) | Superseded by `model_final`; no interaction term |
| `16_hmsc_analysis_final.Rmd` | 16→18 | `model_final` | **Restored as `14_hmsc_analysis_final.Rmd`**; copy kept here for history |

## Archived setup chapters

| File | Former ch. | Models saved | Why archived |
|------|------------|--------------|--------------|
| `13_hmsc_setup2.Rmd` | 13 | `model_r100`, `model_r200`, `model_r400`, `model_tasmania` | Prevalence-filter pipeline; artifacts mismatch ERDA or are unused |
| `1z3_hmsc_setup2.Rmd` | — | (duplicate) | Legacy duplicate of setup2 |
| `hmsc_setup.Rmd` | — | legacy | Pre-bookdown setup |
| `hmsc_analysis.Rmd` | — | legacy | Pre-bookdown analysis |

## Archived HPC launch scripts

- `launch_hmsc_model_r100.sh`
- `launch_hmsc_model_r200.sh`
- `launch_hmsc_model_r400.sh`

**Active:** `launch_hmsc_model_final.sh` (project root)

## On-disk model artifacts

| File | Status | Notes |
|------|--------|-------|
| `hmsc/model_final` | **Canonical** | 55 Tasmania samples, 576 genomes — use with ERDA `Hmsc_model_final.rds` |
| `hmsc/model_env` | Legacy | Same dimensions as final; different formula (no interaction) |
| `hmsc/model_r100/r200/r400` | Legacy | Australia-wide; r200 ≠ ERDA posterior |
| `hmsc/model_tasmania` | Legacy | Rebuilt 901 genomes; no matching ERDA posterior |

Restore archived chapters only if you re-fit matching HPC posteriors and re-add them to `_bookdown.yml`.
