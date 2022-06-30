# retrieve directories from config file
PIPELINE_DIR = config["pipeline_dir"]
NEID_SOLAR_SCRIPTS = PIPELINE_DIR + "/" + config["NEID_SOLAR_SCRIPTS"]
EXCLUDE_FILENAME = PIPELINE_DIR + "/" + config["EXCLUDE_FILENAME"]
INSTRUMENT = config["INSTRUMENT"]
INPUT_VERSION = config["INPUT_VERSION"]
USER_ID = config["USER_ID"]
PIPELINE_ID = config["PIPELINE_ID"]

DATA_ROOT = f"{PIPELINE_DIR}/data"
DOWNLOAD_SCRIPT = PIPELINE_DIR + "/" + config["DOWNLOAD_SCRIPT"]

LINELISTS = config["params"]["linelist"]
CCFS_FLAGS = config["params"]["calc_order_ccfs_flags"]

import os
import shutil
from datetime import datetime, timedelta
from pathlib import Path

# get the input and output directories
INPUT_L2_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/L2"
INPUT_L0_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/L0"
PYRHELIO_DIR = f"{DATA_ROOT}/{INSTRUMENT}/pyrheliometer"
PYRO_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/pyro"
MANIFEST_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/manifest"
OUTPUT_DIR = f"{DATA_ROOT}/{INSTRUMENT}/v{INPUT_VERSION}/outputs/{USER_ID}/{PIPELINE_ID}"

# get the dates
# Process all days with a saved query, i.e. to make pyrheliometer files from L0s irrespective of whether L2's have been downloaded
# DATES, = glob_wildcards(f"{INPUT_L2_DIR}/{{date}}/meta.csv", followlinks=True) 

# Only process days with verified L2's (usually line to use)
# DATES, = glob_wildcards(f"{INPUT_L2_DIR}/{{date}}/0_download_verified", followlinks=True)  

# Process days between given dates
start_date = datetime.strptime(config["start_date"], "%Y-%m-%d").date()
end_date = datetime.strptime(config["end_date"], "%Y-%m-%d").date()

delta = end_date - start_date
DATES = [(start_date + timedelta(days=x)).strftime("%Y/%m/%d") for x in range(delta.days + 1)]

rule all:
    input:
        expand(f"{OUTPUT_DIR}/combined_rvs_{{linelist_key}}_{{ccfs_flag_key}}.csv", linelist_key=list(LINELISTS.keys()), ccfs_flag_key=list(CCFS_FLAGS.keys())),
        expand(f"{OUTPUT_DIR}/summary_{{linelist_key}}_{{ccfs_flag_key}}.csv", linelist_key=list(LINELISTS.keys()), ccfs_flag_key=list(CCFS_FLAGS.keys())),
        #expand(f"{OUTPUT_DIR}/{{year}}/{{month}}/monthly_summary.csv",year=YEARS,month=MONTHS), # TODO: Figure out how to impelement 


rule download_L0:
    output:
        f"{INPUT_L0_DIR}/{{date}}/meta.csv"
    run:
        shell(f"python {DOWNLOAD_SCRIPT} {INPUT_L0_DIR} {{wildcardsdate}} {INPUT_VERSION} 0")
    
    
rule download_L2:
    output:
        f"{INPUT_L2_DIR}/{{date}}/meta.csv"
    run:
        shell(f"python {DOWNLOAD_SCRIPT} {INPUT_L2_DIR} {{wildcards.date}} {INPUT_VERSION} 2")


rule prep_pyro:
    input:
        metafile=f"{INPUT_L2_DIR}/{{date}}/meta.csv",
        # Intentionally exclude L0 fits files and *.tel files since the L0 files will be autodeleted from /gpfs/scratch and don't want to overwrite pyrooheliometer.csv files generated when L0s were present with ones generated from *.tel files.
        nexsci_id=NEID_SOLAR_SCRIPTS + "/" + config["params"]["NEXSCI_ID"]
    output:
        f"{PYRO_DIR}/{{date}}/pyrheliometer.csv"
    version: config["PYRHELIOMETER_VERSION"]
    run: 
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/scripts/make_pyrheliometer_daily_{{version}}.jl {{input}} --nexsci_login_filename {{input.nexsci_id}} --pyrheliometer_dir {PYRHELIO_DIR} --work_dir {INPUT_L0_DIR}/{{wildcards.date}} --output {{output}}")

rule prep_manifest:
    input:
        pyrheliometer=f"{PYRO_DIR}/{{date}}/pyrheliometer.csv"
    output:
        f"{MANIFEST_DIR}/{{date}}/manifest.csv",
        f"{MANIFEST_DIR}/{{date}}/manifest_calib.csv"
    version: config["MANIFEST_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/scripts/make_manifest_solar_{{version}}.jl  {INPUT_L2_DIR} {MANIFEST_DIR} --subdir {{wildcards.date}} --pyrheliometer {PYRO_DIR} ") 

