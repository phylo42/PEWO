'''

@deprecated : this mechanism was wrong, as snakemake do not allow ruleA to ouput a directory, that is input of ruleB

prepare directories which corresponds to paramters combination tested in the pipeline
currently, this is used to build a directory per k/omega combination in rappas
however, a similar approach could be added later for epa/pplacer
@author Benjamin Linard
'''

import os

#debug
if (config["debug"]==1):
    print("prunings: "+os.getcwd())
#debug

#rule all:
#    input: expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config",pruning=range(0,config["pruning_count"],1),k=k_list(),omega=omega_list())

'''
creation of experiment directories
'''
rule build_rappas_exp_dir:
    input:
        config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_seq.txt",
        config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_tree.txt"
    output:
        directory(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/ready")
    log:
        config["workdir"]+"/logs/ar_expdir/{pruning}_k{k}_o{omega}.log"
    version: "1.00"
    shell:
        "touch {output}"
        #for k in k_list():
        #    for omega in omega_list():
        #        dir=config["workdir"]+"/RAPPAS/"+str(wildcards.pruning)+"/k"+str(k)+"_o"+str(omega)
        #        if not os.path.exists(dir):
        #            os.mkdir(dir)
        # if (wildcards.k in k_list()) and (wildcards.omega in omega_list()):
        #     dir=config["workdir"]+"/RAPPAS/"+str(wildcards.pruning)+"/k"+str(wildcards.k)+"_o"+str(wildcards.omega)+"_config"
        #     if not os.path.exists(dir):
        #         os.mkdir(dir)
        # else:
        #     print("k/omega combination not defined in config: k="+wildcards.k+" o="+wildcards.omega)
