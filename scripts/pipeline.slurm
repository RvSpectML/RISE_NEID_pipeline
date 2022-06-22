#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --mem=10MB
#SBATCH --partition=open
#SBATCH --time=1:00:00
#SBATCH --begin=01:00:00
#SBATCH --output=chron.slurm.%j.log
#SBATCH --job-name=chron_test

sleep 1m
sbatch -d afterany:${SLURM_JOB_ID} ${SLURM_SUBMIT_DIR}/pipeline.slurm
date >> chron.log
sleep 10m