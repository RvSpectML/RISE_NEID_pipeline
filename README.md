This is an automated snakemake pipeline for NEID data processing.

# Quick-start

## Setup NEID Research Pipeline on your system

### 0.  Setup your account on the system you'll be working from.

-  Make sure you can connect to GitHub (e.g., have account, [ssh keys setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), running `ssh-agent` and `ssh-add`).

-  Make sure julia is installed and in your path (e.g., `module load julia` on Roar).

-  Make sure julia depot is somewhere you'll have sufficient storage space and isn't slow (i.e., not home on Roar).  
```
mkdir /storage/work/USERID/julia_depot; 
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
├── shared                  (code with Snakemake pipeline and configuration files)
├── venv                    (provides python environment)
├── neid_solar
|   ├── NeidSolarScripts.jl (code to perform the actual analysis)
|   ├── data                (will contain many large data files)
|   └── work                (copy neid_solar workflow files here and submit jobs)
└── neid_night 
    ├── data                (will contain many large data files)
    └── work                (copy neid_night workflow files here and submit jobs)
```

- Clone the snakemake pipeline and starter configuration files.  Rename the folder to shared.  

```
$ git clone git@github.com:RvSpectML/RISE_NEID_pipeline.git
$ mv RISE_NEID_pipeline shared
```

- Create the virtual environment and install packages such as snakemake and pyNeid

```
$ python3 -m venv venv
$ source venv/bin/activate
$ pip install --upgrade pip
$ pip install -r shared/envs/requirements.txt
```

## Set up neid_solar sub-folder in pipeline_dir

```
$ mkdir neid_solar
$ cd neid_solar
```

### 1.  Clone the NeidSolarScripts codes
```
$ git clone git@github.com:RvSpectML/NeidSolarScripts.jl.git
```
 
Instantiate the NeidSolarScripts project so that julia downloads and installs dependancies. 
(We temporarily removed Rcall from the Project.toml as R has not been installed on RoarCollab.)

```
$ julia --project=NeidSolarScripts.jl
> import Pkg
> Pkg.instantiate()
> exit()
```
Copy the following into the NeidSolarScripts.jl folder (**TODO:** probably should move the following to the work directories)

- scripts/data/linelist_*.csv

### 2.  Create the data sub-directory 

(On RoarCollab, its `/storage/group/ebf11/default/pipeline/neid_solar/data`.)

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

### 3.  Create a directory to contain workspaces

```
$ mkidr -p work
```

## Set up neid_night sub-folder in pipeline_dir

```
$ mkdir neid_night
$ cd neid_night
```

### 1.  Create the data sub-directory 

(On RoarCollab, its `/storage/group/ebf11/default/pipeline/neid_night/data`.)

```
$ mkdir data 
```

### 2.  Create a directory to contain workspaces

```
$ mkidr -p work
```


## Run pipeline

It's very similar to run neid_solar and neid_night jobs. We will take neid_solar as an example unless otherwise noted.

### 1.  Create a workspace for an analysis run.  
If your have userid USERID and a run to be named `test1`, then you would create  
```
$ mkdir -p work/USERID/test1
$ cd work/USERID/test1
```

Copy the template slurm script (`pipeline.slurm`), Snakefile (`Snakefile`) and configuration parameters file (`config.yaml`) into the workspace for your analysis run.
```
$ cp ../../../../shared/job_submission/slurm/pipeline.slurm .
```
and either
```
$ cp ../../../../shared/neid_solar_workflow/Snakefile .
$ cp ../../../../shared/neid_solar_workflow/config.yaml .
```
or
```
$ cp ../../../../shared/neid_night_workflow/Snakefile .
$ cp ../../../../shared/neid_night_workflow/config.yaml .
```

Create file nexsci_id.toml in the workspace that includes the username and password for neid. 
For running a neid_night job, you will also want to generate file cookie in the workspace.

