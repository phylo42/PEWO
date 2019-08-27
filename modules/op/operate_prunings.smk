'''
compute the different prunings using the alignment/tree set in config file
@author Benjamin Linard
'''

# TODO: add trifurcations tests ? currently disabled
# TODO: keep or remove read length sd ?

import os

#debug
if (config["debug"]==1):
    print("prunings: "+os.getcwd())
#debug

#rule all:
#    input: expand(config["workdir"]+"/R/{pruning}_r{length}.fasta", pruning=range(0,config["pruning_count"],1), length=config["read_length"])

rule operate_pruning:
    input:
        a=config["dataset_align"],
        t=config["dataset_tree"]
    output:
        a=expand(config["workdir"]+"/A/{pruning}.align",pruning=range(0,config["pruning_count"],1)),
        t=expand(config["workdir"]+"/T/{pruning}.tree",pruning=range(0,config["pruning_count"],1)),
        g=expand(config["workdir"]+"/G/{pruning}.fasta", pruning=range(0,config["pruning_count"],1)),
        r=expand(config["workdir"]+"/R/{pruning}_r{length}.fasta", pruning=range(0,config["pruning_count"],1), length=config["read_length"])
    log:
        config["workdir"]+"/logs/operate_pruning.log"
    version:"1.00"
    params:
        wd=config["workdir"],
        count=config["pruning_count"],
        states=config["states"],
        length=str(config["read_length"]).replace("[","").replace("]","").replace(" ",""),
        #length_sd=config["read_length_sd"],
        #bpe=config["bpe"],
        kmin=config["config_rappas"]["kmin"],
        kmax=config["config_rappas"]["kmax"],
        kstep=config["config_rappas"]["kstep"],
        omin=config["config_rappas"]["omin"],
        omax=config["config_rappas"]["omax"],
        ostep=config["config_rappas"]["ostep"]
    shell:
        "java -cp viroplacetests_LITE.jar PrunedTreeGenerator_LITE "
        "{params.wd} {input.a} {input.t} "
        "{params.count} {params.length} 0 1 "
        "{params.kmin} {params.kmax} {params.kstep} "
        "{params.omin} {params.omax} {params.ostep} "
        "{params.states} -1 "
        "&> {log}"

