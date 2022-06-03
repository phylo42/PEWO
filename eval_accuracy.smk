"""
WORKFLOW TO EVALUATE PLACEMENT ACCURACY, GIVEN PARAMETERS SET IN "config.yaml"
This snakefile loads all necessary modules and builds the evaluation workflow itself
based on the setup defined in the config file.
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

import pickle


configfile: "config.yaml"

config["mode"] = "accuracy"

########################
# INIT BLOCK
# first launch, config is validated (reduced # of pruning if too much required...)
# launched only once at start
from pewo.pruning.configuration import validate_config

config_valid = os.path.join(config["workdir"], "run.bin")
if not os.path.exists(config_valid):
    print('Check of configfile...')
    res = validate_config(config)
    if res:
        with open(config_valid, 'wb') as file:
            pickle.dump(config, file)
    else:
        print("error while validating config...")
        sys.exit(1)
else:
    if os.path.getsize(config_valid) > 0:
        with open(config_valid, "rb") as f:
            unpickler = pickle.Unpickler(f)
            # if file is not empty scores will be equal
            # to the value unpickled
            config = unpickler.load()


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
    "rules/op/operate_prunings_python.smk"
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
