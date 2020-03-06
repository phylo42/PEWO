#!/bin/bash

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

export PATH="$CONDA_DIR/bin:$PATH"
conda activate PEWO

# Run the fast accuracy example
snakemake -p \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/travis/tests/1_travis_accuracy_test/run \
--configfile travis/tests/1_travis_accuracy_test/config.
