# PEWO: "Pacement Evaluation WOrkflow"

## Overview

PEWO is a worflow designed to evaluate phylogenetic placement algorithms and their software implementation in terms of placement accuracy and associated computational costs.
It is built on *Snakemake* + *Miniconda3* and rely extensively on the *Bioconda* repository, making it portable to most OS supporting Python 3. A particular phylogenetic placement software can be tested as long as it is compatible with said OS.

**Main goals of PEWO :**

1. Evaluate phylogenetic placement accuracy, given a particular reference species tree (and corresponding reference alignment). For instance, one can run PEWO on different trees built for different taxonomic marker genes.

2. Given a particular software,/algorithm, empirically explore which parameters produces the most accurate placements and for which computational cost. Indeed, depending on the volume of sequence data to place, one may need to find the best balance between placement accuracy and scalability (CPU/RAM requirements).

3. For developpers, facilitate the benchmarking and comparison of any novel phylogenetic placement algorithm to existing methods, removing the hassle to implement evaluation protocols used in previous manuscripts.

**Procedures currently implemented in PEWO :**

* *Node Distance (ND)* : 
This procedure was used in the original papers of the following software:
The reference tree is pruned randomly. For each pruning the pruned leaves are placed and accuracy is evaluated as the number of nodes separating expected and observed placements.

* *Expected Node Distance (eND)* :
An improved version of ND, which takes into account placement weights (e.g. Likelihood Weight Ratios, see documentation).

* *Likelihood Improvement (LI)* : 
Rapid evaluation of phylogenetic placements designed for developers and rapid evaluation of small changes in the code/algorithms. Following placement, a reoptimisation simply highlights better of worse results, in terms of likelihood changes.

* *Ressources (RESS)* :
CPU and peek RAM consumption are measured for every steps required to operate a pylogenetic placement (including alignment in alignment-based methods and ancestral state reconstruction + database build in alignment-free methods). This procedure mostly intend to evaluate the scalability of the methods, as punctual analyses or routine placement of large sequence volumes do not induce the smae constraints. 

**Phylogenetic placement software currently supported in PEWO.**

* EPA(RAxML)  (Berger et al, 2010) 
* PPlacer     (Matsen et al, 2011)
* EPA-ng      (Barbera et al, 2019)
* RAPPAS      (Linard et al, 2019)
* APPLES      (Balaban et al, 2019)

At present date (october 2019), there are no other placement methods with a software implementation.
If you implement a new method, you are welcome to contact us, code a new snakemake module and contribute to PEWO via pull requests.

## Wiki documentation

**An complete documentation, including a tutorial is available in the wiki section of this github repository.**

## Installation

### Requirements

Python 3 and Miniconda 3 needs to be installed on your system and the 'conda' command ust be accessible to the user running the workflow.

```
wget [url miniconda 3]
./miniconda3
```

If your Miniconda3 installation was successfull, you should be able to run the following command:
```
```


### Rapid installation

```
#add conda repositories
conda config add channels bioconda

#install PEWO environment
conda env create -f envs/environement.yaml
```

# Usage

1. Activate PEWO environement:

```
conda activate PEWO
```

Note that anaconda will always install the latest software version of all phylogenetic placement software supported by PEWO.
If you intend to test a particular version, you will need to manually downgrade to earlier versions, for instance:

```
conda activate PEWO
#removes the latest version of pplacer and downgrades to earlier version:
conda remove pplacer
conda install pplacer=
```

2. Setup the pipeline configuration by editing the config.yaml file. 

2/3 sentences, details in documentation

3. Choose and execute your workflow

First, it is strongly recommended to test if your configuration is valid and matches your needs.
To do so, launch a dry run of the pipeline using the command

```
snakemake --snakefile \[subworkflow\].smk -np --core 1 --config pruning_count=1
```

where \[subworkflow\] is one of the subworflow listed in the table below. This will list the operations that will be run by the workflow

Table with possible analyses

Moreover, you can produce a graph detailling the different steps of the workflow.

```
# to display the graph in a window
snakemake --snakefile \[subworkflow\].smk --config pruning_count=1 --dag | dot | display

# to produce an image of the graph
snakemake --snakefile \[subworkflow\].smk --config pruning_count=1 --dag | dot -Tsvg > graph.svg
```

## Licence

PEWO is available under the MIT license.