rule calc_ccfs:
    input:
        manifest=f"{MANIFEST_DIR}/{{date}}/manifest.csv",
        linelist_file=lambda wildcards:NEID_SOLAR_SCRIPTS + "/" + LINELISTS[wildcards.linelist_key],
        anchors= NEID_SOLAR_SCRIPTS + "/" + config["params"]["anchors"]
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_ccfs_{{linelist_key}}_{{ccfs_flag_key}}.jld2"
    version: config["CCFS_VERSION"]
    params:
        orders_first=config["params"]["orders_first"],
        orders_last=config["params"]["orders_last"],
        range_no_mask_change=config["params"]["range_no_mask_change"],
        ccfs_flags_value=lambda wildcards:CCFS_FLAGS[wildcards.ccfs_flags_key]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} -t 1 {NEID_SOLAR_SCRIPTS}/examples/calc_order_ccfs_using_continuum_{{version}}.jl {{input.manifest}} {{output}} --line_list_filename {{input.linelist_file}}  --anchors_filename {{input.anchors}}  --orders_to_use={{params.orders_first}} {{params.orders_last}} --range_no_mask_change {{params.range_no_mask_change}} {{params.ccfs_flags_value}} --overwrite")
    
    
rule calc_rvs:
    input:
        ccfs=f"{OUTPUT_DIR}/{{date}}/daily_ccfs_{{linelist_key}}_{{ccfs_flag_key}}.jld2",
        template=NEID_SOLAR_SCRIPTS + "/" + config["params"]["ccf_template"]
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_rvs_{{linelist_key}}_{{ccfs_flag_key}}.csv"
    version: config["RVS_VERSION"]
    params:
        daily_rvs_flags=config["params"]["daily_rvs_flags"]
    run:
        #shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_rvs_v{{version}}.jl {{input.ccfs}} {{output}} {{params.daily_rvs_flags}} ")
        #shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_rvs_v{{version}}.jl {{input.ccfs}} {{output}} --template_file {{input.template}} {{params.daily_rvs_flags}} ")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_rvs_v{{version}}.jl {{input.ccfs}} {{output}} {{input.template}} {{params.daily_rvs_flags}} ")

rule report_daily:
    input:
        rvs=f"{OUTPUT_DIR}/{{date}}/daily_rvs_{{linelist_key}}_{{ccfs_flag_key}}.csv"
        #template=f"{NEID_SOLAR_SCRIPTS}/scripts/template.jld2"
        #manifest=f"{OUTPUT_DIR}/{{date}}/manifest.csv"  # Not implemented yet, but eventually will use extra information from manifest file
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_summary_{{linelist_key}}_{{ccfs_flag_key}}.toml"
    version: config["REPORT_DAILY_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/daily_report_v{{version}}.jl {{input.rvs}} {{output}} ")

rule report_monthly:
    input:
        #expand(f"{OUTPUT_DIR}/{{year}}/{{month}}/{{day}}/daily_summary_{{linelist_key}}_{{ccfs_flag_key}}.toml",year=YEARS,month=MONTHS,day=DAYS)   # Not implemented yet, but eventually could look up info from these.  Need way to exclude days with no data
         glob_wildcards(f"{OUTPUT_DIR}/{{year}}/{{month}}/{{day}}/daily_summary_{{linelist_key}}_{{ccfs_flag_key}}.toml", followlinks=True)
    output:
        f"{OUTPUT_DIR}/{{year}}/{{month}}/monthly_summary_{{linelist_key}}_{{ccfs_flag_key}}.csv"
    version: config["REPORT_MONTHLY_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_reports_v{{version}}.jl {OUTPUT_DIR}/{{year}}/{{month}} {{output}} --input_filename daily_summary_{{linelist_key}}_{{ccfs_flag_key}}.toml --overwrite")

rule report_all:
    input:
        daily_summary = expand(f"{OUTPUT_DIR}/{{date}}/daily_summary_{{linelist_key}}_{{ccfs_flag_key}}.toml", date=DATES, linelist_key=list(LINELISTS.keys()), ccfs_flag_key=list(CCFS_FLAGS.keys()))
    output:
        good=f"{OUTPUT_DIR}/summary_{{linelist_key}}_{{ccfs_flag_key}}.csv",
        bad=f"{OUTPUT_DIR}/summary_incl_bad_{{linelist_key}}_{{ccfs_flag_key}}.csv"
    version: config["REPORT_ALL_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_reports_v{{version}}.jl {OUTPUT_DIR} {{output.good}} --input_filename {{input.daily_summary}} --exclude_filename {EXCLUDE_FILENAME} --overwrite")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_reports_v{{version}}.jl {OUTPUT_DIR} {{output.bad}}  --input_filename {{input.daily_summary}} --overwrite")

rule combine_rvs:
    input:
        daily_rvs = expand(f"{OUTPUT_DIR}/{{date}}/daily_rvs_{{linelist_key}}_{{ccfs_flag_key}}.csv", date=DATES, linelist_key=list(LINELISTS.keys()), ccfs_flag_key=list(CCFS_FLAGS.keys()))
    output:
        good=f"{OUTPUT_DIR}/combined_rvs_{{linelist_key}}_{{ccfs_flag_key}}.csv",
        bad=f"{OUTPUT_DIR}/combined_rvs_incl_bad_{{linelist_key}}_{{ccfs_flag_key}}.csv"
    version: config["COMBINE_RVS_VERSION"]
    run:
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_rvs_{{version}}.jl {OUTPUT_DIR} {{output.good}} --input_filename {{input.daily_rvs}} --exclude_filename {EXCLUDE_FILENAME} --overwrite")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} {NEID_SOLAR_SCRIPTS}/examples/combine_daily_rvs_{{version}}.jl {OUTPUT_DIR} {{output.bad}}  --input_filename {{input.daily_rvs}} --overwrite")
