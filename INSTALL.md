###############################
# Requirements
###############################

Please make sure 'git' and 'conda' commands are installed on your system.
These are very common software, just browse the web to learn how to install them.

###############################
# INSTALLATION FOR UNIX SYSTEMS
###############################

# clone workflow into working directory
git clone https://bitbucket.org/user/myworkflow.git path/to/workdir
cd path/to/workdir

# install dependencies into an isolated conda environment
conda env create -n placetest_workflow --file environment.yaml

# activate environment
source activate placetest_workflow

# edit config as needed
vim config.yaml

# execute workflow
snakemake -n