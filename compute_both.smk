'''
WORKFLOW FOR PLACEMENTS COMPUTATION, BOTH ALINGMENT-BASED AND ALIGNMENT-FREE
This file describes the pipeline itself.
It calls many other SnakeFiles (*.smk) which are modules dedicated to the different operations.
@author Benjamin Linard
'''

#this config file is not set globally for all subworkflows
configfile: "config.yaml"

#prunings
include:
    "modules/op/operate_prunings.smk"
include:
    "modules/op/operate_optimisation.smk"
#rappas
include:
    "modules/op/operate_ar.smk"
include:
    "modules/placement/placement_rappas_dbondisk.smk"
#alignments
include:
    "modules/alignment/alignment_hmm.smk"
#other placements
include:
    "modules/placement/placement_epa.smk"
include:
    "modules/placement/placement_ppl.smk"
include:
    "modules/placement/placement_epang.smk"


import numpy as numpy

'''
list of tested ks
'''
def k_list():
    l=[]
    for k in range(config["config_rappas"]["kmin"],config["config_rappas"]["kmax"],config["config_rappas"]["kstep"]):
        l.append(str(k))
    return l

'''
list of tested omegas
'''
def omega_list():
    l=[]
    for o in numpy.arange(config["config_rappas"]["omin"], config["config_rappas"]["omax"], config["config_rappas"]["ostep"]):
        l.append(str(o))
    return l

rule all:
    input:
        expand(config["workdir"]+"/EPA/{pruning}_r{length}_epa.jplace", pruning=1, length=config["read_length"]),
        expand(config["workdir"]+"/PPLACER/{pruning}_r{length}_ppl.jplace", pruning=1, length=config["read_length"]),
        expand(config["workdir"]+"/EPANG/{pruning}_r{length}_epang.jplace", pruning=1, length=config["read_length"]),
        expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace", pruning=1, k=k_list(),omega=omega_list(),length=config["read_length"]),
