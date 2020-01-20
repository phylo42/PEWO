'''
WORKFLOW TO EVALUATE RESSOURCES NECESSARY TO PLACEMENTS
This top snakefile loads all necessary modules and operations.
CPU/RAM/disk measurements are done via SnakeMake "benchmark" functions.

@author Benjamin Linard
'''

#this config file is set globally for all subworkflows
configfile: "config.yaml"

'''
explicitly set config as if there was a single pruning which in fact represents the full (NOT pruned) tree.
this allow to use the same config file for both 'accuracy' and 'resources' modes of PEWO worflow
NOTE: this statement MUST be set BEFORE the "includes"
'''
config["pruning_count"]=1
config["read_length"]=[0]

#utils
include:
    "modules/utils/workflow.smk"
include:
    "modules/utils/etc.smk"
#prepare input files
include:
    "modules/op/operate_inputs.smk"
include:
    "modules/op/operate_optimisation.smk"
#phylo-kmer placement, e.g.: rappas
include:
    "modules/op/operate_ar.smk"
include:
    "modules/placement/placement_rappas_dbondisk.smk"
#alignment (for distance-based and ML approaches)
include:
    "modules/alignment/alignment_hmm.smk"
#ML-based placements, e.g.: epa, epang, pplacer
include:
    "modules/placement/placement_epa.smk"
include:
    "modules/placement/placement_pplacer.smk"
include:
    "modules/placement/placement_epang_h1.smk"
include:
    "modules/placement/placement_epang_h2.smk"
include:
    "modules/placement/placement_epang_h3.smk"
include:
    "modules/placement/placement_epang_h4.smk"
#distance-based placements, e.g.: apples
include:
    "modules/placement/placement_apples.smk"
#results and plots
include:
    "modules/op/operate_plots.smk"

rule all:
     input:
         build_resources_workflow()
