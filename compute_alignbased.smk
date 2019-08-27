'''
WORKFLOW FOR EPA PLACEMENTS COMPUTATION
This file describes the pipeline itself.
It calls many other SnakeFiles (*.smk) which are modules dedicated to the different operations.
@author Benjamin Linard
'''

#this config file is not set globally for all subworkflows
configfile: "config.yaml"

include:
    "modules/op/operate_prunings.smk"
include:
    "modules/op/operate_optimisation.smk"
include:
    "modules/alignment/alignment_hmm.smk"
include:
    "modules/placement/placement_epa.smk"
include:
    "modules/placement/placement_ppl.smk"
include:
    "modules/placement/placement_epang.smk"

rule all:
    input:
        expand(config["workdir"]+"/EPA/{pruning}_r{length}_epa.jplace", pruning=range(0,config["pruning_count"],1), length=config["read_length"]),
        expand(config["workdir"]+"/PPLACER/{pruning}_r{length}_ppl.jplace", pruning=range(0,config["pruning_count"],1), length=config["read_length"]),
        expand(config["workdir"]+"/EPANG/{pruning}_r{length}_epang.jplace", pruning=range(0,config["pruning_count"],1), length=config["read_length"])