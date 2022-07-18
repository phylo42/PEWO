# PEWO: "Placement Evaluation WOrkflows"
**Benchmark existing placement software and compare placement accuracy on different reference trees.**


[![Build Status](https://travis-ci.com/phylo42/PEWO.svg?branch=master)](https://travis-ci.com/phylo42/PEWO) [![license](https://img.shields.io/github/license/shenwei356/seqkit.svg?maxAge=2592000)](https://github.com/phylo42/RAPPAS/LICENSE) [![Cross-platform](https://img.shields.io/badge/platform-any-ec2eb4.svg?style=flat)](https://github.com/phylo42/RAPPAS)

- **Documents:** [**Usage**](https://github.com/phylo42/PEWO/wiki),
[**Tutorial**](https://github.com/phylo42/PEWO/wiki)
<!-- badge generated via https://shields.io/) -->
- **Please cite:** [![doi](https://img.shields.io/static/v1?label=doi&message=10.1093/bioinformatics/btaa657&color=blue)](https://doi.org/10.1093/bioinformatics/btaa657)
<!-- <img align="left" src="https://github.com/blinard-BIOINFO/RAPPAS/wiki/images/rappas_logo_small.jpg" > -->
**PEWO: a collection of workflows to benchmark phylogenetic placement**<br />
*Benjamin Linard, Nikolai Romashchenko, Fabio Pardi, Eric Rivals*<br />
*Bioinformatics, btaa657, 22 July 2020*<br />
<br />

## Reference datasets

**(updated 13-01-2022)**

Datasets described in the PEWO manuscript and a compilation of datasets from other manuscripts can be retrieved with the following link :
[https://seafile.lirmm.fr/f/f6e3c6508cde4ce38dbb/](https://seafile.lirmm.fr/f/f6e3c6508cde4ce38dbb/)

Each dataset contains a README describing file(s) and source(s). \
EPA datasets : courtesy of Alexandros Stamakis. \
EPA-ng datasets : courtesy of Pierre Barbera. 

## Important notices


```diff

11/2021

Following some refactoring error, a bug was introduced in the ND computation.
This is now fixed.
It was located in the java code of the PEWO_java subrepository (which is in charge of computing node distances).
Every node distance (ND) reported by PEWO was consistenlty shifted by +1, making every reported value ND+1. 
This +1 shift occured consistently for all query sequences, whatever the selected inputs, software or software parameters.

CONSEQUENTLY, EXPERIMENTS AND SOFTWARE COMPARISONS PRIOR TO THE BUGFIX ARE STILL VALID.

Values reported by PEWO were just shifted by +1.
Following the bugfix, the shift was removed and ND values are in [0,n] again (and not in [1,n+1] )
This error was hard to spot, because in most experimental setups, average NDs are much higher than 1.

Following this bugfix. PEWO has been attributed a 1.0.0 version tag. 
``` 


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

**Software currently supported by PEWO.**

* **EPA**(RAxML)  (Berger et al, 2010) 
* **PPlacer** (Matsen et al, 2011)
* **EPA-ng**  (Barbera et al, 2019)
* **RAPPAS**  (Linard et al, 2019)
* **APPLES**  (Balaban et al, 2019)
* **App-SpaM**  (Blanke et al, 2021)


<!-- ER changes -->
PEWO can easily be extended to integrate new tools for phylogenetic placement, and new tools are welcome. 
As of November 2020, these tools are the main software for phylogenetic placement. To the best of your knowledge, no other implementation of phylogenetic placement algorithms are available (with a conda package). 

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
Refer to the snakemake [documentation](https://snakemake.readthedocs.io/en/stable/executing/cluster.html) to learn how to configure a workflow for such environments.



## Contacts
*B Linard, N Romashchenko, F Pardi, E Rivals*

MAB team (Methods and Algorithms in Bioinformatics), LIRMM, Montpellier, France.

## Licence

PEWO is available under the MIT license.


## UPDATE OF PEWO (by PENEL BENOIT - penelbenoit@gmail.com)


### 1- JAVA, branch distance and difficulty features:

Previously, PEWO was dependent of JAVA to do pruning operations. The new version of PEWO
is exempt form this dependency. For this purpose, ETE TOOLKIT version 3 (ETE3 - http://etetoolkit.org/), a python environment for tree exploration, has been charged on PEWO conda environment.
To install it: http://etetoolkit.org/download/.

Operate_pruning.smk workflow, which was dependent of JAVA environment is no longer used in evalaccuracy.smk workflow. Operate_pruning_python.smk has been developed. It is the analogue workflow of operate_pruning.smk. It is the new one use in evalaccuracy.smk.
Rule PRUNING from operate_pruning_python.smk produce the same output as the previous version of PEWO:
- Pruned trees,
- Pruned alignment files,
- Genome of pruned sequences,
- Request sequences (derivated from genome of pruned sequences),
- Dtx.csv file

and produce two new one:

- D2tx.csv : analogue file to Dtx.csv, but save branch distance rather node distance. It is a new non-redundant feature of PEWO to asses phylogenetic placement tools.
- Diff.csv : Save difficulty associated to each pruning operation as the sum of the branch length of pruned sequences.

To produce those outputs, the pruning_operation function is used. That function, which relies on ETE3 packages, comes from a python script (pruning.py). That python script is store on the pruning library of PEWO library. pruning_operation do :
- the reading of a phylogenetic tree (TREE function),
- a unique postorder exploration (postorder_explo function),
- create new features associated to TreeNode object of the phhylogenetic tree (id_and_labels_features function),
- create a list of TreeNode object which will be pruned (list_pruned_node function),
- create a list of child TreeNode object associated to the pruned object (get_child or get_leafchil_name function),
- create pruned alignement files, genome of pruned sequences files, request sequences files, D(2)tx.csv file and difficulty file (distance_and_align function),
-Creates pruned trees (multipruning function).

TODO: 

JAVA dependences exist still for nodedistance calcul operation on operate_nodedistance.smk workflow. 
In the near future, that dependence should to be fixed, to allow PEWO to calculate nodedistance and branchedistance, and  to link those measures to the level of difficulty associated to each pruning operations.

### 2- RAXML UPDATE

The current version of PEWO is using raxml-ng version of the software RAXML (https://github.com/amkozlov/raxml-ng), through operate_optimisation_raxml_ng.smk workflow, to produce reoptimized phylogenetic tree after pruning operation. It is the latest version available (July 2022). That version is faster and needs less memory space. The operate_optimisation.smk workflow however, is still used for the taxtastic operation.

TODO: 
The dependencies to operate_optimisation.smk workflow needs to be deleted. Taxtastic operation need to be done with operate_optimisation_raxml_ng.smk workflow.

### 3- Controle of pruning_count and use of minimleaf on config.yaml file

Before to lauch PEWO, a control of the values associated to pruning_count is done. If the number of pruned requested by the user is too important, in accordance with the phylogenetic tree used and the minimleaf argument choose, an update of the configuration file is generated. The values associated to pruning_count is change by the maximum of pruned possible  in accordance with the phylogenetic tree used and the minimleaf. The updated configuration file is save as a binary file and subsequently use as the new configuration file associated to PEWO. 

minimleaf corresponds to the minimum of leaves that a phylogenetic tree must contain after pruning steps.

### 4- Read simulation rule

Read simulation rule has been started in operate_pruning_python.smk (rule named generator). In this new rule, input (Genome of pruned sequences), output (generated reads) and run have been configured. It is currently not used when eval_accuracy.smk workflow is run. It is because the generator rule output are still not used.


Fastqsim tool (https://github.com/annashcherbina/FASTQSim) is used to generate reads from three different technologies :
-Illumina
-Pacbio
-Sanger

The rule run:
```
  sh {params.script} -nobackground -platform {params.techno} -source 20 {input.genome} True -plothistogram -o {output.generator} -threads 1
 ``` 
This code line allows user to generated reads from an already existing script ({params.script}) and a fasta file of sequences ({input.genome}).
-nobackground flag is used to not incorporate the sequences from the fasta file in the generated read file ; in accordance with the chosen technologies (-platform {params.techno}).
-plothistogram flag is used to generated summary plot characterising the generated reads (length of generated reads, mutation rate, error rate, etc..).
-o flag is used to give a specific name to the generated read file.
-threads flag is uses to chose a number of cpu  

TODO: 

To finish that part, it is necessary: 

- to charge new package in the env.yaml file  of PEWO  (BE CAREFULL, some part of fastqsim use PYTHON2 !): 
    - numpy,
    - scipy,
    - matplotlib,
    - python_tk,
    - tk,
    - tkinter

- Use the generated sequences in workflows performing the placement operation


 
