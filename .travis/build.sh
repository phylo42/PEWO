#!/bin/bash

source activate PEWO

# Make sure that the master branch works fine, running the example pipelines.
# For other branches just run snakemake in dry-run mode for speed
if [[ "$TRAVIS_BRANCH" == "master" ]]
then
    # Run the fast accuracy example
    snakemake -p \
    --snakefile `pwd`/eval_accuracy.smk \
    --config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
    --configfile `pwd`/examples/1_fast_test_of_accuracy_procedure/config.yaml
else
    # dry-run of the accuracy pipeline
    snakemake -np \
    --snakefile `pwd`/eval_accuracy.smk \
    --config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
    --configfile `pwd`/examples/1_fast_test_of_accuracy_procedure/config.yaml

    # dry-run of the resourses pipeline
    snakemake -np \
    --snakefile `pwd`/eval_resources.smk \
    --config workdir=`pwd`/examples/5_CPU_RAM_requirements_evaluation/run query_user=`pwd`/examples/5_CPU_RAM_requirements_evaluation/EMP_92_studies_100000.fas \
    --configfile `pwd`/examples/5_CPU_RAM_requirements_evaluation/config.yaml
fi