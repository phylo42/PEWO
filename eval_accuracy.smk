"""
WORKFLOW TO EVALUATE PLACEMENT ACCURACY, GIVEN PARAMETERS SET IN "config.yaml"
This snakefile loads all necessary modules and builds the evaluation workflow itself
based on the setup defined in the config file.
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

configfile: "config.yaml"

# Explicitly set config to not repeat binary executions,
# which is an option that should be considered only in 'resource' evaluation mode.
# this allow to use the same config file for both 'accuracy' and 'resources' modes of PEWO worflow
# NOTE: this statement MUST be set BEFORE the "includes"
config["repeats"] = 1

#utils
include:
    "modules/utils/workflow.smk"
include:
    "modules/utils/etc.smk"
#prunings
include:
    "modules/op/operate_prunings.smk"
#tree optimisation
include:
    "modules/op/operate_optimisation.smk"
#phylo-kmer placement, e.g.: rappas
include:
    "modules/op/ar.smk"
include:
    "modules/placement/rappas.smk"
#alignment (for distance-based and ML approaches)
include:
    "modules/alignment/hmmer.smk"
#ML-based placements, e.g.: epa, epang, pplacer
include:
    "modules/placement/epa.smk"
include:
    "modules/placement/pplacer.smk"
include:
    "modules/placement/epang.smk"
#distance-based placements, e.g.: apples
include:
    "modules/placement/apples.smk"
#results evaluation and plots
include:
    "modules/op/operate_nodedistance.smk"
include:
    "modules/op/operate_plots.smk"


rule all:
    '''
    top snakemake rule, necessary to launch the workflow
    '''
    input:
        build_accuracy_workflow()
