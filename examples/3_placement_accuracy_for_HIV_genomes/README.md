# PEWO demo n°1

## Overview

This demo measures placement accuracy in terms of Node Distance (ND)
and expected Node Distance (eND)for a reference dataset
of 104 HIV complete genomes.

EPA-ng, PPlacer, RAPPAS are tested.

Only 10 pruning are launched and only default parameters are tested.
This analysis will require around 1 hours of computation.

A better analysis would ask for >50 prunings; to generate a wide
range of topologies (1 leaf pruned, large clades pruned, ...).


## How to launch

Download pipeline.
```
git clone --recursive https://github.com/phylo42/PEWO.git
cd PEWO
```

Execute installation script.
```
chmod u+x INSTALL.sh
./INSTALL.sh
```

After installation, load environement.
```
conda activate PEWO
```

Test workflow before launch.
```
snakemake -np \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/3_placement_accuracy_for_HIV_genomes/run \
--configfile examples/3_placement_accuracy_for_HIV_genomes/config.yaml
```

Execute workflow, using 2 CPU cores.
```
snakemake -p --cores 2 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/3_placement_accuracy_for_HIV_genomes/run \
--configfile examples/3_placement_accuracy_for_HIV_genomes/config.yaml
```

## Comments

In this example, 'workdir' and 'query_user' config flags are set
dynamically, as it is required they are passed as absolute paths.
You could also set them manually by editing the config.yaml file
before launch.

Raw results will be written in
'examples/3_placement_accuracy_for_HIV_genomes/run'.

Results summaries and plots will be written in
'examples/3_placement_accuracy_for_HIV_genomes/run'.

See PEWO wiki for a more detailed explanation of the results:
https://github.com/phylo42/PEWO/wiki/IV.-Tutorials-and-results-interpretation
