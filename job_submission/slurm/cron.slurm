#!/bin/bash

####  Job name
#SBATCH --job-name=neidcron

####  Request resources here
####    These are typically, number of processors, amount of memory,
####    an the amount of time a job requires.  May include processor
####    type, too.
#SBATCH --ntasks=1
#SBATCH --mem=1GB
#SBATCH --time=1:00:00
#SBATCH --partition=open

####  Schedule the start time of this job
#SBATCH --begin=01:00:00

echo "Cron job $SLURM_JOBID started on $(hostname) at $(date)"

##  Print the nodename(s) to the output in case needed for diagnostics,
##  or if you need information about the hardware after the job ran.
echo $SLURM_JOB_NODELIST

####################################################################
# Run  the  pipeline                                               #
####################################################################

PIPELINE_JOBID=$(sbatch --parsable ${SLURM_SUBMIT_DIR}/pipeline.slurm)

sleep 10

####################################################################
# Submit the next job                                              #
####################################################################

sbatch -d afterany:${PIPELINE_JOBID} ${SLURM_SUBMIT_DIR}/cron.slurm