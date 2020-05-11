# PEWO: "Placement Evaluation WOrkflows"

[![Build Status](https://travis-ci.com/phylo42/PEWO.svg?branch=master)](https://travis-ci.com/phylo42/PEWO)

**Benchmark existing placement software and compare placement accuracy on different reference trees.**

## Overview

PEWO compiles a set of workflows dedicated to the evaluation of phylogenetic placement algorithms and their software implementation. It focuses on reporting placement accuracy under different conditions and associated computational costs.

It is built on [Snakemake](https://snakemake.readthedocs.io/en/stable/) and [Miniconda3](https://docs.conda.io/en/latest/miniconda.html) and relies extensively on the [Bioconda](https://bioconda.github.io/) and [Conda-forge](https://conda-forge.org/) repositories, making it portable to most OS supporting Python 3. A specific phylogenetic placement software can be evaluated by PEWO as long as it can be installed on said OS via conda.

**Main purposes of PEWO:**

1. Evaluate phylogenetic placement accuracy, given a particular reference species tree and corresponding reference alignment. For instance, one can run PEWO on different trees built for different taxonomic marker genes and explore which markers produce better placements.

2. Given a particular software/algorithm, empirically explore which sets of parameters produces the most accurate placements, and at which computational costs. This can be particularly useful when a huge volume of sequences are to be placed and one may need to consider a balance between accuracy and scalability (CPU/RAM limitations).

3. For developers, provide a basis to standardize phylogenetic placement evaluation and the establishment of benchmarks. PEWO aims to remove the hassle of re-implementing evaluation protocols that were described in anterior studies. In this regard, any phylogenetic placement developer is welcome to pull request new modules in the PEWO repository or contact us for future support of their new productions.

## Wiki documentation

**An complete documentation, including a tutorial for each workflow, is available in the [wiki section](https://github.com/phylo42/PEWO/wiki) of this github repository.**

## Installation

### Requirements

Before installation, the following packages should be available on your system must be installed on your system:

* Python >=3.5
* Miniconda3. Please choose the installer corresponding to your OS: [Miniconda dowloads](https://docs.conda.io/en/latest/miniconda.html)
* GIT

PEWO will look for the commands `git` and `conda`. Not finding these commands will cancel the PEWO installation.

Below are debian commands to rapidly install them:
```
sudo apt-get install git
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod u+x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh
# when installation ask if you want to run conda init, answer yes
# after installation ends, reload bash so that conda belongs to your PATH
bash 
```

### Installation

Download PEWO:
``` bash
git clone --recursive https://github.com/phylo42/PEWO.git
cd PEWO
```

Execute installation script:
``` bash
chmod u+x INSTALL.sh
./INSTALL.sh
```

After installation, load environment:
``` bash
conda activate PEWO
```

You can launch a dry-run, if no error is throwed, PEWO is correctly installed:
``` bash
snakemake -np \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
--configfile examples/1_fast_test_of_accuracy_procedure/config.yaml
```

You can launch a 20 minutes test, using 2 CPU cores.

``` bash
snakemake -p --cores 2 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/1_fast_test_of_accuracy_procedure/run \
--configfile examples/1_fast_test_of_accuracy_procedure/config.yaml
```

If the test is successful, you should produce the following statistics and image files in the `examples/1_fast_test_of_accuracy_procedure/run` directory:
* `results.csv`
* `summary_plot_eND_epang_h1.svg`
* `summary_plot_eND_pplacer.svg`
* `summary_plot_eND_rappas.svg`

<!-- ER questions: pointer to wiki doc. -->
The content and interpretation of these files are detailed in the wiki documentation. 
Please read the [dedicated wiki page](https://github.com/phylo42/PEWO/wiki/IV.-Tutorials-and-results-interpretation).


## Setup your own analyses

### PEWO procedures

* *Node Distance (ND)* : 
This standard procedure was introduced with EPA and reused in PPlacer and RAPPAS original manuscripts. The reference tree is pruned randomly. For each pruning, the pruned leaves are placed and accuracy is evaluated as the number of nodes separating expected and observed placements.

 <!-- ER  ALT : you need to delete previous paragraph -->
This distance measure between two placements was introduced with EPA and reused in PPlacer and RAPPAS original manuscripts. It is computed as follows: The reference tree is pruned randomly, which removes one sequence of the tree. The pruned sequence serves as query for placement against the pruned tree, but one knows the true solution (ie. the position of that sequence in the  original tree). The resulting placement is compared to the true solution by evaluating the accuracy as the number of nodes separating the true and observed placements. This procedure is repeated with numerous prunings. One drawback: the running time.

* *Expected Node Distance (eND)* :
An improved version of ND, which takes into account placement weights (e.g. Likelihood Weight Ratios, see documentation).

<!-- ER comment: no documentation link ; add bib reference ; what is improved  -->

* *Likelihood Improvement (LI)* : 
Rapid evaluation of phylogenetic placements designed for developers and rapid evaluation of changes in the code and algorithms. Following placement, a re-optimization simply highlights better or worse results, in terms of likelihood changes.

* *Ressources (RESS)* :
CPU and peek RAM consumptions are measured for every step required to operate phylogenetic placement (including alignment in alignment-based methods and ancestral state reconstruction + database build in alignment-free methods). This procedure mostly intends to evaluate the scalability of the methods, as punctual analyses or routine placement of large sequence volumes do not induce the same constraints. 


**Software currently supported by PEWO.**

* **EPA**(RAxML)  (Berger et al, 2010) 
* **PPlacer** (Matsen et al, 2011)
* **EPA-ng**  (Barbera et al, 2019)
* **RAPPAS**  (Linard et al, 2019)
* **APPLES**  (Balaban et al, 2019)

<!-- ER changes -->
PEWO can easily be extended to integrate new tools for phylogenetic placement, and new tools are welcome. 
As of March 2020, these tools are the main software for phylogenetic placement. To the best of your knowledge, no other implementation of phylogenetic placement algorithms are available (with a conda package). 
<!-- Currently (March 2020) there are no other implementations of phylogenetic placement algorithms.  -->

If you implement a new method, you are welcome to contact us for requesting future support. You can also implement a new snakemake module and contribute to PEWO via pull requests (see the [documentation](https://github.com/phylo42/PEWO/wiki/Developer-instructions) for contribution guidelines).

## Analysis configuration

**1. Activate PEWO environment:**

``` bash
conda activate PEWO
```
By default, the latest version of every phylogenetic placement software is installed in PEWO environment.
If you intend to evaluate anterior versions, you need to manually downgrade the corresponding package.

For instance, downgrading to anterior versions of PPlacer can be done with:

``` bash
conda uninstall pplacer
conda install pplacer=1.1.alpha17
```

**2. Select a procedure:**

PEWO proposes several procedures aiming to evaluate different aspects of phylogenetic placement. Each procedure is coding as a Snakemake workflow, which can be loaded via a dedicated Snakefile (`PEWO_workflow/\*.smk`).

Identify the Snakefile corresponding to your needs. 

<!-- ER change: lower instead of higher likelihood -->

Procedure | Snakefile | Description
--- | --- | ---
Pruning-based Accuracy evaluation (PAC) | `eval_accuracy.smk` | Given a reference tree/alignment, compute both the "Node Distance" and "expected Node Distance" for a set of software and a set of conditions. This procedure is based on a pruning approach and an important parameter is the number of prunings that is run (see documentation).
Ressources evaluation (RES) | `eval_ressources.smk` | Given a reference tree/alignment and a set of query reads, measures CPU/RAM consumptions for a set of software and a set of conditions. An important parameter is the number of repeats from which mean consumptions will be deduced (see documentation). 
Likelihood-based Accuracy evaluation (LAC) | `eval_likelihood.smk` | Given a reference tree and alignment, compute tree likelihoods induced by placements under a set of conditions, with a lower likelihood reflecting better placements.



**3. Setup the workflow by editing `config.yaml`:**

<!-- ER: todo add link to procedures ; add link to explanation on substitution models -->
The file `config.yaml` is where you setup the workflow. It contains 4 sections:
* *Workflow configuration*
The most important section: set the working directory, the input tree/alignment on which to evaluate placements, the number of pruning experiments or experiment repeats (see procedures).
* *Per software configuration*
Select a panel of parameters and parameter values for each software. Measurements will be operated for every parameter combination.
* *Options common to all software*
Mostly related to the formatting of the jplace outputs. Note that these options will impact expected Node Distances.
* *Evolutionary model*
A very basic definition of the evolutionary model used in the procedures. Currently, only GTR+G (for nucleotides), JTT+G, WAG+G and LG+G (for amino acids) are supported.  

**Notes on memory usage for alignment-free methods:**
Alignment-free methods such as RAPPAS require to build/load a database in memory prior to the placement.
This step can be memory consuming for large datasets. Correctly managing the memory is done as follows:

1. Do a test with a single RAPPAS run on the tree/alignment you use as input dataset.Write down the peek memory. To measure peek memory you can use:
```
/usr/bin/time -v command
#Make sure to use the full path, it's not the default linux 'time' command. 
```
And search for the line "Maximum resident set size".

2. For instance, You conclude RAPPAS requires 8Gb per analysis. Then force RAPPAS to use 8Gb of RAM via the snakemake config file and the field:
```yaml
config_rappas:
    memory: 8
```

3. Finally choose the maximum amount of RAM that can be used by snakemake during its launch. For instance, if you have a machine with 32Gb of RAM :
```
snakemake -p --cores 8 --resources mem_mb=32000 \
--snakefile eval_accuracy.smk \
--config workdir=`pwd`/examples/2_placement_accuracy_for_a_bacterial_taxonomy/run \
--configfile examples/2_placement_accuracy_for_a_bacterial_taxonomy/config.yaml
```
With this setup, snakemake will wait for 8gb to be free before each RAPPAS launch and will run with a maximum of four RAPPAS launches in parallel (32/8=4).

**4. Test your workflow:**

It is strongly recommended to test if your configuration is valid and matches the analyses you intended.
To do so, launch a dry run of the pipeline using the command:

``` bash
snakemake --snakefile [snakefile].smk -np
```

where `\[snakefile\]` is one of the sub-workflow snakefiles listed in the table above. 

This will list the operations that will be run by the workflow. It is also recommended to export a graph detailing the different steps of the workflow (to avoid very large graphs in "Accuracy" sub-workflow, we force a single pruning).

**to display the graph in a window**
``` bash
snakemake --snakefile [snakefile].smk --config pruning_count=1 --dag | dot | display
```
**to produce an image of the graph**
``` bash
snakemake --snakefile [snakefile].smk --config pruning_count=1 --dag | dot -Tsvg > graph.svg
```

**5. Launch the analysis:**

``` bash
snakemake --snakefile [snakefile].smk -p --core [#cores] 
```
<!-- ER changes: inserted grid system names and pointeers to wiki. qsub is a command. -->
<!-- ER changes: inserted pointer to snake doc on this. -->
Note that the workflow can be launched on a grid environment such as [SunGridEngine](https://en.wikipedia.org/wiki/Oracle_Grid_Engine) or [SLURM](https://en.wikipedia.org/wiki/Slurm_Workload_Manager) (i.e., with  `qsub` command).
Refer to the snakemake [documentation](https://snakemake.readthedocs.io/en/stable/executing/cluster-cloud.html#cluster-execution) to learn how to configure a workflow for such environments.



## Contacts
*B Linard, N Romashchenko, F Pardi, E Rivals*

MAB team (Methods and Algorithms in Bioifnormatics), LIRMM, Montpellier, France.

## Licence

PEWO is available under the MIT license.
