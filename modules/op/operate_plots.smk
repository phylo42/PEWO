'''
using R, compute plots which summarize the workflow results

@author Benjamin Linard
'''

import os

#debug
if (config["debug"]==1):
    print("exttree: "+os.getcwd())
#debug

rule plot:
    input:
        config["workdir"]+"/results.csv"
    output:
        set_plot_outputs()
    log:
        config["workdir"]+"/logs/R/summary_plots.log"
    params:
        workdir=config["workdir"]
    shell:
        "Rscript --vanilla scripts/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"