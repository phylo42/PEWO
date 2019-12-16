# PEWO: "Pacement Evaluation WOrkflow"

## Overview

PEWO is a worflow designed to evaluate phylogenetic placement algorithms and their software implementation in terms of placement accuracy and computationnal requirements.
It is built on Snakemake + Miniconda3 and rely extensively on the Bioconda repository, making it portable to most OS supporting Python 3 (a particular phylogenetic placement software can be tested as long as it is compatible with said OS).

**The main goals of PEWO are:**

1. Evaluate how accurate will be the phylogenetic placements produced by current methods, given a particular reference species tree (and corresponding reference alignment), 

2. Search which parameter combination produces the most accurate placement or the most scalable analysis, in terms of CPU and memory consumption.

3. Facilitate the benchmarking of any novel phylogenetic placement algorithm that will be developped in the future and standardize its comparison to existing methods.

**Currently, PEWO implements the following tests:**

* *Node Distance (ND)* test : This procedure was used in the original papers of the following software:
The reference tree is pruned randomly. For each pruning the pruned leaves are placed and accuracy is evaluated as the number of nodes separating expected and observed placements.

* *Expected Node Distance (eND)* test : This is a modified version of the ND distance, which takes into account, for each placement, the distribution of the Likelihood Weight Ratios. 

* *Likelihood Improvement (LI)* test : This procedure is designed for rapid evaluation of phylogenetic placements during developement stages. Following any new condition (change in algorithm or parameters), it tests if placements are resulting to trees with improved likelihood.

* *Ressources (RESS)* test : Measured CPU and peek RAM consumption at every steps required for pylogenetic placement (including query alignment in alignment-based methods and ancestral state reconstruction + database build in alignment-free methods). This test mostly intend to evaluate the scalability of the methods, depending on your usage of phylogenetic placement (punctual analyses or routine placement of large sequence volumes). 

**Currently, the following software can be tested in PEWO.**

* EPA(RAxML)  (Berger et al, 2011) 
* PPlacer     (Matsen et al, 2011)
* EPA-ng      (Barbera et al, 2019)
* RAPPAS      (Linard et al, 2019)
* APPLES      (Balaban et al, 2019)

If you wish to test you own, unpublished new phylogenetic placement software, you are welcome to code a new snakemake module and contribute to PEWO via pull requests.

## Wiki documentation

An complete documentation, including a tutorial is available in the wiki section of this github repository.

## Installation

### Requirements

Python 3 and Miniconda 3 needs to be installed on your system and the 'conda' command ust be accessible to the user running the workflow.

'''
wget [url miniconda 3]
./miniconda3
'''

If your Miniconda3 installation was successfull, you should be able to run the following command:
'''
'''


### Rapid installation

'''
#add conda repositories
conda config add channels bioconda

#install PEWO environment
conda env create -f envs/environement.yaml
'''

# Usage

1. Activate PEWO environement:

'''
conda activate PEWO
'''

Note that anaconda will always install the latest software version of all phylogenetic placement software supported by PEWO.
If you intend to test a particular version, you will need to manually downgrade to earlier versions, for instance:
'''
conda activate PEWO
#removes the latest version of pplacer and downgrades to earlier version:
conda remove pplacer
conda install pplacer=
'''

2. Setup the pipeline configuration by editing the config.yaml file. 

3. Choose and execute your workflow

First, it is strongly recommended to test if your configuration is valid and matches your needs.
To do so, launch a dry run of the pipeline using the command

'''
snakemake --snakefile \[subworkflow\].smk -np --core 1 --config pruning_count=1
'''

where \[subworkflow\] is one of the subworflow listed in the table below. This will list the operations that will be run by the workflow

Table with possible analyses

Moreover, you can produce a graph detailling the different steps of the workflow.

'''
# to display the graph in a window
snakemake --snakefile \[subworkflow\].smk --config pruning_count=1 --dag | dot | display

# to produce an image of the graph
snakemake --snakefile \[subworkflow\].smk --config pruning_count=1 --dag | dot -Tsvg > graph.svg
'''


## Licence


