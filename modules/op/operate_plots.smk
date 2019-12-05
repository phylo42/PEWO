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
        accuracy_plots_ND_outputs(),
        accuracy_plots_eND_outputs()
    log:
        config["workdir"]+"/logs/R/summary_plots.log"
    params:
        workdir=config["workdir"]
    shell:
        "Rscript --vanilla scripts/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"

# rule plot_resource_results:
#     input:
#         directory(config["workdir"]+"/benchmarks")
#     output:
#         set_resource_plots_outputs()
#     log:
#         config["workdir"]+"/logs/R/summary_plots.log"
#     params:
#         workdir=config["workdir"]
#     shell:
#         "Rscript --vanilla scripts/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"