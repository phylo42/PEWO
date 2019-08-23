'''
computes ancestral reconstructions using phyml

@author Benjamin Linard
'''

# todo: set correct string for model depending on  config["phylo_params"]["model"]

configfile: "config.yaml"

import os

#debug
if (config["debug"]==1):
    print("ar: "+os.getcwd())
#debug

#rule all:
#    input: expand(config["workdir"]+"/T/{pruning}_optimised.tree", pruning=range(0,config["pruning_count"],1))

'''
extract phylo parameters from info file to transfer them to phyml
'''
def extract_params(file):
    res={}
    with open(file,'r') as infofile:
        line = infofile.readline()
        while line:
            if line.startswith("Substitution Matrix:") :
                res["model"]=line.split(" ")[1]
            if line.startswith("alpha:") :
                res["alpha"]=line.split(" ")[1]
    infofile.close()
    return res

'''
compute ancestral probabilites
'''
rule compute:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}_optimised.tree"
    output:
        directory(config["workdir"]+"/AR/{pruning}/AR")
    log:
        config["workdir"]+"/logs/AR/{pruning}.log"
    params:
        phylo_params=extract_params(config["workdir"]+"/T/{pruning}_optimised.info"),  #launch 1 extract per pruning
        c=config["phylo_params"]["categories"]
    shell:
        """
        phyml --ancestral --no_memory_check -b 0 -v 0.0 -o r -f e -a {phylo_params['alpha']} -m phylo_params['model'] -c {params.c} -i {input.a} -u {input.t} &> {log}
        mv extended_align.phylip_phyml_stats.txt extended_align.phylip_phyml_stats.txt
        mv extended_trees/extended_align.phylip_phyml_ancestral_tree.txt extended_align.phylip_phyml_ancestral_tree.txt
        mv extended_trees/extended_align.phylip_phyml_ancestral_seq.txt extended_align.phylip_phyml_ancestral_seq.txt
        mv extended_trees/extended_align.phylip_phyml_tree.txt extended_align.phylip_phyml_tree.txt
        """
