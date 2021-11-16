import argparse
import pandas as pd
import shutil
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
        # filepath of the meta file
        query_result_file = root_dir.joinpath("meta_all.csv")

        # query parameters
        param = {}
        param["datalevel"] = f"solarl{level}" # L1 data only
        param["object"] = "Sun"
        param["datetime"] = f'{start_date} 00:00:00/{start_date} 23:59:59'

        try:
            # get the meta file
            Neid.query_criteria(param, format=default_format, outpath=str(query_result_file))

            # read the meta file
            df = pd.read_csv(str(query_result_file))
            groups = df.groupby('swversion')
            
            for swversion, grouped_df in groups:
                try:
                    # create the data directory for start_date
                    outdir = root_dir.joinpath(swversion)\
                    .joinpath(level)\
                    .joinpath(str(start_date.year))\
                    .joinpath(str(start_date.month))\
                    .joinpath(str(start_date.day))

                    outdir.mkdir(parents=True, exist_ok=True)
                    
                    group_file = outdir.joinpath("meta.csv")
                    grouped_df.to_csv(str(group_file))

                    # download the fits data
                    Neid.download(str(group_file), param["datalevel"], default_format, str(outdir))
                except:
                    shutil.rmtree(str(outdir))
            query_result_file.unlink()
        except:
            # if an error occurred, delete the query result file
            if query_result_file.is_file():
                query_result_file.unlink()
                
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
    
