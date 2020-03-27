# PEWO demo №6

## Overview

This demo measures average likelihood of modified trees produced by extending the original tree with placed sequences. 
For each query sequence, an extended tree is being constructed by inserting a new node, thus splitting the most likely
branch according to the placement of the sequence. Then, the likelihood of every extended tree is calculated. 
A reference dataset of bacterial 16S-rRNA barcodes is used.

This example will produce this evaluation from only 100 query reads.
A better analysis would involve thousands of query reads expected to be related to every regions of the reference tree.

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
query_user=`pwd`/examples/6_placement_likelihood/EMP_92_studies_100.fas \
--configfile examples/6_placement_likelihood/config.yaml
```

Execute workflow, using 4 CPU cores:
```
snakemake -p --cores 2 \
--snakefile eval_likelihood.smk \
--config workdir=`pwd`/examples/6_placement_likelihood/run \
query_user=`pwd`/examples/6_placement_likelihood/EMP_92_studies_100.fas \
--configfile examples/6_placement_likelihood/config.yaml
```

## Comments

In this example, 'workdir' and 'query_user' config flags are set
dynamically, as it is required they are passed as absolute paths.
You could also set them manually by editing the config.yaml file
before launch.

Raw results will be written in 'examples/6_placement_likelihood/run'.

Results summaries and plots will be written in
'examples/6_placement_likelihood/run'.

See PEWO wiki for a more detailed explanation of the results:
https://github.com/phylo42/PEWO/wiki/IV.-Tutorials-and-results-interpretation

