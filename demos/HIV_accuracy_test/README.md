# PEWO demo n°1

## Overview

This demo measures placement accuracy in terms of Node Distance (ND)
and expected Node Distance (eND)for a reference dataset
of 150 16S-rRNA barcodes.

EPA-ng, PPlacer, RAPPAS and Apples are tested.

Only 10 pruning are launched and a limited set of parameters is tested.
This analysis will require around 2 hours of computation.

A better analysis would ask for >50 prunings; to generate a wide
range of topologies (1 leaf pruned, large clades pruned, ...).


## How to launch

``̀
#Download pipeline
git clone https://github.com/blinard-BIOINFO/PEWO_workflow.git 
cd PEWO_workflow

#Install PEWO environment (may take some time...)
conda env create -f envs/environement.yaml

#Load environement
conda activate PEWO

#Test workflow before launch
snakemake -np \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/demos/16SrRNA_accuracy_test/run \
--configfile demos/16SrRNA_accuracy_test/config.yaml

#Execute workflow, using 4 CPU cores
snakemake -p --cores 4 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/demos/16SrRNA_accuracy_test/run \
--configfile demos/16SrRNA_accuracy_test/config.yaml
```

## Comments

Not that in this example, 'workdir' flag is set dynamically
as it is required to be an absolute path.
But you could also set it manually by editing the config.yaml file.

Results will be written in 'demos/16SrRNA_accuracy_test/run' .

-summary_table_*.csv : ND or eND measured for each parameter combination.
-summary_plot_*.svg :  Same values plotted for easier comparison.

See PEWO tutorial n°1 for a more detailed explanation of the results.