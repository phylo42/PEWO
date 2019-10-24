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
accessory function to correctly set which epa-ng heuristics are tested and with which parameters
'''
def select_epang_heuristics():
    l=[]
    if "h1" in config["config_epang"]["heuristics"]:
        l.append(
            expand(     config["workdir"]+"/EPANG/{pruning}/h1/{pruning}_r{length}_h1_g{gepang}_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        gepang=config["config_epang"]["h1"]["g"]
                   )
        )
    if "h2" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/EPANG/{pruning}/h2/{pruning}_r{length}_h2_bigg{biggepang}_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        biggepang=config["config_epang"]["h2"]["G"]
                        )
        )
    if "h3" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/EPANG/{pruning}/h3/{pruning}_r{length}_h3_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"]
                        )
        )
    if "h4" in config["config_epang"]["heuristics"]:
        l.append(
            expand(
                config["workdir"]+"/EPANG/{pruning}/h4/{pruning}_r{length}_h4_epang.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"]
                )
            )
    return l



'''
list all jplaces that should be present before computing node distances
'''
def define_inputs():
    inputs=list()
    if "epa" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/EPA/{pruning}/g{gepa}/{pruning}_r{length}_g{gepa}_epa.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                gepa=config["config_epa"]["G"]
            )
        )
    if "pplacer" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_ppl.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                msppl=config["config_pplacer"]["max-strikes"],
                sbppl=config["config_pplacer"]["strike-box"],
                mpppl=config["config_pplacer"]["max-pitches"]
            )
        )
    if "epang" in config["test_soft"]:
        inputs.append(
            select_epang_heuristics()
        )
    if "rappas" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_rappas.jplace",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"]
            )
        )
    if "apples" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                meth=config["config_apples"]["methods"],
                crit=config["config_apples"]["criteria"]
            )
        )
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
        compute_rappas= 1 if "rappas" in config["test_soft"] else 0,
        compute_apples= 1 if "apples" in config["test_soft"] else 0
    shell:
        "java -cp PEWO.jar DistanceGenerator_LITE2 {params.workdir} "
        "{params.compute_epa} {params.compute_epang} {params.compute_pplacer} {params.compute_rappas} {params.compute_apples} &> {log}"