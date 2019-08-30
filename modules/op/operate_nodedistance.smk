'''
compute the ND (node distances) metric using the jplace outputs
@author Benjamin Linard
'''

#configfile: "config.yaml"

import os
import numpy as numpy

#debug
if (config["debug"]==1):
    print("prunings: "+os.getcwd())
#debug


#rule all:
#    input: config["workdir"]+"/results.csv"

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


'''
list all jplaces that should be present before computing node distances
'''
def define_inputs():
    inputs=list()
    if "epa" in config["test_soft"]:
        inputs.append(expand(config["workdir"]+"/EPA/{pruning}_r{length}_epa.jplace",pruning=range(0,config["pruning_count"]),length=config["read_length"]))
    if "pplacer" in config["test_soft"]:
        inputs.append(expand(config["workdir"]+"/PPLACER/{pruning}_r{length}_ppl.jplace",pruning=range(0,config["pruning_count"]),length=config["read_length"]))
    if "epang" in config["test_soft"]:
        inputs.append(expand(config["workdir"]+"/EPANG/{pruning}_r{length}_epang.jplace",pruning=range(0,config["pruning_count"]),length=config["read_length"]))
    if "rappas" in config["test_soft"]:
        inputs.append(expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace",pruning=range(0,config["pruning_count"]),length=config["read_length"],k=k_list(),omega=omega_list()))
    #print(inputs)
    return inputs


rule compute_nodedistance:
    input:
        jplace_files=define_inputs()
    output:
        config["workdir"]+"/results.csv"
    log:
        config["workdir"]+"/logs/compute_nd.log"
    params:
        workdir=config["workdir"],
        compute_epa= 1 if "epa" in config["test_soft"] else 0 ,
        compute_epang= 1 if "epang" in config["test_soft"] else 0,
        compute_pplacer= 1 if "pplacer" in config["test_soft"] else 0,
        compute_rappas= 1 if "rappas" in config["test_soft"] else 0
    shell:
        "java -cp viroplacetests_LITE.jar DistanceGenerator_LITE {params.workdir} "
        "{params.compute_epa} {params.compute_epang} {params.compute_pplacer} {params.compute_rappas} -1 &> {log}"