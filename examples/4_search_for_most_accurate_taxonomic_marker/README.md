# PEWO demo n°2

## Overview

This demo measures placement accuracy in terms of Node Distance (ND)
and expected Node Distance (eND) for two different reference trees
based on the same 1000 coleopteran mitochondria but two different loci
in the 12S and 16S rRNA genes.

Two accuracy procedures are launched independantly on each locus.
The goal is to compare placement accuray measured for each locus and
deduce which reference tree appears to be a better reference for future
placements based on mitochondrial reads of either the 12S or 16S gene. 

EPA-ng, PPlacer, RAPPAS are tested with default parameters.

Only 10 pruning are launched and for a set of parameters in each program.
This analysis will require around 2 hours of computation.

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
--config workdir=`pwd`/examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_12S/run \
--configfile examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_12S/config_12S.yaml

snakemake -np \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_16S/run \
--configfile examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_16S/config_16S.yaml
```

Execute workflow for 12S gene, using 2 CPU cores.
```
snakemake -p --cores 2 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_12S/run \
--configfile examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_12S/config_12S.yaml
```

Execute workflow for 16S gene, using 2 CPU cores.
```
snakemake -p --cores 2 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_16S/run  \
--configfile examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_16S/config_16S.yaml
```



## Comments

In this example, 'workdir' and 'query_user' config flags are set
dynamically, as it is required they are passed as absolute paths.
You could also set them manually by editing the config.yaml file
before launch.

Raw results will be written in
'examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_16S/run'
'examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_12S/run'

Results summaries and plots will be written in
'examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_16S/run'
'examples/4_search_for_most_accurate_taxonomic_marker/coleoptera_12S/run'

See PEWO wiki for a more detailed explanation of the results:
https://github.com/blinard-BIOINFO/PEWO/wiki/Tutorials-and-results-interpretation
