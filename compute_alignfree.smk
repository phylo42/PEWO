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
    "modules/op/operate_ar.smk"
include:
    "modules/op/operate_directories.smk"
#include:
#    "modules/placement/placement_rappas.smk"


rule all:
    input: expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}", pruning=1, k=6,omega=1.00)