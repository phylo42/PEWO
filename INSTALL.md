###############################
# Requirements
###############################

Please make sure 'git' and 'conda' commands are installed on your system.
These are very common software, just browse the web to learn how to install them.

###############################
# INSTALLATION FOR UNIX SYSTEMS
###############################

# clone workflow into working directory
git clone https://address/pewo.git
cd pewo

# install dependencies into an isolated conda environment
conda env create --file environment.yaml

# activate environment
source activate pewo

# edit config as needed
vim config.yaml

# execute workflow to test accuracy
snakemake --snakefile eval_accuray.smk
#OR
# execute workflow to evaluate necessary ressources
snakemake --snakefile eval_ressources.smk
