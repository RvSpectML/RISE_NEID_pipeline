#!/bin/bash

####################################################################
#                                                                  #
# UPDATE VARIABLES HERE                                            #
#                                                                  #
####################################################################

# set the start and end dates to download data for
START_DATE="2021-10-10"
END_DATE="2021-10-10"
#END_DATE=$(date --date='yesterday' +"%Y-%m-%d")

echo "# Attempting to processes dates from $START_DATE to $END_DATE."

# Choose whether to run jobs in cluster mode or serial mode:
# 1: cluster mode
# 0: serial mode
CLUSTER_MODE=0

# directory of the pipeline
#PIPELINE_DIR=/storage/work/dus73/pipeline
PIPELINE_DIR=/storage/group/ebf11/default/pipeline

# path to the python virtual environment
VIRTUAL_ENV=${PIPELINE_DIR}/venv/bin/activate

# path to the cluster configuration folder
PROFILE=${PIPELINE_DIR}/shared/profile/slurm-open/

# path to the Snakefile
SNAKEFILE=Snakefile

# path to the config file
CONFIGFILE=config.yaml

# path to julia. If not provided, the system's julia module will be loaded.
#export JULIA_PATH=

# Path to julia depot _for user submitting the job_.  
# Do NOT try to have multiple users share one julia depot!
# Julia depot can get big an home directory can be slow, so best not to keep your julia depot in your home directory.  
# It's good to make ~/.julia a symlink to /storage/work/${USER}/julia_depot, so it's not in home directory and gets found even if forget to set JULIA_DEPOT_PATH.
# Comment out if your julia depot is in ~/.julia 
#export JULIA_DEPOT_PATH=/storage/work/${USER}/julia_depot/

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

date
echo "# Running snakemake"

if [[ $CLUSTER_MODE == 1 ]]
then
    snakemake -n --keep-going --snakefile ${SNAKEFILE} --configfile ${CONFIGFILE} --config start_date=${START_DATE} end_date=${END_DATE} pipeline_dir=${PIPELINE_DIR} --profile ${PROFILE} --latency-wait 20 daily_manifest
    
    sleep 10
    
    snakemake -n --keep-going --snakefile ${SNAKEFILE} --configfile ${CONFIGFILE} --config start_date=${START_DATE} end_date=${END_DATE} pipeline_dir=${PIPELINE_DIR} --profile ${PROFILE} --latency-wait 20 ssof_summary --forceall
else
    snakemake -n --keep-going --snakefile ${SNAKEFILE} --configfile ${CONFIGFILE} --config start_date=${START_DATE} end_date=${END_DATE} pipeline_dir=${PIPELINE_DIR} -c1 daily_manifest
    
    snakemake -n --keep-going --snakefile ${SNAKEFILE} --configfile ${CONFIGFILE} --config start_date=${START_DATE} end_date=${END_DATE} pipeline_dir=${PIPELINE_DIR} -c1 ssof_summary --forceall
fi

date

deactivate

