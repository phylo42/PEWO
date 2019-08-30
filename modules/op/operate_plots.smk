'''
using R, compute plots which summarize the workflow results

@author Benjamin Linard
'''

#configfile: "config.yaml"

import os

#debug
if (config["debug"]==1):
    print("exttree: "+os.getcwd())
#debug


rule plot:
    input:
        config["workdir"]+"/results.csv"
    output:
        config["workdir"]+"/experience_complitude.pdf"
    log:
        config["workdir"]+"/logs/R/summary_plots.log"
    params:
        workdir=config["workdir"]
    shell:
        "Rscript --vanilla scripts/R/summary_plots.R {input} {params.workdir} &> {log}"