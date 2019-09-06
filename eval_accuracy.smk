'''
WORKFLOW TO EVALUATE PLACEMENT ACCURACY, GIVEN PARAMATERS SET IN eval_accuracy_config.yaml
This top snakefile loads all modules necessary to the evaluation itself.

@author Benjamin Linard
'''

#this config file is set globally for all subworkflows
configfile: "eval_accuracy_config.yaml"

#prunings
include:
    "modules/op/operate_prunings.smk"
include:
    "modules/op/operate_optimisation.smk"
#alignment-free placements, e.g. : rappas
include:
    "modules/op/operate_ar.smk"
include:
    #"modules/placement/placement_rappas_dbondisk.smk"
    "modules/placement/placement_rappas_dbinram.smk"
#alignments
include:
    "modules/alignment/alignment_hmm.smk"
#alignment-based placements, e.g. : epa, epang, pplacer
include:
    "modules/placement/placement_epa.smk"
include:
    "modules/placement/placement_ppl.smk"
include:
    "modules/placement/placement_epang.smk"
#node distances
include:
    "modules/op/operate_nodedistance.smk"
#R plots
include:
    "modules/op/operate_plots.smk"

import numpy as numpy

'''
list of tested ks
'''
def k_list():
    l=[]
    for k in range(config["config_rappas"]["kmin"],config["config_rappas"]["kmax"]+1,config["config_rappas"]["kstep"]):
        l.append(str(k))
    return l

'''
list of tested omegas
'''
def omega_list():
    l=[]
    for o in numpy.arange(config["config_rappas"]["omin"], config["config_rappas"]["omax"]+config["config_rappas"]["ostep"], config["config_rappas"]["ostep"]):
        l.append(str(o))
    return l


rule all:
     input:
         expand(config["workdir"]+"/PPLACER/{pruning}_r{length}_ppl.jplace", pruning=range(0,config["pruning_count"]), length=config["read_length"]),
         expand(config["workdir"]+"/EPA/{pruning}_r{length}_epa.jplace", pruning=range(0,config["pruning_count"]), length=config["read_length"]),
         expand(config["workdir"]+"/EPANG/{pruning}_r{length}_epang.jplace", pruning=range(0,config["pruning_count"]), length=config["read_length"]),
         expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace", pruning=range(0,config["pruning_count"]), k=k_list(),omega=omega_list(),length=config["read_length"]),
         config["workdir"]+"/experience_complitude.pdf"

