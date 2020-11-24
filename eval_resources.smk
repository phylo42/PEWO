"""
WORKFLOW TO EVALUATE RESSOURCES NECESSARY TO PLACEMENTS
This top snakefile loads all necessary modules and operations.
CPU/RAM/disk measurements are done via SnakeMake "benchmark" functions.
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

# this config file is set globally for all subworkflows
configfile: "config.yaml"

config["mode"] = "resources"

# explicitly set config as if there was a single pruning which in fact represents the full (NOT pruned) tree.
# this allow to use the same config file for both 'accuracy' and 'resources' modes of PEWO worflow
# NOTE: this statement MUST be set BEFORE the "includes"
config["pruning_count"] = 1
config["read_length"] = [0]

#utils
include:
    "rules/utils/workflow.smk"
include:
    "rules/utils/etc.smk"
#prepare input files
include:
    "rules/op/operate_inputs.smk"
include:
    "rules/op/operate_optimisation.smk"
#phylo-kmer placement, e.g.: rappas
include:
    "rules/op/ar.smk"
include:
    "rules/placement/rappas.smk"
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
#results and plots
include:
    "rules/op/operate_plots.smk"

rule all:
    input:
        build_resources_workflow()
