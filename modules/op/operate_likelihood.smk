"""
This module computes the likelihood of a tree.
"""

__author__ = "Nikolai Romashchenko"

import os


rule operate_likelihood:
    input:
        alignment = os.path.join(config["workdir"], "A+", "{query}.align"),
        tree = os.path.join(config["workdir"], "T+", "{query}.tree")
    output:
        likelihood = config["workdir"] + "/LL/{query}.txt",
    log:
        config["workdir"]+"/logs/operate_likelihood_{query}.log"
    version:
        "1.00"
    shell:
        'raxml-ng --evaluate --msa {input.alignment} --tree {input.tree} --model GTR+G | '
        'grep "Final LogLikelihood" > {output.likelihood}'
