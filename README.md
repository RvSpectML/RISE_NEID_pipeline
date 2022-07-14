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

Create an empty data_paths.jl (`touch data_paths.jl`).  (**TODO:** Update make_manifest_solar.jl so it doesn't need this file.  Or if it really does, make it toml file.)

### 5. Update parameters for your analysis run.
 Change the parameters as needed for your run: 
- config.yaml
- pipeline.slurm (see the "UPDATE VARIABLES HERE" section)

### 6.   Submit a slurm job in the workspace  directory
```
$ sbatch pipeline.slurm
```
