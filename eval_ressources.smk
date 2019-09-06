'''
WORKFLOW TO RESSOURCES NECESSARY TO PLACEMENTS, GIVEN A DATASET AND PARAMATERS SET IN eval_ressources_config.yaml
This top snakefile loads all modules, are operates measurements via SnakeMake "benchmark" functions.

@author Benjamin Linard
'''

#this config file is set globally for all subworkflows
configfile: "eval_accuracy_config.yaml"

#prepare input files
include:
    "modules/op/operate_queries.smk"
include:
    "modules/op/operate_optimisation.smk"
#alignment-free placements, e.g. : rappas
include:
    "modules/op/operate_ar.smk"
include:
    "modules/placement/placement_rappas_dbondisk.smk"




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
         #expand(config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_seq.txt", pruning=0)
         #expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/DB.bin",pruning=0, k=k_list(),omega=omega_list(),length=0)
         expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace", pruning=0, k=k_list(),omega=omega_list(),length=0)
