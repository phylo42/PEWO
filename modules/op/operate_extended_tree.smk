'''
computes extended trees

@author Benjamin Linard
'''

configfile: "config.yaml"

import os

#debug
if (config["debug"]==1):
    print("exttree: "+os.getcwd())
#debug

#rule all:
#    input: expand(config["workdir"]+"/T/{pruning}_optimised.tree", pruning=range(0,config["pruning_count"],1))

rule compute:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}_optimised.tree"
    output:
        directory(config["workdir"]+"/AR/{pruning}/extended_tree")
    log:
        config["workdir"]+"/logs/extended_tree/{pruning}.log"
    shell:
         ""