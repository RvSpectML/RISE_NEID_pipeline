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
    - days_to_exclude.csv (column name date_to_exclude, entries look like 2021-10-02)
    - neid_solar/pyrheliometer/*.tel  (Can download from https://neid.ipac.caltech.edu/pyrheliometer.php )

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
- scripts/template.jld2

## Run pipeline
### 4.  Create a workspace for an analysis run.  
If your run is named `test1`, then you would create  
```
$ mkidr -p work/test1
$ cd work/test1
```

Copy the template slurm script (`pipeline.slurm`), Snakefile (`Snakefile`) and configuration parameters file (`config.yaml`) into the workspace for your analysis run.
```
$ cp ../../shared/scripts/slurm/pipeline.slurm .
$ cp ../../shared/Snakefile .
$ cp ../../config/config.yaml .
```

### 5. Update parameters for your analysis run.
 Change the parameters as needed for your run: 
- config.yaml
- pipeline.slurm (see the "UPDATE VARIABLES HERE" section)

### 6.   Submit a slurm job in the workspace  directory
```
$ sbatch pipeline.slurm
```
