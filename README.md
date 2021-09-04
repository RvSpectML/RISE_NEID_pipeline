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

