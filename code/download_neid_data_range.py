import argparse
import pandas as pd
import shutil
from datetime import datetime, timedelta
from pathlib import Path
from pyneid.neid import Neid

def download_neid(root_dir, start_date, end_date, swversion, level):
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
                    .joinpath(f'{start_date.year:04d}')\
                    .joinpath(f'{start_date.month:02d}')\
                    .joinpath(f'{start_date.day:02d}')
                    
        out_dir.mkdir(parents=True, exist_ok=True)
                   
        # query parameters
        param = {}
        param["datalevel"] = f"solarl{level}"
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
                    df = pd.read_csv(str(query_result_file_all))
                    
                    # filter for the swversion
                    if int(level) > 0: 
                        df_version = df[df['swversion']==swversion]  
                    
                    if (len(df.index) > 0 ):
                        # save to meta.csv
                        query_result_file = out_dir.joinpath("meta.csv")
                        if int(level) > 0:
                            df_version.to_csv(str(query_result_file))    
                        else:
                            df.to_csv(str(query_result_file))    
        
                        # remove meta_all.csv
                        query_result_file_all.unlink()

                        # download the fits data
                        Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir))            
                    else:
                        shutil.rmtree(str(out_dir))
            except Exception as e:
                print(f"Error downloading the data for {start_date}! {e}")
            except:
                print(f"Error downloading the data for {start_date}!")
                
        start_date += delta_date
        
def get_date(s):
    date = None
    if "-" in s:
        date = datetime.strptime(s, "%Y-%m-%d").date()
    else:
        try:
            date = datetime.strptime(s, "%Y/%m/%d").date()
        except ValueError:
            date = datetime.strptime(s, "%m/%d/%Y").date()
            
    return date
        
# start of the program    
if __name__ == "__main__":
    # define the arguments
    parser = argparse.ArgumentParser(description='Download data from NEID archive.')
    parser.add_argument('root_dir', help='root directory to save the downloaded data files')
    parser.add_argument('start_date', help='start date of the data file to download')
    parser.add_argument('end_date', help='end date of the data file to download')
    parser.add_argument('swversion', help='software version that creates the input data, e.g. v1.1.2')
    parser.add_argument('level', help='data level, e.g. 0, 1 or 2')

    # parse the input arguments
    args = parser.parse_args()
    root_dir = Path(args.root_dir)
    start_date = get_date(args.start_date)
    end_date = get_date(args.end_date)
    
    # download data files
    download_neid(root_dir, start_date, end_date, args.swversion, args.level)
    