from datetime import date, timedelta
from pathlib import Path
from pyneid.neid import Neid

# requested format of the meta file
default_format = "csv"

# start and end dates
start_date = date(2020,12,12)  
end_date = date.today()
delta_date = timedelta(days=1)

while start_date <= end_date:
    # create the data directory for start_date
    outdir = Path(f'/gpfs/group/ebf11/default/RISE_NEID/data/input/solar_L1/{start_date}')
    outdir.mkdir(parents=True, exist_ok=True)
    
    # filepath of the meta file
    query_result_file = outdir.joinpath("meta.csv")

    # query parameters
    param = {}
    param["datalevel"] = "solarl1" # L1 data only
    param["object"] = "Sun"
    param["datetime"] = f'{start_date} 00:00:00/{start_date} 23:59:59'

    # get the meta file
    Neid.query_criteria(param, default_format, outpath=query_result_file)

    # download the fits data
    Neid.download(query_result_file, param["datalevel"], default_format, outdir)

    # logging
    num_lines = countlines(query_result_file) - 1
    println('{start_date}: {num_lines} entries have been downloaded.')
    
    start_date += delta_date