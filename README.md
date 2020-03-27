# PEWO: "Placement Evaluation WOrkflows"

[![Build Status](https://travis-ci.com/phylo42/PEWO.svg?branch=master)](https://travis-ci.com/phylo42/PEWO)

**Benchmark existing placement software and compare placement accuracy on different reference trees.**

## Overview

PEWO compiles a set of workflows dedicated to the evaluation of phylogenetic placement algorithms and their software implementation. It focuses on reporting placement accuracy under different conditions and associated computational costs.

It is built on [Snakemake](https://snakemake.readthedocs.io/en/stable/) and [Miniconda3](https://docs.conda.io/en/latest/miniconda.html) and relies extensively on the [Bioconda](https://bioconda.github.io/) and [Conda-forge](https://conda-forge.org/) repositories, making it portable to most OS supporting Python 3. A specific phylogenetic placement software can be evaluated by PEWO as long as it can be installed on said OS via conda.

**Main purposes of PEWO:**

1. Evaluate phylogenetic placement accuracy, given a particular reference species tree and corresponding reference alignment. For instance, one can run PEWO on different trees built for different taxonomic marker genes and explore which markers produce better placements.

2. Given a particular software/algorithm, empirically explore which sets of parameters produces the most accurate placements and for which computational costs. This can be particularly useful when a huge volume of sequences are to be placed and one may need to consider a balance between accuracy and scalability (CPU/RAM limitations).

3. For developers, provide a basis to standardize phylogenetic placement evaluation and the establishment of benchmarks. PEWO aims to remove the hassle of re-implementing evaluation protocols that were described in anterior studies. In this regard, any phylogenetic placement developer is welcome to pull request new modules in the PEWO repository or contact us for future support of their new productions.

## Wiki documentation

**An complete documentation, including a tutorial is available in the [wiki section](https://github.com/phylo42/PEWO/wiki) of this github repository.**

## Installation

### Requirements

Before installation, the following packages should be available on your system must be installed on your system:

* Python >=3.5
* Miniconda3. Please choose the installer corresponding to your OS: [Miniconda dowloads](https://docs.conda.io/en/latest/miniconda.html)
* GIT

PEWO will look for the commands 'git' and 'conda'. Not finding these commands will cancel the PEWO installation.

Below are debian commands to rapidly install them:
```
sudo apt-get install git
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod u+x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh
```

### Installation

Download PEWO:
```
git clone --recursive https://github.com/phylo42/PEWO.git
cd PEWO
```

Execute installation script:
```
chmod u+x INSTALL.sh
./INSTALL.sh
```

After installation, load environment:
```
conda activate PEWO
```

You can launch a dry-run, if no error is throwed, PEWO is correctly installed:
```
snakemake -np \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
--configfile examples/1_fast_test_of_accuracy_procedure/config.yaml
```

You can launch a 20 minutes test, using 2 CPU cores.

```
snakemake -p --cores 2 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
--configfile examples/1_fast_test_of_accuracy_procedure/config.yaml
```

If the test is successful, you should produce csv and svg files in the PEWO_workflow directory, for instance:
* results.csv
* summary_plot_eND_epang_h1.svg
* summary_plot_eND_pplacer.svg
* summary_plot_eND_rappas.svg

The content and interpretation of these files are detailed in the wiki documentation. 
Please read the [dedicated wiki page](https://github.com/phylo42/PEWO/tree/master/examples/1_fast_test_of_accuracy_procedure).


## Setup your own analyses

### PEWO procedures

* *Node Distance (ND)* : 
This standard procedure was introduced with EPA and reused in PPlacer and RAPPAS original manuscripts. The reference tree is pruned randomly. For each pruning the pruned leaves are placed and accuracy is evaluated as the number of nodes separating expected and observed placements.

* *Expected Node Distance (eND)* :
An improved version of ND, which takes into account placement weights (e.g. Likelihood Weight Ratios, see documentation).

* *Likelihood Improvement (LI)* : 
Rapid evaluation of phylogenetic placements designed for developers and rapid evaluation of small changes in the code/algorithms. Following placement, a reoptimisation simply highlights better of worse results, in terms of likelihood changes.

* *Ressources (RESS)* :
CPU and peek RAM consumption are measured for every steps required to operate a pylogenetic placement (including alignment in alignment-based methods and ancestral state reconstruction + database build in alignment-free methods). This procedure mostly intend to evaluate the scalability of the methods, as punctual analyses or routine placement of large sequence volumes do not induce the same constraints. 

**Software currently supported by PEWO.**

* **EPA**(RAxML)  (Berger et al, 2010) 
* **PPlacer** (Matsen et al, 2011)
* **EPA-ng**  (Barbera et al, 2019)
* **RAPPAS**  (Linard et al, 2019)
* **APPLES**  (Balaban et al, 2019)

Currently, (october 2019) there are no other implementations of phylogenetic placement algorithms. If you implement a new method, you are welcome to contact us for requesting future support or you can directly code a new snakemake module and contribute to PEWO via pull requests (see documentation for contribution rules).


## Analysis configuration

**1. Activate PEWO environment:**

```
conda activate PEWO
```
By default, the latest version of every phylogenetic placement software is installed in PEWO environment.
If you intend to evaluate anterior versions, you need to manually downgrade the corresponding package.

For instance, downgrading to anterior versions of PPlacer can be done with:

```
conda uninstall pplacer
conda install pplacer=1.1.alpha17
```

**2. Select a procedure :**

PEWO proposes several procedures aiming to evaluate different aspects of phylogenetic placement. Each procedure is coding as a Snakemake workflow, which can be loaded via a dedicated Snakefile (PEWO_workflow/\*.smk).

Identify the Snakefile corresponding to your needs. 

Procedure | Snakefile | Description
--- | --- | ---
Accuracy (ND + eND) | eval_accuracy.smk | Given a reference tree/alignment, compute both the "Node Distance" and "expected Node Distance" for a set of software and a set of conditions. This procedure is based on a pruning approach and an important parameter is the number of prunings that is run (see documentation).
Ressources | eval_ressources.smk | Given a reference tree/alignment and a set of query reads, measures CPU/RAM consumptions for a set of software and a set of conditions. An important parameter is the number of repeats from which mean consumptions will be deduced (see documentation). 
Likelihood Improvement | eval_likelihood.smk | Given a reference tree/alignment, compute tree likelihoods induced by placements under a set of conditions, with higher likelihood reflecting better placements.


**3. Setup the workflow by editing config.yaml:**

The file config.yaml is where you setup the workflow. It contains 4 sections:
* *Workflow configuration*
The most important section: set the working directory, the input tree/alignment on which to evaluate placements, the number of pruning experiments or experiment repeats (see procedures).
* *Per software configuration*
Select a panel of parameters and parameter values for each software. Measurements will be operated for every parameter combination.
* *Options common to all software*
Mostly related to the formatting of the jplace outputs. Note that these options will impact expected Node Distances.
* *Evolutionary model*
A very basic definition of the evolutionary model used in the procedures. Currently, only GTR+G (nucleotides), JTT+G, WAG+G and LG+G (amino acids) are supported.  

**4. Test your workflow:**

It is strongly recommended to test if your configuration is valid and matches the analyses you intended.
To do so, launch a dry run of the pipeline using the command:

```
snakemake --snakefile [snakefile].smk -np
```

where \[snakefile\] is one of the sub-workflow snakefiles listed in the table above. 

This will list the operations that will be run by the workflow. It is also recommended to export a graph detailing the different steps of the workflow (to avoid very large graphs in "Accuracy" sub-workflow, we force a single pruning).

```
# to display the graph in a window
snakemake --snakefile [snakefile].smk --config pruning_count=1 --dag | dot | display

# to produce an image of the graph
snakemake --snakefile [snakefile].smk --config pruning_count=1 --dag | dot -Tsvg > graph.svg
```

**5. Launch the analysis:**

```
snakemake --snakefile [snakefile].smk -p --core [#cores] 
```
Note that the workflow can be launched on a grid environment such as qsub.
Refer to the snakemake documentation to learn how to configure the snakemake workflow for such an environment.

## Contacts
*B Linard, N Romashchenko, F Pardi, E Rivals*
MAB team (Methods and Algorithms in Bioifnormatics), LIRMM, Montpellier, France.

## Licence

PEWO is available under the MIT license.
