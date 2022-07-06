This is an automated snakemake pipeline for NEID data processing.

# Quick-start

0.  Setup your account on the system you'll be working from.
0a.  Make sure you can connect to GitHub (e.g., have account, [ssh keys setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), running `ssh-agent` and `ssh-add`).
0b.  Make sure julia is installed and in your path (e.g., `module load julia` on Roar).
0c.  Make sure julia depot is somewhere you'll have sufficient storage space and isn't slow (i.e., not home on Roar).  
```
mkdir /storage/work/USERID/julia_depto; 
ln -s  /storage/work/USERID/julia_depot ~/.julia
```

1.  If you're truely starting from scratch, then create a new pipeline_dir.  (On Roar/Roar Collab, this should be in group storage, not your home directory.)  If someone else has already setup a pipeline_dir, then just change into it.
```
$ cd pipeline_dir
```

2.  Now we'll prepare the pipeline_dir following the below structure:

```
├── data 
├── NeidSolarScripts.jl
├── shared
├── venv
└── work
```

2a.  Clone the snakemake pipeline codes and rename the folder to shared
```
$ git clone git@github.com:RvSpectML/RISE_NEID_pipeline.git
$ mv RISE_NEID_pipeline shared
```

2b.  Clone the NeidSolarScripts codes
```
$ git clone git@github.com:RvSpectML/NeidSolarScripts.jl.git
```

2c.  Instantiate the NeidSolarScripts project. (I temporarily commented out Rcall on RoarCollab as R has not been installed there)

```
$ julia --project=NeidSolarScripts.jl
> import Pkg
> Pkg.instantiate()
> exit()
```

2d.  Prepare the data directory (On RoarCollab, I'm linking it to scratch for now.)
```
$ mkdir data 
```

Copy the follwoing data to the data directory
- days_to_exclude.csv
- neid_solar/pyrheliometer/

Create the virtual environment and install packages such as snakemake and pyNeid
```
$ python3 -m venv venv
$ source venv/bin/activate
$ pip install --upgrade pip
$ pip install -r shared/envs/requirements.txt
```

Copy the following data to the NeidSolarScripts.jl folder
- data/
- scripts/anchors_*.jld2
- scripts/linelist_*.csv
- scripts/template.jld2

Create a workspace
```
$ mkidr -p work/test1
$ cd work/test1
```

Copy over the slurm script, Snakefile and config.yaml
```
$ cp ../../shared/scripts/slurm/pipeline.slurm .
$ cp ../../shared/Snakefile .
$ cp ../../config/config.yaml .
```

Change the parameters as needed: 
- config.yaml
- pipeline.slurm: the "UPDATE VARIABLES HERE" section

submit the job in the work/test1 directory
```
$ sbatch pipeline.slurm
```
