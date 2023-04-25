import json
import os
import pandas as pd
from datetime import datetime, timedelta
from math import floor
from pip._vendor import tomli
from pyneid.neid import Neid

# Get all objects including the standard stars defined in config and the objects in the programs
def get_object_dates():
    object_dates = {}
    
    # add objects in programs in config
    programs = config["PROGRAMS"]
    if programs:
        for program in programs:
            param={'datetime': f'{start_datetime}/{end_datetime}', 'datalevel': 'l2', 'program': program}
            metafile = f'meta_{program}.csv'
            Neid.query_criteria(param, format='csv', outpath=metafile, cookiepath=COOKIE)
            df = pd.read_csv(metafile)
            # calcuate the date
            df['date'] = df['date_obs'].apply(lambda x: meta_datetime_to_date(x))
            # group by object and date
            for object in pd.unique(df['object']):
                df_object = df[df['object'] == object]
                object_dates[object] = list(pd.unique(df_object['date']))
                for date in object_dates[object]:
                    dir = f"{DATA_ROOT}/{object}/v{INPUT_VERSION}/L2/{date}"
                    if config["RUN_ALL_DATES"] == "yes" or not os.path.exists(f"{dir}/0_download_verified"):
                        df_object_date = df_object[df_object['date'] == date]
                        # save as meta_redownload.csv to the corresponding folder
                        if not os.path.exists(dir):
                            os.makedirs(dir)
                        df_object_date.to_csv(f"{dir}/meta_redownload.csv", index=False) 
                    
    # existing object folders
    if config["INCLUDE_STARS_IN_DATA_FOLDER"]:       
        objects, = glob_wildcards(f"{DATA_ROOT}/{{obj}}/v{INPUT_VERSION}/L2")
    else:
        objects = []
    
    # add the objects explicitly listed in config
    if config["STANDARD_STARS"]:
        objects.extend(config["STANDARD_STARS"]) 
        
    for object in objects:
        if object not in object_dates:
            param={'datetime': f'{start_datetime}/{end_datetime}', 'datalevel': 'l2', 'object': object}
            metafile = f'meta_{object}.csv'
            Neid.query_criteria(param, format='csv', outpath=metafile, cookiepath=COOKIE)
            df_object = pd.read_csv(metafile)
            # calcuate the date
            df_object['date'] = df_object['date_obs'].apply(lambda x: meta_datetime_to_date(x))
            object_dates[object] = list(pd.unique(df_object['date']))
            for date in object_dates[object]:
                dir = f"{DATA_ROOT}/{object}/v{INPUT_VERSION}/L2/{date}"
                if config["RUN_ALL_DATES"] == "yes" or not os.path.exists(f"{dir}/0_download_verified"):
                    df_object_date = df_object[df_object['date'] == date]
                    # save as meta_redownload.csv to the corresponding folder
                    if not os.path.exists(dir):
                        os.makedirs(dir)
                    df_object_date.to_csv(f"{dir}/meta_redownload.csv", index=False) 
    
    with open("object_dates.txt", "w") as f:
        json.dump(object_dates, f)