CONFIG_FILE = "config/config.yaml"
configfile: CONFIG_FILE

# retrieve directories from config file
DATA_ROOT = config["DATA_ROOT"]
INSTRUMENT = config["INSTRUMENT"]
INPUT_VERSION = config["INPUT_VERSION"]
USER_ID = config["USER_ID"]
PIPELINE_ID = config["PIPELINE_ID"]
JULIA = config["JULIA"]
NEID_SOLAR_SCRIPTS = config["NEID_SOLAR_SCRIPTS"]

import os
import shutil
from pathlib import Path

# copy over the config file
CONFIG_DIR = f"{DATA_ROOT}/{INSTRUMENT}/{INPUT_VERSION}/config/{USER_ID}/{PIPELINE_ID}/"
Path(CONFIG_DIR).mkdir(parents=True, exist_ok=True)
shutil.copyfile(CONFIG_FILE, f"{CONFIG_DIR}/config_{PIPELINE_ID}.yaml")

# get the input and output directories
INPUT_DIR = f"{DATA_ROOT}/{INSTRUMENT}/{INPUT_VERSION}"
OUTPUT_DIR = f"{DATA_ROOT}/{INSTRUMENT}/{INPUT_VERSION}/outputs/{USER_ID}/{PIPELINE_ID}"

# get the dates
DATES, FITFILES = glob_wildcards(f"{INPUT_DIR}/L1/{{date}}/{{fitfile}}.fits")


rule all:
    input:
        expand(f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv", date=DATES)


rule manifest:
    input:
        f"{INPUT_DIR}/{{date}}/"
    output:
        f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        f"{OUTPUT_DIR}/{{date}}/manifest_calib.csv"
    run:
        shell(f"if [ ! -d {OUTPUT_DIR}/{{wildcards.date}} ]; then mkdir {OUTPUT_DIR}/{{wildcards.date}}; fi")
        shell(f"{JULIA} --project={NEID_SOLAR_SCRIPTS} -e 'target_subdir=\"{{input}}\"; output_dir=\"{OUTPUT_DIR}/{{wildcards.date}}\";  include(\"{NEID_SOLAR_SCRIPTS}/scripts/make_manifest_solar_1.0.0.jl\")'")


rule ccfs:
    input:
        manifest=f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        linelist=f"{NEID_SOLAR_SCRIPTS}/scripts/linelist_20210208.csv",
        sed=f"{NEID_SOLAR_SCRIPTS}/data/neidMaster_HR_SmoothLampSED_20210101.fits",
        anchors=f"{NEID_SOLAR_SCRIPTS}/scripts/anchors_20210305.jld2"        
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2"
    params:
        orders_first=config["params"]["orders_first"],
        orders_last=config["params"]["orders_last"],
        range_no_mask_change=config["params"]["range_no_mask_change"]
    run:
        shell(f"{JULIA} --project={NEID_SOLAR_SCRIPTS} -t 1 {NEID_SOLAR_SCRIPTS}/examples/calc_order_ccfs_using_continuum_1.0.0.jl {{input.manifest}} {{output}} --line_list_filename {{input.linelist}} --sed_filename {{input.sed}}  --anchors_filename {{input.anchors}}  --orders_to_use={{params.orders_first}} {{params.orders_last}} --range_no_mask_change {{params.range_no_mask_change}}  --apply_continuum_normalization  --variable_mask_scale  --overwrite")
    
    
rule daily_report:
    input:
        f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2"
    output:
        csv=f"{OUTPUT_DIR}/{{date}}/daily_rvs_1.csv",
        md=f"{OUTPUT_DIR}/{{date}}/daily_summary_1.md"
    run:
        shell(f"{JULIA} --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_report_v1.1.jl {{input}} {{output.csv}} {{output.md}}")
        
