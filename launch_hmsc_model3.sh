#!/bin/bash
#SBATCH --job-name=hmsc_hpc_model3
#SBATCH --nodes=1
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal
#SBATCH --gres=gpu:1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32gb
#SBATCH --time=100:00:00

# Activate conda environment
source activate hmsc-hpc

# Set output files
output="output/Hmsc_model_model3.rds"
mkdir output

# Run model fit
srun python3 -m hmsc.run_gibbs_sampler --input $init --output $output --samples $samples --transient $transient --thin $thin --verbose 100
