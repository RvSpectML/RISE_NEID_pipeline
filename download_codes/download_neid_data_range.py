import argparse
import pandas as pd
import shutil
from datetime import datetime, timedelta
from pathlib import Path
from pyneid.neid import Neid

def download_neid_range(root_dir, start_date, end_date, swversion, level, obj, cookie, cutoff_time_of_day):
    # requested format of the meta file
    default_format = "csv"

    # increment by one day 
    delta_date = timedelta(days=1)
    
    # create the root directory if it does not exist yet
    root_dir.mkdir(parents=True, exist_ok=True)
    
    while start_date <= end_date:
        # create the output directory if it does not exist yet
        out_dir = root_dir.joinpath(f'{start_date.year:04d}')\
                    .joinpath(f'{start_date.month:02d}')\
                    .joinpath(f'{start_date.day:02d}')
                    
        out_dir.mkdir(parents=True, exist_ok=True)
                   
        # query parameters
        param = {}
        
        if obj:
            param["object"] = obj
            param["datalevel"] = f"l{level}"
        else:        
            param["datalevel"] = f"solarl{level}"
        
        if cutoff_time_of_day:
            if type(cutoff_time_of_day) is list and len(cutoff_time_of_day) == 2:
                start_time = cutoff_time_of_day[0]
                end_time = cutoff_time_of_day[1]
                if start_time <= end_time:
                    param["datetime"] = f'{start_date} {start_time}/{start_date} {end_time}'
                else:
                    next_date = start_date + timedelta(days=1)
                    param["datetime"] = f'{start_date} {start_time}/{next_date} {end_time}'
            else:
                raise Exception("The format of cutoff_time_of_day is wrong!")
        else:
            param["datetime"] = f'{start_date} 00:00:00/{start_date} 23:59:59'
        
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
                    
                    if (len(df_version.index) > 0 ):
                        # save to meta.csv
                        query_result_file = out_dir.joinpath("meta.csv")
                        df_version.to_csv(str(query_result_file), index=False)

                        # download the fits data
                        if cookie:
                            Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir), cookiepath=cookie)      
                        else:
                            Neid.download(str(query_result_file), param["datalevel"], default_format, str(out_dir)) 
                    else:
                        f = open(out_dir.joinpath("0_no_data_available"), "w")
                        f.close()
            except Exception as e:
                print(f"Error downloading the data for {start_date}! {e}")
                
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
    parser.add_argument('start_date', help='start date of the data file to download. Accepted formats include YYYY-MM-DD, YYYY/MM/DD and MM/DD/YYYY')
    parser.add_argument('end_date', help='end date of the data file to download. Accepted formats include YYYY-MM-DD, YYYY/MM/DD and MM/DD/YYYY')
    parser.add_argument('swversion', help='software version that creates the input data, e.g. 1.1 or 1.1.2')
    parser.add_argument('level', help='data level, e.g. 0, 1 or 2')
    parser.add_argument('--object', help='object, e.g. HD 4628. If no object is provided, solar data will be downloaded')
    parser.add_argument('--cookie', help='filepath to the cookie file that is used to search the proprietary data')
    parser.add_argument('--cutoff_time_of_day', nargs=2, help='cutoff time of day (24-hour time format in UTC). The input should be a pair of start time and end time, e.g. 22:30:00 16:45:00. If the end time is less than the start time, the end time refers to the time of the next day. Default value: 00:00:00 23:59:59')

    # parse the input arguments
    args = parser.parse_args()
    root_dir = Path(args.root_dir)
    start_date = get_date(args.start_date)
    end_date = get_date(args.end_date)
    
    # download data files
    download_neid_range(root_dir, start_date, end_date, args.swversion, args.level, args.object, args.cookie, args.cutoff_time_of_day)
    