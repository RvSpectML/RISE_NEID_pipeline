import argparse
from backports.datetime_fromisoformat import MonkeyPatch
from datetime import date, timedelta
from pathlib import Path
from pyneid.neid import Neid
from shutil import rmtree

def download_neid(root_dir, start_date, end_date, level):
    # requested format of the meta file
    default_format = "csv"

    # increment by one day 
    delta_date = timedelta(days=1)

    while start_date <= end_date:
        # create the data directory for start_date
        outdir = root_dir.joinpath(str(start_date))
        outdir.mkdir(parents=True, exist_ok=True)

        # filepath of the meta file
        query_result_file = str(outdir.joinpath("meta.csv"))

        # query parameters
        param = {}
        param["datalevel"] = f"solarl{level}" # L1 data only
        param["object"] = "Sun"
        param["datetime"] = f'{start_date} 00:00:00/{start_date} 23:59:59'

        try:
            # get the meta file
            Neid.query_criteria(param, format=default_format, outpath=query_result_file)

            # download the fits data
            Neid.download(query_result_file, param["datalevel"], default_format, str(outdir))
        except:
            # if an error occurred, delete the directory for that date 
            rmtree(outdir)

        start_date += delta_date
        
# start of the program    
if __name__ == "__main__":
    # define the arguments
    parser = argparse.ArgumentParser(description='Download Solar L1 data from NEID archive.')
    parser.add_argument('root_dir', help='root directory to save the downloaded data files')
    parser.add_argument('start_date', help='start date yyyy-mm-dd of the data file to download')
    parser.add_argument('end_date', help='end date yyyy-mm-dd of the data file to download')
    parser.add_argument('level', help='data level')

    # parse the input arguments
    args = parser.parse_args()
    root_dir = Path(args.root_dir)
    MonkeyPatch.patch_fromisoformat()
    start_date = date.fromisoformat(args.start_date)
    end_date = date.fromisoformat(args.end_date)
    
    # download data files
    download_neid(root_dir, start_date, end_date, args.level)
    
