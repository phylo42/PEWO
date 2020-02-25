#!/bin/bash

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

# Miniconda restored from cache
if [ -d "$MINICONDA_DIR" ] && [ -e "$MINICONDA_DIR/bin/conda" ]; then
    echo "Miniconda install already present from cache: $MINICONDA_DIR"
    export PATH="$MINICONDA_DIR/bin:$PATH"
    hash -r
# Install Miniconda from scratch
else
    # remove cache
    rm -rf "$MINICONDA_DIR"

    # Install conda
    sudo apt-get update
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh;
    bash miniconda.sh -b -p $HOME/miniconda -u
    export PATH="$HOME/miniconda/bin:$PATH"
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
fi
