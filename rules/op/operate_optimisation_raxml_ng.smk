"""
This module optimises pruned trees.
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import os

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
        m=select_model_raxmlngstyle(),
        c=config["phylo_params"]["categories"],
        name="{pruning}",
        raxmlname=config["workdir"]+"/T/RAxML_result.{pruning}",
        outname=config["workdir"]+"/T/{pruning}_optimised.tree",
        raxmlinfoname=config["workdir"]+"/T/RAxML_info.{pruning}",
        outinfoname=config["workdir"]+"/T/{pruning}_optimised.info",
        reduction=config["workdir"]+"/A/{pruning}.align.reduced",
        outdir= os.path.join(config["workdir"],"T","")
    shell:
        """
        raxml-ng --evaluate --threads 1 --model {params.m}  --msa {input.a} --tree {input.t} --prefix {params.outdir}{params.name} &> {log}
        mv {params.raxmlname} {params.outname}
        mv {params.raxmlinfoname} {params.outinfoname}
        rm -f {params.reduction}
        """