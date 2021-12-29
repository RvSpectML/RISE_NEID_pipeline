CONFIG_FILE = "config/config.yaml"
configfile: CONFIG_FILE

# retrieve directories from config file
DATA_ROOT = config["DATA_ROOT"]
DATA_L0_ROOT = config["DATA_L0_ROOT"]
INSTRUMENT = config["INSTRUMENT"]
INPUT_VERSION = config["INPUT_VERSION"]
LEVEL = config["LEVEL"]
USER_ID = config["USER_ID"]
PIPELINE_ID = config["PIPELINE_ID"]
NEID_SOLAR_SCRIPTS = config["NEID_SOLAR_SCRIPTS"]
PYRHELIO_DIR = config["PYRHELIO_DIR"]
NEXSCI_ID = config["NEXSCI_ID"]
EXCLUDE_FILENAME = config["EXCLUDE_FILENAME"]

import os
import shutil
from pathlib import Path
from datetime import datetime

# get the input and output directories
INPUT_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/L{LEVEL}"
INPUT_L0_DIR = f"{DATA_L0_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/L0"
OUTPUT_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/outputs/{USER_ID}/{PIPELINE_ID}"

# get the dates
#DATES, = glob_wildcards(f"{INPUT_DIR}/{{date}}/meta.csv", followlinks=True)              # Process all days with a saved query, i.e. to make pyrheliometer files from L0s irrespective of whether L2's have been downloaded
DATES, = glob_wildcards(f"{INPUT_DIR}/{{date}}/0_download_verified", followlinks=True)  # Only process days with verified L2's (usually line to use)
YEARS = [2021]  # TODO: Figure out how to automate which year/month combinations need to be run
MONTHS = ["01","02","03","04","05","06","07","08","09","10","11","12"]
#YEARS, MONTHS, DAYS, = glob_wildcards(f"{INPUT_DIR}/{{year}}/{{month}}/{{day}}/0_download_verified", followlinks=True)
#print( YEARS)  # WARNING: glob_wildcards returned list for every match, rather than unique match

# copy over the config file
onstart:
    Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)
    CONFIG_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/config/{USER_ID}/{PIPELINE_ID}/"
    Path(CONFIG_DIR).mkdir(parents=True, exist_ok=True)
    shutil.copyfile(CONFIG_FILE, f"{CONFIG_DIR}/config_{PIPELINE_ID}_{datetime.now()}.yaml")
    shell(f"echo Dates to be processed: {{DATES}}")

rule all:
    input:
        expand(f"{OUTPUT_DIR}/{{date}}/pyrheliometer.csv", date=DATES),
        expand(f"{OUTPUT_DIR}/{{date}}/manifest.csv", date=DATES),
        #expand(f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2", date=DATES),
        #expand(f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv", date=DATES),
        f"{OUTPUT_DIR}/combined_rvs_1.csv",
        expand(f"{OUTPUT_DIR}/{{date}}/daily_summary_1.toml",date=DATES),
        #expand(f"{OUTPUT_DIR}/{{year}}/{{month}}/monthly_summary_1.csv",year=YEARS,month=MONTHS), # TODO: Figure out how to impelement 
        f"{OUTPUT_DIR}/summary_1.csv"

rule prep_pyro:
    input:
        f"{INPUT_DIR}/{{date}}/meta.csv"
        # Intentionally exclude L0 fits files and *.tel files since the L0 files will be autodeleted from /gpfs/scratch and don't want to overwrite pyrooheliometer.csv files generated when L0s were present with ones generated from *.tel files.
    output:
        f"{OUTPUT_DIR}/{{date}}/pyrheliometer.csv"
    version: config["PYRHELIOMETER_VERSION"]
    run: 
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/scripts/make_pyrheliometer_daily_{{version}}.jl {{input}} --nexsci_login_filename {NEXSCI_ID} --pyrheliometer_dir {PYRHELIO_DIR} --work_dir {INPUT_L0_DIR}/{{wildcards.date}} --output {{output}}")

