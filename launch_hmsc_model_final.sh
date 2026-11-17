#!/bin/bash
#SBATCH --job-name=hmsc_model_final
#SBATCH --nodes=1
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal
#SBATCH --gres=gpu:1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32gb
#SBATCH --time=150:00:00
#
# Canonical MCMC (export before sbatch, or set here):
#   samples=250  thin=1000  transient=250000
# One chain per job — submit four jobs for nChains=4, then combine posteriors.
# Matches 13_hmsc_setup_final.Rmd / 14_hmsc_analysis_final.Rmd importPosteriorFromHPC(..., thin=1000).

# Activate conda environment
source activate hmsc-hpc

# Set output files
output="output/Hmsc_model_final.rds"
mkdir -p output

# Defaults if not exported by the caller
: "${samples:=250}"
: "${thin:=1000}"
: "${transient:=$((samples * thin))}"

# Run model fit (single chain)
srun python3 -m hmsc.run_gibbs_sampler --input "$init" --output "$output" --samples "$samples" --transient "$transient" --thin "$thin" --verbose 100
