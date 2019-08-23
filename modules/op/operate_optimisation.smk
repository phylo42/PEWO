'''
optimises all pruned trees

@author Benjamin Linard
'''

# TODO: add model/parameters selection in the config file, this config needs to be propagated to all placement software

#configfile: "config.yaml"

import os

#debug
if (config["debug"]==1):
    print("prunings: "+os.getcwd())
#debug

#rule all:
#    input: expand(config["workdir"]+"/T/{pruning}_optimised.tree", pruning=range(0,config["pruning_count"],1))

rule optimise:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}.tree"
    output:
        temp(config["workdir"]+"/T/RAxML_binaryModelParameters.{pruning}"),
        temp(config["workdir"]+"/T/RAxML_log.{pruning}"),
        config["workdir"]+"/T/{pruning}_optimised.tree",
        config["workdir"]+"/T/{pruning}_optimised.info"
    log:
        config["workdir"]+"/logs/optimisation/{pruning}.log"
    version: "1.00"
    params:
        m=config["phylo_params"]["model"],
        c=config["phylo_params"]["categories"],
        name="{pruning}",
        raxmlname=config["workdir"]+"/T/RAxML_result.{pruning}",
        outname=config["workdir"]+"/T/{pruning}_optimised.tree",
        raxmlinfoname=config["workdir"]+"/T/RAxML_info.{pruning}",
        outinfoname=config["workdir"]+"/T/{pruning}_optimised.info",
        reduction=config["workdir"]+"/A/{pruning}.align.reduced",
        outdir= os.path.join(config["workdir"],"T")
    shell:
        """
        raxmlHPC-SSE3 -f e -w {params.outdir} -m {params.m} -c {params.c} -s {input.a} -t {input.t} -n {params.name} &> {log}
        mv {params.raxmlname} {params.outname}
        mv {params.raxmlinfoname} {params.outinfoname}
        rm -f {params.reduction}
        """