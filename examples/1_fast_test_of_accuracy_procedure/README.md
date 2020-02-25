# PEWO Example n°1 : Fast test of Accuracy procedure

## Overview

This demo measures placement accuracy in terms of Node Distance (ND)
and expected Node Distance (eND)for a reference dataset
of 150 16S-rRNA barcodes.

EPA-ng, PPlacer and RAPPAS are run using only their default parameters.
Only 2 pruning are launched, to rapidly produce results in less than
20 minutes.

A better analysis would require for >50 prunings to generate a wide
range of topologies (1 leaf pruned, large clades pruned, ...).


## How to launch

Download pipeline.
```
git clone --recursive https://github.com/phylo42/PEWO.git
cd PEWO
```

Execute installation script
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
--config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
--configfile examples/1_fast_test_of_accuracy_procedure/config.yaml
```

Execute workflow, using 1 CPU core.
```
snakemake -p --cores 1 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
--configfile examples/1_fast_test_of_accuracy_procedure/config.yaml
```

## Comments

In this example, 'workdir' and 'query_user' config flags are set
dynamically, as it is required they are passed as absolute paths.
You could also set them manually by editing the config.yaml file
before launch.

Raw results will be written in
'examples/1_fast_test_of_accuracy_procedure/run'.

Results summaries and plots will be written in
'examples/1_fast_test_of_accuracy_procedure/run'.

See PEWO wiki for a more detailed explanation of the results:
https://github.com/blinard-BIOINFO/PEWO/wiki/Tutorials-and-results-interpretation
