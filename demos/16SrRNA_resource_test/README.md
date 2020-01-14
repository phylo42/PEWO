# PEWO demo n°2 : Resource evaluation

## Overview

This demo measures CPU/RAM/TIME resources consumed by the different
placement softwares, using a reference dataset of 16S-rRNA barcodes.

EPA-ng, PPlacer, RAPPAS are tested.
Each measure is repeated 3 times.
This analysis will require around 4 hours of computation.

Final measures are reported as the mean of the repeats.
Consequently, increasing repeats should improve the evaluation.

## How to launch

Download pipeline.
```
git clone https://github.com/blinard-BIOINFO/PEWO_workflow.git 
cd PEWO_workflow
```

Install PEWO environment (may take some time...).
```
conda env create -f envs/environement.yaml
```

Load environement.
```
conda activate PEWO
```

Test workflow before launch.
```
snakemake -np \
--snakefile eval_resources.smk \
--config workdir=$(pwd)/demos/16SrRNA_resource_test/run \
query_user=`pwd`/demos/16SrRNA_resource_test/EMP_92_studies_100000.fas \
--configfile demos/16SrRNA_accuracy_test/config.yaml
```

Execute workflow, using 4 CPU cores.
```
snakemake -p --cores 4 \
--snakefile eval_resources.smk \
--config workdir=$(pwd)/demos/16SrRNA_resource_test/run \
query_user=`pwd`/demos/16SrRNA_resource_test/EMP_92_studies_100000.fas \
--configfile demos/16SrRNA_resource_test/config.yaml
```

## Comments

In this example, 'workdir' and 'query_user' config flags are set
dynamically, as it is required they are passed as absolute paths.
You could also set them manually by editing the config.yaml file
before launch.

Raw results will be written in
'demos/16SrRNA_resource_test/run/benchmark'.

Results summaries and plots will be written in
'demos/16SrRNA_resource_test/run'.

See PEWO wiki for a more detailed explanation of the results:
https://github.com/blinard-BIOINFO/PEWO_workflow