Create an empty data_paths.jl (`touch data_paths.jl`) in NeidSolarScripts.jl.  (**TODO:** Update make_manifest_solar.jl so it doesn't need this file.  Or if it really does, make it toml file.)

### 2. Update parameters for your analysis run.
 Change the parameters as needed for your run: 
- config.yaml
- pipeline.slurm (see the "UPDATE VARIABLES HERE" section)

### 3.   Submit a slurm job in the workspace  directory
```
$ sbatch pipeline.slurm
```

# Executing the snakemake pipeline

#### Separate workspace and half-shared data repository for different users

Each user should create their own workspace, and within their workspace, they can furtheer create subfolders for different runs, e.g. PIPELINE_ROOT/work/USERID/test1. The user then copy Snakefile, config.yaml and pipeline slurm/shell script from the shared repository to this folder, and make changes to the files in their own folder. File nexsci_id.toml that includes the username and password for neid might also be needed here.

Once snakemake is started, .snakemake will be created in this work subfolder that keeps track of the snakemake jobs. A lock will be placed when a snakemake pipeline is running, and no other runs are allowed in this subfolder. However, users can start another run in a different workspace as long as the output files will not interfere with each other (see below).

The L0/L2 data, pyrheliometer files and manifest files are relatively stable and once created, they can be shared between different users and different pipeline runs.

- data/INPUT_VERSION/L0/

- data/INPUT_VERSION/L2/

- data/INPUT_VERSION/pyrheliometer/

- data/INPUT_VERSION/manifest/

The downstream analysis often varies with different parameter sets, so we put those outputs in specific USER_ID and PIPELINE_ID subfolders. 

- data/INPUT_VERSION/outputs/USER_ID/PIPELINE_ID/

In this way different users can run their own versions of downstream analysis without interfering each other. 

#### Pipeline mode: DAILY vs SUMMARY

In pipeline.slurm, there is a variable "PIPELINE_MODE". 

If PIPELINE_MODE=DAILY, daily data will be downloaded and processed for each day between the given start_date and end_date. Specifically, this mode includes downloding L0/L2 data, generating pyrheliometer and manifest files, calculating ccfs and rvs, and generating daily reports.

If PIPELINE_MODE=SUMMARY, steps that generate summary reports, including report_monnthly, report_all annd combine_rvs, will be run. The report_monnthly runs on each month between (and including) the given start_date and end_date. The report_all and combine_rvs steps run on all the data in the output folder, regardles of the given start_date and end_date.

Sometimes we need to re-execute the entire or part of the pipeline, while other times we want to avoid unnecessary re-execution. Here we list some common scenarios.

#### Scenario 1. Remove L0 data will not trigger re-execution.

L0 files are large and they are not needed in the steps beyond prep_pyro. To save storage space, we can safely discard the old L0 files that have already been processed. This will not trigger re-execution of the pipeline as long as we do not add the "--forceall" option.

Note that although removing the input file of a rule does not trigger re-execution, **changes** to the input file will trigger the re-execution of the downstream steps.

#### Scenario 2. Input raw data has been updated and needs to be re-downloaded

The input raw data on https://neid.ipac.caltech.edu/search.php may be updated from time to time. When its swversion is updated to a new major and/or minor version, we may want to download the newer version of data and re-run the pipeline. To do so, set the new swversion in config.yaml, and snakemake will detect the change and re-run the pipeline on all the dates between the given start_date and end_date, including downloading the new version of data and the downstream data processings.

When only the patch version is updated or you simply want to re-run the pipeline, add the "--forceall" option to the snakemake command.

#### Scenario 3. Run with different rules and/or parameter sets

When a rule is updated in the Snakefile, or the parameter used in the rule (either set in the Snakefile directly, passed in from the config file or from the "snakemake --config" command) is changed, that step and all the downstream steps will be re-run the next time snakemake is run.  The updates will only occur for dates within the date range specified.  If the date range specified does not include previous dates, then the output files would be a mix of output files generated with the old and new rules/parameters.   To prevent the risk of this, when after changing a rule or pipeline parameter, one should generally run the pipeline with the full date range to make sure all affected outputs get updated.
