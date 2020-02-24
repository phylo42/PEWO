# PEWO Example n°1 : Fast test of Accuracy procedure

## Overview

This demo measures placement accuracy in terms of Node Distance (ND)
and expected Node Distance (eND)for a reference dataset
of 150 16S-rRNA barcodes.

EPA-ng, PPlacer and RAPPAS are run using only their default parameters.
Only 3 pruning are launched, to produce results rapidly in ~20 minutes.

A better analysis would ask for >50 prunings; to generate a wide
range of topologies (1 leaf pruned, large clades pruned, ...).


## How to launch

Download pipeline.
```
git clone --recursive https://github.com/blinard-BIOINFO/PEWO_workflow.git 
cd PEWO_workflow
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
--config workdir=`pwd`/demos/16SrRNA_accuracy_test/run \
--configfile demos/16SrRNA_accuracy_test/config.yaml
```

Execute workflow, using 2 CPU cores.
```
snakemake -p --cores 2 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/demos/16SrRNA_accuracy_test/run \
--configfile demos/16SrRNA_accuracy_test/config.yaml
```

## Comments

In this example, 'workdir' and 'query_user' config flags are set
dynamically, as it is required they are passed as absolute paths.
You could also set them manually by editing the config.yaml file
before launch.

Raw results will be written in
'demos/16SrRNA_accuray_test/run/benchmark'.

Results summaries and plots will be written in
'demos/16SrRNA_accuracy_test/run'.

See PEWO wiki for a more detailed explanation of the results:
https://github.com/blinard-BIOINFO/PEWO_workflow/wiki/Tutorials-and-results-interpretation
