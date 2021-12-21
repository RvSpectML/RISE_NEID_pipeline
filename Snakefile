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
PYROHELIO_DIR = config["PYROHELIO_DIR"]
NEXSCI_ID = config["NEXSCI_ID"]

import os
import shutil
from pathlib import Path
from datetime import datetime

# get the input and output directories
INPUT_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/L{LEVEL}"
INPUT_L0_DIR = f"{DATA_L0_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/L0"
OUTPUT_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/outputs/{USER_ID}/{PIPELINE_ID}"

# get the dates
DATES, = glob_wildcards(f"{INPUT_DIR}/{{date}}/0_download_verified", followlinks=True)

# copy over the config file
onstart:
    Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)
    CONFIG_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/config/{USER_ID}/{PIPELINE_ID}/"
    Path(CONFIG_DIR).mkdir(parents=True, exist_ok=True)
    shutil.copyfile(CONFIG_FILE, f"{CONFIG_DIR}/config_{PIPELINE_ID}_{datetime.now()}.yaml")
    shell(f"echo Dates with verified downloads: {{DATES}}")


rule all:
    input:
        expand(f"{OUTPUT_DIR}/{{date}}/pyrheliometer.csv", date=DATES),
        expand(f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv", date=DATES)

rule pyro:
    input:
        f"{INPUT_DIR}/{{date}}/meta.csv"
    output:
        f"{OUTPUT_DIR}/{{date}}/pyrheliometer.csv"
    run: 
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/scripts/make_pyrheliometer_daily.jl {{input}} --nexsci_login_filename {NEXSCI_ID} --pyrheliometer_dir {PYROHELIO_DIR} --work_dir {INPUT_L0_DIR}/{{wildcards.date}} --output {{output}}")

rule manifest:
    input:
        manifest_dir=f"{INPUT_DIR}/{{date}}/",
        pyrheliometer=f"{OUTPUT_DIR}/{{date}}/pyrheliometer.csv"
    output:
        f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        f"{OUTPUT_DIR}/{{date}}/manifest_calib.csv"
    version: config["MANIFEST_VERSION"]
    run:
        shell(f"if [ ! -d {OUTPUT_DIR}/{{wildcards.date}} ]; then mkdir {OUTPUT_DIR}/{{wildcards.date}}; fi")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/scripts/make_manifest_solar_{{version}}.jl  {INPUT_DIR} {OUTPUT_DIR} --subdir {{wildcards.date}} --pyrohelio {PYROHELIO_DIR} ") 
        #shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/scripts/make_manifest_solar_{{version}}.jl  {INPUT_DIR} {OUTPUT_DIR} --subdir {{wildcards.date}} --pyrheliometer {{input.pyrheliometer}} ") 

rule ccfs:
    input:
        manifest=f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        linelist=f"{NEID_SOLAR_SCRIPTS}/scripts/linelist_20210208.csv",
        #sed=f"{NEID_SOLAR_SCRIPTS}/data/neidMaster_HR_SmoothLampSED_20210101.fits",
        anchors=f"{NEID_SOLAR_SCRIPTS}/scripts/anchors_20210305.jld2"        
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
    
    
rule daily_report:
    input:
        f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2"
    output:
        csv=f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv",
        md=f"{OUTPUT_DIR}/{{date}}/daily_summary_1.md"
    version: config["REPORT_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_report_v{{version}}.jl {{input}} {{output.csv}} {{output.md}}")
        
