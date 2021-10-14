#!/bin/sh

# when jobs are submitted to the normal queeue, uncomment the follwoing line
# if qstat -u $(whoami) | grep download_neid
# when jobs are submitted to the hprc queue, uncomment the following line
if qstat @torque02.util.production.int.aci.ics.psu.edu | grep download_neid
then
    echo "The previous run has not finished. Quit."
else
    echo "Submit the job."
    cd /gpfs/group/ebf11/default/RISE_NEID
    /usr/local/bin/qsub scripts/download_neid.pbs
fi
