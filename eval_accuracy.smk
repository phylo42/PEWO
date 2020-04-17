"""
WORKFLOW TO EVALUATE PLACEMENT ACCURACY, GIVEN PARAMETERS SET IN "config.yaml"
This snakefile loads all necessary modules and builds the evaluation workflow itself
based on the setup defined in the config file.
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

configfile: "config.yaml"


config["mode"] = "accuracy"

# Explicitly set config to not repeat binary executions,
# which is an option that should be considered only in 'resource' evaluation mode.
# this allow to use the same config file for both 'accuracy' and 'resources' modes of PEWO worflow
# NOTE: this statement MUST be set BEFORE the "includes"
config["repeats"] = 1

#utils
include:
    "rules/utils/workflow.smk"
include:
    "rules/utils/etc.smk"
#prunings
include:
    "rules/op/operate_prunings.smk"
#tree optimisation
include:
    "rules/op/operate_optimisation.smk"
#phylo-kmer placement, e.g.: rappas
include:
    "rules/op/ar.smk"
include:
    "rules/placement/rappas_dbinram.smk"
#alignment (for distance-based and ML approaches)
include:
    "rules/alignment/hmmer.smk"
#ML-based placements, e.g.: epa, epang, pplacer
include:
    "rules/placement/epa.smk"
include:
    "rules/placement/pplacer.smk"
include:
    "rules/placement/epang.smk"
#distance-based placements, e.g.: apples
include:
    "rules/placement/apples.smk"
include:
    "rules/placement/appspam.smk"
#results evaluation and plots
include:
    "rules/op/operate_nodedistance.smk"
include:
    "rules/op/operate_plots.smk"


rule all:
    '''
    top snakemake rule, necessary to launch the workflow
    '''
    input:
        build_accuracy_workflow()
