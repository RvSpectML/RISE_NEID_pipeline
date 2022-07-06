This is an automated snakemake pipeline for NEID data processing.

# Quick-start

```
$ cd pipeline_dir
```

Now we'll prepare the pipeline_dir following the below structure:

```
├── data 
├── NeidSolarScripts.jl
├── shared
├── venv
└── work
```

Clone the snakemake pipeline codes and rename the folder to shared
```
$ git clone https://github.com/RvSpectML/RISE_NEID_pipeline.git
$ mv RISE_NEID_pipeline shared
```

Clone the NeidSolarScripts codes
```
$ git clone https://github.com/RvSpectML/NeidSolarScripts.jl.git
```

Copy the following data to the NeidSolarScripts.jl folder
- data/
- scripts/anchors_*.jld2
- scripts/linelist_*.csv
- scripts/template.jld2

Instantiate the NeidSolarScripts project. (I temporarily commented out Rcall on RoarCollab as R has not been installed there)

```
$ julia --project=NeidSolarScripts.jl
> import Pkg
> Pkg.instantiate()
> exit()
```
Prepare the data directory (On RoarCollab, I'm linking it to scratch for now.)
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
