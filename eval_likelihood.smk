"""
This is a workflow to evaluate likelihood of extended trees, given the parameters
set in "config.yaml". This snakefile loads all necessary modules and builds
the evaluation workflow itself based on the setup defined in the config file.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"

configfile: "config.yaml"

config["mode"] = "likelihood"

# Explicitly set config as if there was a single pruning which in fact represents the full (NOT pruned) tree.
# This allow to use the same config file for both 'accuracy' and 'resources' modes of PEWO worflow
# NOTE: this statement MUST be set BEFORE the "includes"
config["pruning_count"] = 1
config["read_length"] = [0]

# Explicitly set config to not repeat binary executions,
# which is an option that should be considered only in 'resource' evaluation mode.
# this allow to use the same config file for both 'accuracy' and 'resources' modes of PEWO worflow
# NOTE: this statement MUST be set BEFORE the "includes"
config["repeats"] = 1

# utils
include:
    "rules/utils/workflow.smk"
include:
    "rules/utils/etc.smk"
# Tree prunings
include:
    "rules/op/operate_prunings.smk"
# Tree optimisation
include:
    "rules/op/operate_optimisation.smk"

# phylo-kmer placement, e.g.: rappas
include:
    "rules/op/ar.smk"
include:
    "rules/placement/rappas.smk"
include:
    "rules/placement/rappas2.smk"
#alignment (for distance-based and ML approaches)
include:
    "rules/alignment/hmmer.smk"
# ML-based placements, e.g.: epa, epang, pplacer
include:
    "rules/placement/epa.smk"
include:
    "rules/placement/pplacer.smk"
include:
    "rules/placement/epang.smk"
# Distance-based placements, e.g.: apples
include:
    "rules/placement/apples.smk"
# Results evaluation and plots
include:
    "rules/op/operate_likelihood.smk"
include:
    "rules/op/operate_plots.smk"

rule all:
    """
    top snakemake rule, necessary to launch the workflow
    """
    input:
         build_likelihood_workflow()
