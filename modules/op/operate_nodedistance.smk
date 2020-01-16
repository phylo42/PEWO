"""
Computes the ND (node distance) metric using .jplace output files
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"


import os

#debug;
if (config["debug"]==1):
    print("prunings: "+os.getcwd())
#debug


#rule all:
#    input: config["workdir"]+"/results.csv"


rule compute_nodedistance:
    input:
        jplace_files = get_jplace_outputs()
    output:
        config["workdir"]+"/results.csv"
    log:
        config["workdir"]+"/logs/compute_nd.log"
    params:
        workdir=config["workdir"],
        compute_epa= 1 if "epa" in config["test_soft"] else 0 ,
        compute_epang= 1 if "epang" in config["test_soft"] else 0,
        compute_pplacer= 1 if "pplacer" in config["test_soft"] else 0,
        compute_rappas= 1 if "rappas" in config["test_soft"] else 0,
        compute_apples= 1 if "apples" in config["test_soft"] else 0
    shell:
        "java -cp `which RAPPAS.jar`:PEWO.jar DistanceGenerator_LITE2 {params.workdir} "
        "{params.compute_epa} {params.compute_epang} {params.compute_pplacer} {params.compute_rappas} {params.compute_apples} &> {log}"