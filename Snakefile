from os import listdir

ROOT_DIR = "/storage/home/dus73/scratch"
MODULE_DIR = f"{ROOT_DIR}/sw/modules/"
JULIA_VERSION = "1.6.2"
NEID_SOLAR_SCRIPTS = f"{ROOT_DIR}/original_neid/code/NeidSolarScripts.jl"
INPUT_DIR = f"{ROOT_DIR}/NEID/data/solar_L1/v1.0.0"
OUTPUT_DIR = f"{ROOT_DIR}/NEID/data/output"
DATES = listdir(INPUT_DIR)


rule all:
    input:
        expand(f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2", date=DATES)


rule manifest:
    input:
        f"{INPUT_DIR}/{{date}}/"
    output:
        f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        f"{OUTPUT_DIR}/{{date}}/manifest_calib.csv"
    run:
        shell(f"module use {MODULE_DIR}")
        shell(f"module load julia/{JULIA_VERSION}")
        shell(f"mkdir {OUTPUT_DIR}/{{wildcards.date}}")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} -e 'target_subdir=\"{{input}}\"; output_dir=\"{OUTPUT_DIR}/{{wildcards.date}}\";  include(\"{NEID_SOLAR_SCRIPTS}/scripts/make_manifest_solar_1.0.0.jl\")'")


rule ccfs:
    input:
        manifest=f"{OUTPUT_DIR}/{{date}}/manifest.csv",
        linelist=f"{NEID_SOLAR_SCRIPTS}/scripts/linelist_20210208.csv",
        sed=f"{NEID_SOLAR_SCRIPTS}/data/neidMaster_HR_SmoothLampSED_20210101.fits",
        anchors=f"{NEID_SOLAR_SCRIPTS}/scripts/anchors_20210305.jld2"        
    output:
        f"{OUTPUT_DIR}/{{date}}/daily_ccfs_1.jld2"
    params:
        orders_first=56,
        orders_last=108,
        range_no_mask_change=6.0
    run:
        shell(f"module use {MODULE_DIR}")
        shell(f"module load julia/{JULIA_VERSION}")
        shell(f"julia --project={NEID_SOLAR_SCRIPTS} -t 1 {NEID_SOLAR_SCRIPTS}/examples/calc_order_ccfs_using_continuum_1.0.0.jl {{input.manifest}} {{output}} --line_list_filename {{input.linelist}} --sed_filename {{input.sed}}  --anchors_filename {{input.anchors}}  --orders_to_use={{params.orders_first}} {{params.orders_last}} --range_no_mask_change {{params.range_no_mask_change}}  --apply_continuum_normalization  --variable_mask_scale  --overwrite")
    
