# HMSC MCMC provenance

**Checked:** 17 November 2026

| Setting | Value | Evidence |
| --- | --- | --- |
| Chains × retained samples | **4 × 250** | `hmsc/Hmsc_model_final.rds` → `obj$list` length 4, each chain length 250 |
| `thin` | **1000** | `13_hmsc_setup_final.Rmd`, `14_hmsc_analysis_final.Rmd` (`importPosteriorFromHPC(..., thin=1000)`), `launch_hmsc_model_final.sh` defaults |
| `transient` | **250000** (= samples × thin) | same scripts |
| HPC scheduler logs | **Not in this repo** | No `.out`/`.err` job logs found under `hmsc/` |

Conclusion: manuscript MCMC wording matches the deposited posterior size and the only launch/import path in the repository. Absolute confirmation of thin/transient would require the original Slurm logs on the HPC; they are not archived here.
