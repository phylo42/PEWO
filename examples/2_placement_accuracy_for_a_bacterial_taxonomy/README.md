# PEWO demo n°2

## Overview

This demo measures placement accuracy in terms of Node Distance (ND)
and expected Node Distance (eND) for a reference dataset
of 150 16S-rRNA barcodes.

EPA-ng, PPlacer, RAPPAS and Apples are tested.

Only 10 prunings are executeed and for a set of parameters in each program.
This analysis will require around 2 hours of computation.

A better analysis would require for >50 prunings to generate a wide
range of topologies (1 leaf pruned, large clades pruned, ...).


## How to run the pipeline
Download the pipeline.
``` bash
git clone --recursive https://github.com/phylo42/PEWO.git
cd PEWO
```

Execute the installation script
``` bash
chmod u+x INSTALL.sh
./INSTALL.sh
```

After installation, load the environment.
``` bash
conda activate PEWO
```

Test workflow before execution.
``` bash
snakemake -np \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/2_placement_accuracy_for_a_bacterial_taxonomy/run \
--configfile examples/2_placement_accuracy_for_a_bacterial_taxonomy/config.yaml
```

Execute workflow using 2 CPU cores.
``` bash
snakemake -p --cores 2 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/2_placement_accuracy_for_a_bacterial_taxonomy/run \
--configfile examples/2_placement_accuracy_for_a_bacterial_taxonomy/config.yaml
```

## Comments

In this example, `workdir` and `query_user` config flags are set
dynamically, as it is required they are passed as absolute paths.
You could also set them manually by editing the `config.yaml`  file
before execution.

Raw results will be written in
`examples/2_placement_accuracy_for_a_bacterial_taxonomy/run`.

Results summaries and plots will be written in
`examples/2_placement_accuracy_for_a_bacterial_taxonomy/run`.

See PEWO wiki for a more detailed explanation of the results:
https://github.com/phylo42/PEWO/wiki/IV.-Tutorials-and-results-interpretation
