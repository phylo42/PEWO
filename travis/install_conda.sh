#!/bin/bash

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

# Install conda
sudo apt-get update
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh;
bash miniconda.sh -b -p $CONDA_DIR -u
source "$CONDA_DIR/etc/profile.d/conda.sh"
hash -r

conda config --set always_yes yes --set changeps1 no
conda update -q conda
# Useful for debugging any issues with conda
conda info -a

# Add channels
conda config --add channels defaults
conda config --add channels conda-forge
conda config --add channels bioconda

# Create the environment. Takes time
conda env create -f "$TRAVIS_BUILD_DIR"/envs/environment.yaml
conda activate PEWO
