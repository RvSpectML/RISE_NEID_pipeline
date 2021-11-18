import argparse
import pandas as pd
import shutil
from backports.datetime_fromisoformat import MonkeyPatch
from datetime import date, timedelta
from pathlib import Path
from pyneid.neid import Neid
from shutil import rmtree

def download_neid(root_dir, start_date, end_date, obj, swversion, level):
    # requested format of the meta file
    default_format = "csv"

    # increment by one day 
    delta_date = timedelta(days=1)
    
    # create the root directory if it does not exist yet
    root_dir.mkdir(parents=True, exist_ok=True)

    while start_date <= end_date:
        # create the output directory if it does not exist yet
        out_dir = root_dir.joinpath(swversion)\
                    .joinpath(f"L{level}")\
                    .joinpath(str(start_date.year))\
                    .joinpath(str(start_date.month))\
                    .joinpath(str(start_date.day))
                    
        out_dir.mkdir(parents=True, exist_ok=True)
                   
        # query parameters
        param = {}
        param["datalevel"] = f"l{level}"
        param["object"] = obj
        param["datetime"] = f'{start_date} 00:00:00/{start_date} 23:59:59'
        
        # skip the following section if the date's data has already been downloaded and verified
        if not out_dir.joinpath("0_download_verified").is_file():
            try: 
                if out_dir.joinpath("meta_redownload.csv").is_file():
                    query_result_file = out_dir.joinpath("meta_redownload.csv")
                    
                    # download the fits data
                    Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir)) 
                    
                    # remove meta_redonwload.csv
                    query_result_file.unlink()
                else:
                    # filepath of the meta file
                    query_result_file_all = out_dir.joinpath("meta_all.csv")

                    # get the meta file
                    Neid.query_criteria(param, format=default_format, outpath=str(query_result_file_all))

                    # read the meta file
                    df = pd.read_csv(str(query_result_file))
                    
                    # filter for the swversion
                    df = df[df['swversion']==swversion]  
                    
                    # save to meta.csv
                    query_result_file = out_dir.joinpath("meta.csv")
                    df_version.to_csv(str(query_result_file))    
        
                    # remove meta_all.csv
                    query_result_file_all.unlink()

                    # download the fits data
                    Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir))            
            except Exception as e:
                print(e)
                
        start_date += delta_date
        
# start of the program    
if __name__ == "__main__":
    # define the arguments
    parser = argparse.ArgumentParser(description='Download data from NEID archive.')
    parser.add_argument('root_dir', help='root directory to save the downloaded data files')
    parser.add_argument('start_date', help='start date yyyy-mm-dd of the data file to download')
    parser.add_argument('end_date', help='end date yyyy-mm-dd of the data file to download')
    parser.add_argument('obj', help='object, e.g. Sun')
    parser.add_argument('swversion', help='software version that creates the input data, e.g. v1.1.2')
    parser.add_argument('level', help='data level, e.g. 0, 1 or 2')

    # parse the input arguments
    args = parser.parse_args()
    root_dir = Path(args.root_dir)
    MonkeyPatch.patch_fromisoformat()
    start_date = date.fromisoformat(args.start_date)
    end_date = date.fromisoformat(args.end_date)
    
    # download data files
    download_neid(root_dir, start_date, end_date, args.obj, args.swversion, args.level)
    
