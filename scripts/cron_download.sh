#!/bin/sh

if qstat -u $(whoami) | grep download_neid
then
    echo "The previous run has not finished. Quit."
else
    echo "Submit the job."
    cd /gpfs/group/ebf11/default/RISE_NEID/workdir
    qsub ../scripts/download_neid.pbs
fi
