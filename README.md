# Download data from NEID ARCHIVE
 
To download solar L1 data from NEID ARCHIVE https://neid.ipac.caltech.edu/search_solar.php,

$ cd /gpfs/group/ebf11/default/RISE_NEID/workdir

$ qsub ../scripts/download_neid.pbs

Downloaded data will be saved to /gpfs/group/ebf11/default/RISE_NEID/data/solar_L1/v1.0.0, 
grouped by date, and the output logs will be saved to /gpfs/group/ebf11/default/RISE_NEID/woorkdir.
The latest date for which the NEID data has been downloaded is recorded in the file 
/gpfs/group/ebf11/default/RISE_NEID/data/solar_L1/v1.0.0/0_max_date. The PBS script download_neid.pbs
checks that latest date, and it sets the start date of the new query to be the next day of that date 
and sets the end date to be yesterday. It then calls code/download_neid_data.py to download the data
between the start and end dates.

# Move data from group directory to archive on ROAR

The archive storage is only accessible from a data manager node on ROAR. To log in a data manager node

$ ssh username@datamgr.aci.ics.psu.edu

To move data from the group directory /gpfs/group/ebf11/default/RISE_NEID/data/solar_L1/v1.0.0 to the 
archive directory /archive/ebf11/default/RISE_NEID/solar_L1/v1.0.0,

$ sh /gpfs/group/ebf11/default/RISE_NEID/scripts/move_to_archive.sh <FOLDER_NAME>

e.g $ sh /gpfs/group/ebf11/default/RISE_NEID/scripts/move_to_archive.sh 2021-07-22

This script compresses the folder to a .tar.gz file and saves the compressed file to the archive directory,
and then it deletes the original folder. 

# Copy data from archive to group directory on ROAR

The archive storage is only accessible from a data manager node on ROAR. To log in a data manager node

$ ssh username@datamgr.aci.ics.psu.edu

To copy the data from archive storage /archive/ebf11/default/RISE_NEID/solar_L1/v1.0.0 to the active storage
(e.g. group directory or scrache space),

$ cd <DESTINATION_FOLDER>

$ tar -xzf /archive/ebf11/default/RISE_NEID/solar_L1/v1.0.0/<FOLDER_NAME>.tar.gz

Note that you are in charge of deleting the extracted folder on the active storage after usage if necessary.
