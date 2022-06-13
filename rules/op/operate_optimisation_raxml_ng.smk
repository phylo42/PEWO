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
        a=config["workdir"]+"/T/{pruning}.raxml.log",
        temp1=temp(config["workdir"]+"/T/{pruning}.raxml.startTree"),
        tree=config["workdir"]+"/T/{pruning}_optimised.tree"
    log:
        config["workdir"]+"/logs/optimisation/{pruning}.log"
    version: "1.00"
    params:
        m=select_model_raxmlngstyle(),
        c=config["phylo_params"]["categories"],
        name="{pruning}",
        raxmlname=config["workdir"]+"/T/{pruning}.raxml.bestTree",
        outdir= os.path.join(config["workdir"],"T","")
    conda:  "../../envs/raxmlngenv.yaml"
    shell:
        """
        raxml-ng --evaluate --threads 1 --model {params.m}  --msa {input.a} --tree {input.t} --prefix {params.outdir}{params.name} &> {log}
        mv {params.raxmlname} {output.tree}
        """