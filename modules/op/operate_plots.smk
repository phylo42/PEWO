"""
Computes plots which summarize the workflow results
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import os
import pewo.config as cfg


rule plot_accuracy_results:
    input:
        config["workdir"] + "/results.csv"
    output:
        accuracy_plots_nd_outputs(),
        accuracy_plots_end_outputs()
    log:
        config["workdir"]+"/logs/R/summary_plots.log"
    params:
        workdir=config["workdir"]
    shell:
        "Rscript --vanilla pewo/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"

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
#         "Rscript --vanilla pewo/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"


_working_dir = cfg.get_work_dir(config)

rule plot_likelihood_results:
    input:
        os.path.join(_working_dir, "likelihood.csv")
    output:
        accuracy_plots_nd_outputs(),
        accuracy_plots_end_outputs()
    log:
        os.path.join(_working_dir, "logs", "R", "summary_plots.log")
    params:
        workdir = _working_dir
    shell:
        "Rscript --vanilla pewo/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"
