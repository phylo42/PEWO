"""
Creates plots which summarize the workflow results
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import os
import pewo.config as cfg

_working_dir = cfg.get_work_dir(config)


rule plot_accuracy_results:
    """
    Makes plots for the accuracy workflow.
    """
    input:
        os.path.join(_working_dir, "results.csv")
    output:
        nd_plots=get_accuracy_nd_plots(),
        end_plots=get_accuracy_end_plots()
    log:
        os.path.join(_working_dir, "logs", "R", "accuracy_plots.log")
    params:
        workdir=config["workdir"]
    shell:
        "Rscript --vanilla scripts/R/eval_accuracy_plots_v2.R {input} {params.workdir} &> {log}"


rule plot_resources_results:
    """
    Makes plots for the resources workflow.
    """
    input:
        tsv=get_resources_outputs()
    output:
        plots=get_resources_plots()
    log:
       os.path.join(_working_dir, "logs", "R", "resources_plots.log")
    params:
        workdir=_working_dir
    shell:
        "Rscript --vanilla scripts/R/eval_resources_plots.R {params.workdir} &> {log}"


rule plot_likelihood_results:
    """
    Makes plots for the likelihood workflow.
    """
    input:
        csv=os.path.join(_working_dir, "likelihood.csv")
    output:
        plots=get_likelihood_plots()
    log:
        os.path.join(_working_dir, "logs", "R", "likelihood_plots.log")
    params:
        workdir=_working_dir
    shell:
        "Rscript --vanilla scripts/R/eval_likelihood_plots.R {input.csv} {params.workdir} &> {log}"