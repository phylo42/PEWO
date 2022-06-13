"""
This module optimises pruned trees.
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


# TODO: add model/parameters selection in the config file, this config needs to be propagated to all placement software

import os

rule optimise_for_taxtastic:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}.tree"
    output:
        temp(config["workdir"]+"/T/taxtastic/RAxML_binaryModelParameters.{pruning}"),
        temp(config["workdir"]+"/T/taxtastic/RAxML_log.{pruning}"),
        config["workdir"]+"/T/taxtastic/{pruning}_optimised.info"
    log:
        config["workdir"]+"/logs/optimisation/{pruning}.log"
    version: "1.00"
    params:
        m=select_model_raxmlstyle(),
        c=config["phylo_params"]["categories"],
        name="{pruning}",
        raxmlname=config["workdir"]+"/T/taxtastic/RAxML_result.{pruning}",
        outname=config["workdir"]+"/T/taxtastic/{pruning}_optimised.tree",
        raxmlinfoname=config["workdir"]+"/T/taxtastic/RAxML_info.{pruning}",
        outinfoname=config["workdir"]+"/T/taxtastic/{pruning}_optimised.info",
        reduction=config["workdir"]+"/A/taxtastic/{pruning}.align.reduced",
        outdir= os.path.join(config["workdir"],"T","taxtastic")
    shell:
        """
        raxmlHPC-SSE3 -f e -w {params.outdir} -m {params.m} -c {params.c} -s {input.a} -t {input.t} -n {params.name} &> {log}
        mv {params.raxmlinfoname} {params.outinfoname}
        rm -f {params.reduction}
        """