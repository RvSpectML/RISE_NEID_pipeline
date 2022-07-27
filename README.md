This is an automated snakemake pipeline for NEID data processing.

# Quick-start

## Setup NEID Research Pipeline on your system

### 0.  Setup your account on the system you'll be working from.

-  Make sure you can connect to GitHub (e.g., have account, [ssh keys setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), running `ssh-agent` and `ssh-add`).

-  Make sure julia is installed and in your path (e.g., `module load julia` on Roar).

-  Make sure julia depot is somewhere you'll have sufficient storage space and isn't slow (i.e., not home on Roar).  
```
mkdir /storage/work/USERID/julia_depto; 
ln -s  /storage/work/USERID/julia_depot ~/.julia
```

### 1.  Create/find pipeline_dir 
If you're truely starting from scratch, then create a new pipeline_dir.  (On Roar/Roar Collab, this should be in group storage, not your home directory.)  
If someone else has already setup a pipeline_dir, then just change into it (on Roar Collab, this is `/storage/group/ebf11/default/pipeline/`) and skip to [step 4](#Run-pipeline).
```
$ cd pipeline_dir
```

### 2.  Setup pipeline_dir
If your pipeline_dir is not already prepared, then we set it up to have the following structure in the next few sub-steps:

```
├── data                  (will contain many large data files)
├── NeidSolarScripts.jl   (code to perform the actual analysis)
├── shared                (code with Snakemake pipeline and configuration files)
├── venv                  (provides python environment)
└── work                  (contains subdirectories with configuration files and small input data files for each analysis run)
```

-  Clone the snakemake pipeline and starter configuration files.  Rename the folder to shared.  
(For now, you also need to checkout dev-dshao branch, but that should be removed once its tested and merged.)
```
$ git clone git@github.com:RvSpectML/RISE_NEID_pipeline.git
$ mv RISE_NEID_pipeline shared
$ cd shared
$ git checkout dev-dshao
$ cd ..
```

-  Clone the NeidSolarScripts codes
```
$ git clone git@github.com:RvSpectML/NeidSolarScripts.jl.git
```
 
-  Instantiate the NeidSolarScripts project so that julia downloads and installs dependancies. 
(We temporarily removed Rcall from the Project.toml as R has not been installed on RoarCollab.)

```
$ julia --project=NeidSolarScripts.jl
> import Pkg
> Pkg.instantiate()
> exit()
```

-  Create the data sub-directory (On RoarCollab, its `/storage/group/ebf11/default/pipeline/neid_solar/data`.)
```
$ mkdir data 
```
Copy the following data into the data sub-directory
   - `days_to_exclude.csv` (column name date_to_exclude, entries look like 2021-10-02)
   - `pyrheliometer/*.tel` (keeping pyrheliometer subdirectory; can download those from https://neid.ipac.caltech.edu/pyrheliometer.php; see `NeidSolarScripts.jl/scripts/download_pyrheliometer_tel_files.jl` for download script )
    
 Optionally create parallel data directory on scratch file system and add symlinks to inside the data directory, so L0 files are stored on scratch.  E.g.,
 ```
 mkdir -p /scratch/ebf11/pipeline/neid_solar/data/v1.1/L0;
 cd data
 mkdir v1.1
 cd v1.1
 ln -s /scratch/ebf11/pipeline/neid_solar/data/v1.1/L0 .
 cd ../..
 ```

-  Create a directory to contain workspaces
```
$ mkidr -p work
```

- Create the virtual environment and install packages such as snakemake and pyNeid
```
$ python3 -m venv venv
$ source venv/bin/activate
$ pip install --upgrade pip
$ pip install -r shared/envs/requirements.txt
```

### 3.  Copy data files used for analysis
Copy the following into the NeidSolarScripts.jl folder (**TODO:** probably should move the following to the work directories)

- data/  (**TODO:** Need to clarify what's needed)
- scripts/anchors_*.jld2
- scripts/linelist_*.csv

## Run pipeline
### 4.  Create a workspace for an analysis run.  
If your have userid USERID and a run to be named `test1`, then you would create  
```
$ mkdir -p work/USERID/test1
$ cd work/USERID/test1
```

Copy the template slurm script (`pipeline.slurm`), Snakefile (`Snakefile`) and configuration parameters file (`config.yaml`) into the workspace for your analysis run.
```
$ cp ../../../shared/scripts/slurm/pipeline.slurm .
$ cp ../../../shared/Snakefile .
$ cp ../../../config/config.yaml .
```

Create file nexsci_id.toml in the workspace that includes the username and password for neid.

Create an empty data_paths.jl (`touch data_paths.jl`) in NeidSolarScripts.jl.  (**TODO:** Update make_manifest_solar.jl so it doesn't need this file.  Or if it really does, make it toml file.)

### 5. Update parameters for your analysis run.
 Change the parameters as needed for your run: 
- config.yaml
- pipeline.slurm (see the "UPDATE VARIABLES HERE" section)

### 6.   Submit a slurm job in the workspace  directory
```
$ sbatch pipeline.slurm
```

# Executing the snakemake pipeline

In pipeline.slurm, there is a variable "SUMMARY_REPORT". If SUMMARY_REPORT=0, only steps up to report_daily will be run; if SUMMARY_REPORT=1, additional steps including report_monnthly, report_all annd combine_rvs will also be run.

The report_monnthly step will run for each month between (and including) the input start_date and end_date.

The report_all annd combine_rvs steps will run for all the data in the output folder, regardles of the input start_date and end_date.

Sometimes we need to re-execute the entire or part of the pipeline, while other times we want to avoid unnecessary re-execution. Here we list some common scenarios.

#### Scenario 1. Remove L0 data will not trigger re-execution.

L0 files are large and they are not needed in the steps beyond prep_pyro. To save storage space, we can safely discard the old L0 files that have already been processed. This will not trigger re-execution of the pipeline as long as we do not add the "--forceall" option.

Note that although removing the input file does trigger re-execution, **changes** to the input file will trigger the re-execution of the downstream steps.

#### Scenario 2. Input raw data has been updated and needs to be re-downloaded

The input raw data on https://neid.ipac.caltech.edu/search.php may be updated from time to time. When its swversion is updated to a new major and/or minor version, we may want to download the newer version of data and re-run the pipeline. To do so, set the new swversion in config.yaml, and snakemake will detect the change and re-run the pipeline on all the dates between the given start_date and end_date, including downloading the new version of data and the downstream data processings.

When only the patch version is updated or you simply want to re-run the pipeline, add the "--forceall" option to the snakemake command.

#### Scenario 3. Run with different rules and/or parameter sets

When a rule is updated in the Snakefile, or the parameter used in the rule (either set in the Snakefile directly, passed in from the config file or from the "snakemake --config" command) is changed, that step and all the downstream steps will be re-run. 
