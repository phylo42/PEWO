'''
using R, compute plots which summarize the workflow results

@author Benjamin Linard
'''

import os

#debug
if (config["debug"]==1):
    print("exttree: "+os.getcwd())
#debug

rule plot_accuracy_results:
    input:
        config["workdir"]+"/results.csv"
    output:
        accuracy_plots_ND(),
        accuracy_plots_eND()
    log:
        config["workdir"]+"/logs/R/plots_accuracy.log"
    params:
        workdir=config["workdir"]
    shell:
        "Rscript --vanilla scripts/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"

rule plot_resource_results:
     input:
         build_benchmarks_workflow()
     output:
         resource_plots()
     log:
         config["workdir"]+"/logs/R/plots_resources.log"
     params:
         workdir=config["workdir"]
     shell:
         "Rscript --vanilla scripts/R/eval_resource_plots.R {params.workdir} &> {log}"