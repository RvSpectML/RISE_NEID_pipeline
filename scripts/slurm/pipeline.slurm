#!/bin/bash

####  Job name
#SBATCH --job-name=neid

####  Request resources here
####    These are typically, number of processors, amount of memory,
####    an the amount of time a job requires.  May include processor
####    type, too.
#SBATCH --ntasks=1
#SBATCH --mem=16GB
#SBATCH --time=23:00:00
#SBATCH --partition=open

echo "Job $SLURM_JOBID started on $(hostname) at $(date)"

cd $SLURM_SUBMIT_DIR

##  Print the nodename(s) to the output in case needed for diagnostics,
##  or if you need information about the hardware after the job ran.
echo $SLURM_JOB_NODELIST

####################################################################
#                                                                  #
# UPDATE VARIABLES HERE                                            #
#                                                                  #
####################################################################

# set the start and end dates to download data for
START_DATE="2022-05-29"
END_DATE="2022-05-29"
#END_DATE=$(date --date='yesterday' +"%Y-%m-%d")

# Choose whether to run jobs in cluster mode or serial mode:
# 1: cluster mode
# 0: serial mode
CLUSTER_MODE=1

# directory of the pipeline
PIPELINE_DIR=/storage/work/dus73/pipeline

# path to the python virtual environment
VIRTUAL_ENV=${PIPELINE_DIR}/venv/bin/activate

# path to the cluster configuration folder
PROFILE=${PIPELINE_DIR}/shared/config/slurm/

# path to the Snakefile
SNAKEFILE=Snakefile

# path to the config file
CONFIGFILE=config.yaml

# path to julia. If not provided, the system's julia module will be loaded.
#export JULIA_PATH=

# Path to julia depot _for user submitting the job_.  
# Do NOT try to have multiple users share one julia depot!
# Keep commented out if your julia depot is in ~/.julia (good to make this a symlink, so not in home directory)
#export JULIA_DEPOT_PATH=

####################################################################
#                                                                  #
# Run snakemake                                                    #
#                                                                  #
####################################################################

# load the python virtual environment
source ${VIRTUAL_ENV}

# load julia: if no JULIA_PATH is provided, loadd the system's julia module; 
# otherwise add the provided julia path to PATH.
if [ -z ${JULIA_PATH+x} ]
then 
    module load julia
else
    export PATH=${JULIA_PATH}:$PATH
fi

if(( $CLUSTER_MODE==1))
then
    snakemake --keep-going --snakefile ${SNAKEFILE} --configfile ${CONFIGFILE} --config start_date=${START_DATE} end_date=${END_DATE} pipeline_dir=${PIPELINE_DIR} --profile ${PROFILE} --latency-wait 20 --groups prep_pyro=group0 prep_manifest=group0 calc_ccfs=group0 calc_rvs=group0 report_daily=group0 --group-components group0=3 # --forcerun manifest
else
    snakemake --keep-going --snakefile ${SNAKEFILE} --configfile ${CONFIGFILE} --config start_date=${START_DATE} end_date=${END_DATE} pipeline_dir=${PIPELINE_DIR} -c1
    # snakemake --configfile config.yaml --config start_date=2022-05-29 end_date=2022-05-29 pipeline_dir=/storage/home/dus73/work/pipeline -np # dry run
fi

# Printing out job summary
qstat -f $SLURM_JOBID