rule prep_manifest:
    input:
        manifest_dir=f"{INPUT_DIR}/{{date}}/",
        pyrheliometer=f"{OUTPUT_DIR}/{{date}}/pyrheliometer.csv"
    output:
        f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        f"{OUTPUT_DIR}/{{date}}/manifest_calib.csv"
    version: config["MANIFEST_VERSION"]
    run:
        shell(f"if [ ! -d {OUTPUT_DIR}/{{wildcards.date}} ]; then mkdir {OUTPUT_DIR}/{{wildcards.date}}; fi")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/scripts/make_manifest_solar_{{version}}.jl  {INPUT_DIR} {OUTPUT_DIR} --subdir {{wildcards.date}} --pyrheliometer {OUTPUT_DIR} ") 

rule calc_ccfs:
    input:
        manifest=f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        linelist=f"{NEID_SOLAR_SCRIPTS}/scripts/linelist_20210208.csv",
        #sed=f"{NEID_SOLAR_SCRIPTS}/data/neidMaster_HR_SmoothLampSED_20210101.fits",  # No longer needed, now that blaze is embedded in L2 files
        anchors=f"{NEID_SOLAR_SCRIPTS}/scripts/anchors_20210305.jld2"                 # TODO: Consider regenerating with DRP 1.1.*
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2"
    version: config["CCFS_VERSION"]
    params:
        orders_first=config["params"]["orders_first"],
        orders_last=config["params"]["orders_last"],
        range_no_mask_change=config["params"]["range_no_mask_change"],
        calc_order_ccfs_flags=config["params"]["calc_order_ccfs_flags"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} -t 1 {NEID_SOLAR_SCRIPTS}/examples/calc_order_ccfs_using_continuum_{{version}}.jl {{input.manifest}} {{output}} --line_list_filename {{input.linelist}}  --anchors_filename {{input.anchors}}  --orders_to_use={{params.orders_first}} {{params.orders_last}} --range_no_mask_change {{params.range_no_mask_change}} {{params.calc_order_ccfs_flags}} --overwrite")
    
    
rule calc_rvs:
    input:
        f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2"
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv"
    version: config["RVS_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_rvs_v{{version}}.jl {{input}} {{output}} ")

rule report_daily:
    input:
        rvs=f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv"
        #manifest=f"{OUTPUT_DIR}/{{date}}/manifest.csv"  # Not implemented yet, but eventually will use extra information from manifest file
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_summary_1.toml"
    version: config["REPORT_DAILY_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_report_v{{version}}.jl {{input.rvs}} {{output}}")

rule report_monthly:
    input:
#        expand(f"{OUTPUT_DIR}/{{year}}/{{month}}/{{day}}/daily_summary_1.toml",year=YEARS,month=MONTHS,day=DAYS)   # Not implemented yet, but eventually could look up info from these.
         glob_wildcards(f"{OUTPUT_DIR}/{{year}}/{{month}}/{{day}}/daily_summary_1.toml", followlinks=True)
    output:
        f"{OUTPUT_DIR}/{{year}}/{{month}}/monthly_summary_1.csv"
    version: config["REPORT_MONTHLY_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_reports_v{{version}}.jl {OUTPUT_DIR}/{{year}}/{{month}} {{output}} --input_filename daily_summary_1.toml --overwrite")

rule report_all:
    input:
        expand(f"{OUTPUT_DIR}/{{date}}/daily_summary_1.toml",date=DATES)
    output:
        good=f"{OUTPUT_DIR}/summary_1.csv",
        bad=f"{OUTPUT_DIR}/summary_incl_bad_1.csv"
    version: config["REPORT_ALL_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_reports_v{{version}}.jl {OUTPUT_DIR} {{output.good}} --input_filename daily_summary_1.toml --exclude_filename {EXCLUDE_FILENAME} --overwrite")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_reports_v{{version}}.jl {OUTPUT_DIR} {{output.bad}}  --input_filename daily_summary_1.toml --overwrite")

rule combine_rvs:
    input:
        expand(f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv",date=DATES)
    output:
        good=f"{OUTPUT_DIR}/combined_rvs_1.csv",
        bad=f"{OUTPUT_DIR}/combined_rvs_incl_bad_1.csv"
    version: config["COMBINE_RVS_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_rvs_1.0.jl {OUTPUT_DIR} {{output.good}} --input_filename daily_rvs_1.csv --exclude_filename {EXCLUDE_FILENAME} --overwrite")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_rvs_1.0.jl {OUTPUT_DIR} {{output.bad}}  --input_filename daily_rvs_1.csv --overwrite")


