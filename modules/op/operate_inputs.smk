'''
Prepare directories to run a resource test.
Basically, it uses same directory structure than a pruning test, but with a unique run '0', which represents
a full, non-pruned tree and for which repeated placements runs will be launched for a set of reads set
(set as R/O/O_r0.fasta).

@author Benjamin Linard
'''

import os


# TODO: script of function to compute reads from alignment

def queries():
    if config["query_type"]=="user":
        return config["query_user"]
    else:
        #compute queries from alignment
        return ""



rule define_resource_inputs:
    input:
        a=config["dataset_align"],
        t=config["dataset_tree"],
        r=queries()
    output:
        aout=config["workdir"]+"/A/0.align",
        tout=config["workdir"]+"/T/0.tree",
        gout=config["workdir"]+"/G/0.fasta",
        rout=config["workdir"]+"/R/0_r0.fasta"
    run:
        if not os.path.isdir(config["workdir"]):
            os.mkdir(config["workdir"])
        if not os.path.isdir(config["workdir"]+"/A"):
            os.mkdir(config["workdir"]+"/A")
        if not os.path.isdir(config["workdir"]+"/T"):
            os.mkdir(config["workdir"]+"/T")
        if not os.path.isdir(config["workdir"]+"/G"):
            os.mkdir(config["workdir"]+"/G")
        if not os.path.isdir(config["workdir"]+"/R"):
            os.mkdir(config["workdir"]+"/R")
        shell(
            """
            cp {input.a} {output.aout}
            cp {input.t} {output.tout}
            """
        )
        if config["query_type"]=='user':
            shell(
                """
                cp {input.r} {output.rout}
                cp {input.r} {output.gout}
                """
            )