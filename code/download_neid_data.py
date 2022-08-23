import argparse
import pandas as pd
import shutil
from datetime import datetime
from pathlib import Path
from pyneid.neid import Neid

def download_neid(root_dir, date, swversion, level, obj, cookie):
    # requested format of the meta file
    default_format = "csv"
    
    # create the root directory if it does not exist yet
    root_dir.mkdir(parents=True, exist_ok=True)

    # create the output directory if it does not exist yet
    out_dir = root_dir.joinpath(f'{date.year:04d}')\
                .joinpath(f'{date.month:02d}')\
                .joinpath(f'{date.day:02d}')

    out_dir.mkdir(parents=True, exist_ok=True)

    # query parameters
    param = {}
    
    if obj:
        param["object"] = obj
        param["datalevel"] = f"l{level}"
    else:        
        param["datalevel"] = f"solarl{level}"
        
    param["datetime"] = f'{date} 00:00:00/{date} 23:59:59'
    

    # skip the following section if the date's data has already been downloaded and verified
    if not out_dir.joinpath("0_download_verified").is_file():
        try: 
            if out_dir.joinpath("meta_redownload.csv").is_file():
                query_result_file = out_dir.joinpath("meta_redownload.csv")

                # download the fits data
                if cookie:
                    Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir), cookiepath=cookie) 
                else:
                    Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir)) 

                # remove meta_redonwload.csv
                query_result_file.unlink()
            else:
                # filepath of the meta file
                query_result_file_all = out_dir.joinpath("meta_all.csv")

                # get the meta file
                if cookie:
                    Neid.query_criteria(param, format=default_format, outpath=str(query_result_file_all), cookiepath=cookie)
                else:
                    Neid.query_criteria(param, format=default_format, outpath=str(query_result_file_all))

                # read the meta file
                df = pd.read_csv(str(query_result_file_all))

                # filter for the swversion
                if int(level) > 0: 
                    df_version = df[df['swversion'].str.startswith('v' + swversion)]  
                else:
                    df_version = df
                    
                # remove meta_all.csv
                query_result_file_all.unlink()

                if len(df_version.index) > 0:
                    # save to meta.csv
                    query_result_file = out_dir.joinpath("meta.csv")
                    df_version.to_csv(str(query_result_file))     

                    # download the fits data
                    if cookie:
                        Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir), cookiepath=cookie)         
                    else:
                        Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir)) 

                else:
                    # create 0_no_data_available if no data is available
                    f = open(out_dir.joinpath("0_no_data_available"), "w")
                    f.close()
                    
        except Exception as e:
            print(f"Error downloading the data for {date}! {e}")
        except:
            print(f"Error downloading the data for {date}!")

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
    parser.add_argument('date', help='date of the data file to download')
    parser.add_argument('swversion', help='software version that creates the input data, e.g. v1.1.2')
    parser.add_argument('level', help='data level, e.g. 0, 1 or 2')
    parser.add_argument('--object', help='object, e.g. HD 4628. If no object is provided, solar data will be downloaded')
    parser.add_argument('--cookie', help='filepath to the cookie file that is used to search the proprietary data')

    # parse the input arguments
    args = parser.parse_args()
    root_dir = Path(args.root_dir)
    date = get_date(args.date)
    
    # download data files
    download_neid(root_dir, date, args.swversion, args.level, args.object, args.cookie)
    
