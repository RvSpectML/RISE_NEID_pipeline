from pyneid.neid import Neid

Neid.query_datetime('l1', '2020-12-31 00:00:00/2020-12-31 23:59:59', outpath='./meta.xml')



# include("password.jl")  # Needs to set user_nexsci and passwd_nexsci
# cookie_nexsci = "./neidadmincookie.txt"


#NeidArchive.login(userid=user_nexsci, password=passwd_nexsci, cookiepath=cookie_nexsci)



query_result_file = "./meta.csv"
default_format = "csv"
outdir = "."

param = {}
param["datalevel"] = "solarl1"
param["object"] = "Sun"
param["datetime"] = "2021-01-14 00:00:00/2021-01-14 23:59:59"

Neid.query_criteria(param, default_format, outpath=query_result_file)


num_lines = countlines(query_result_file) - 1
println("# Query resulted in file with ", num_lines, " entries.")






Neid.download(query_result_file, param["datalevel"], default_format, outdir, start_row=1, end_row=2)


