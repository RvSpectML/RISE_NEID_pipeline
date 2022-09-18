import argparse
import pandas as pd
import shutil
from datetime import datetime, timedelta
from pathlib import Path
from pyneid.neid import Neid

def query_neid_metadata(filepath, start_date, end_date, swversion, level, obj, cookie):
    # requested format of the meta file
    default_format = "csv"

    # query parameters
    param = {}
    param["datetime"] = f'{start_date} 00:00:00/{end_date} 23:59:59'
    
    if obj:
        param["object"] = obj
        param["datalevel"] = f"l{level}"
    else:
        param["datalevel"] = f"solarl{level}"
        
    try: 
        # get the meta file
        if cookie:
            Neid.query_criteria(param, format=default_format, outpath=filepath, cookiepath=cookie)
        else:
            Neid.query_criteria(param, format=default_format, outpath=filepath)

        # filter for the swversion
        if int(level) > 0: 
            df = pd.read_csv(filepath)
            df = df[df['swversion'].str.startswith('v' + swversion)]  
            df.to_csv(filepath, index=False)
    except Exception as e:
        print(f"Error downloading the data! {e}")
        
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
    parser = argparse.ArgumentParser(description='Query meta data from NEID archive.')
    parser.add_argument('filepath', help='filepath to save the downloaded meta file')
    parser.add_argument('start_date', help='start date of the data file to download. Accepted formats include YYYY-MM-DD, YYYY/MM/DD and MM/DD/YYYY')
    parser.add_argument('end_date', help='end date of the data file to download. Accepted formats include YYYY-MM-DD, YYYY/MM/DD and MM/DD/YYYY')
    parser.add_argument('swversion', help='software version that creates the input data, e.g. 1.1 or 1.1.2')
    parser.add_argument('level', help='data level, e.g. 0, 1 or 2')
    parser.add_argument('--object', help='object, e.g. HD 4628. If no object is provided, solar data will be downloaded')
    parser.add_argument('--cookie', help='filepath to the cookie file that is used to search the proprietary data')

    # parse the input arguments
    args = parser.parse_args()
    
    # download data files
    query_neid_metadata(args.filepath, get_date(args.start_date), get_date(args.end_date), args.swversion, args.level, args.object, args.cookie)
    
