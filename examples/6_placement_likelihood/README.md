# PEWO demo №5: Placement likelihood evaluation

## Overview

This demo measures average likelihood of modified trees produced by extending the original tree with placed sequences. 
For each query sequence, an extended tree is being constructed by inserting a new node, thus splitting the most likely branch according to the placement of the sequence.
Then, the likelihood of every extended tree is calculated. 
The reference dataset of 16S-rRNA barcodes is used.

## How to launch

Download pipeline:
```
git clone --recursive https://github.com/phylo42/PEWO.git
cd PEWO
```

Execute installation script:
```
chmod u+x INSTALL.sh
./INSTALL.sh
```

Load the environement:
```
conda activate PEWO
```

Test the workflow:
```
snakemake -np \
--snakefile eval_likelihood.smk \
--config workdir=`pwd`/examples/6_placement_likelihood/run \
query_user=`pwd`/examples/6_placement_likelihood/EMP_92_studies_1000.fas \
--configfile examples/6_placement_likelihood/config.yaml
```

Execute workflow, using 4 CPU cores:
```
snakemake -p --cores 4 \
--snakefile eval_likelihood.smk \
--config workdir=`pwd`/examples/6_placement_likelihood/run \
query_user=`pwd`/examples/6_placement_likelihood/EMP_92_studies_1000.fas \
--configfile examples/6_placement_likelihood/config.yaml
```
