"""
Functions related to workflow constructions,
e.g. define snakemake outputs depending on tested software
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import os
from typing import List
from pewo.software import AlignmentSoftware
from pewo.templates import get_software_dir, get_common_queryname_template, get_common_template_args


'''
builds the list of outputs,for a "accuracy" workflow
'''
def build_accuracy_workflow():
    l=list()
    #placements
    l.append(
        build_placements_workflow()
    )
    #compute node distances metrics from jplace outputs
    l.append(config["workdir"]+"/results.csv")
    #collection of results and generation of summary plots
    l.append(accuracy_plots_ND_outputs())
    l.append(accuracy_plots_eND_outputs())
    return l

'''
builds the list of outputs,for a "resources" workflow
'''
def build_resources_workflow():

    l=list()

    #call outputs from operate_inputs module to build input reads as pruning=0 and r=0
    l.append( config["workdir"]+"/A/0.align")
    l.append( config["workdir"]+"/T/0.tree")
    l.append( config["workdir"]+"/G/0.fasta")
    l.append( config["workdir"]+"/R/0_r0.fasta")

    #placements
    l.append(
        build_placements_workflow()
    )

    #collection of results and generation of summary plots
    #l.append(build_plots())

    return l

'''
'''
def build_likelihood_workflow():
    l=list()

    # get placements
    #l.append(
    #    _build_likelihood_workflow()
    #)

    # compute likelihood values from jplace outputs
    l.append(config["workdir"] + "/likelihood.csv")

    # collection of results and generation of summary plots
    #l.append(accuracy_plots_ND_outputs())
    #l.append(accuracy_plots_eND_outputs())
    return l


def _get_query_alignment_output() -> List[str]:
    """
    Returns the list of .fasta files of aligned query files. These files
    must be produced by the alignment stage.
    """
    _alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)
    query_alignment_template = os.path.join(_alignment_dir,
                                            "{pruning}",
                                            get_common_queryname_template(config) + ".fasta")
    return expand(query_alignment_template, **get_common_template_args(config))


def build_placements_workflow():
    """
    Builds expected outputs from tested placement software ("test_soft" field in the config file)
    """

    l=list()

    # tree optimization
    l.extend(
        expand(
            config["workdir"] + "/T/{pruning}_optimised.tree",
            pruning = range(config["pruning_count"])
        )
    )

    # hmm alignments for alignment-based methods
    # TODO: implement it with pewo.software types
    require_alignment = ["epa", "epang", "pplacer", "apples"]
    # check if there is any software that requires alignment
    if any(soft in config["test_soft"] for soft in require_alignment):
        l.extend(_get_query_alignment_output())

    # pplacer placements
    if "pplacer" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                msppl=config["config_pplacer"]["max-strikes"],
                sbppl=config["config_pplacer"]["strike-box"],
                mpppl=config["config_pplacer"]["max-pitches"]
            )
        )
    #epa placements
    if "epa" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/EPA/{pruning}/g{gepa}/{pruning}_r{length}_g{gepa}_epa.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                gepa=config["config_epa"]["G"]
            )
        )
    #epa-ng placements
    if "epang" in config["test_soft"] :
        l.append(
            #different heuristics can be called, leading to different results and completely different runtimes
            select_epang_heuristics()
        )
    #apples placements
    if "apples" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                meth=config["config_apples"]["methods"],
                crit=config["config_apples"]["criteria"]
            )
        )
    #rappas placements
    #for accuracy evaluation, the dbinram mode is used to avoid redundant database constructions
    #(basically bulding a DB once per pruning/parameters combination)
    if "rappas" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas.jplace",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"],
                arsoft=config["config_rappas"]["arsoft"]
            )
        )

    if "rappas2" in config["test_soft"]:
        l.append(
            expand(
                config["workdir"]+"/RAPPAS2/{pruning}/red{reduction}_ar{arsoft}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas.jplace",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"],
                arsoft=config["config_rappas"]["arsoft"]
            )
        )

    return l


'''
define plots that will be computed in 'accuracy' mode
'''
def accuracy_plots_ND_outputs():
    l=list()
    #epa-ng
    if "epang" in config["test_soft"] :
        l.append( expand(config["workdir"]+"/summary_plot_ND_epang_{heuristic}.svg",heuristic=config["config_epang"]["heuristics"]) )
        l.append( expand(config["workdir"]+"/summary_table_ND_epang_{heuristic}.csv",heuristic=config["config_epang"]["heuristics"]) )
    #all other software
    l.append( expand(config["workdir"]+"/summary_plot_ND_{soft}.svg",soft=[x for x in config["test_soft"] if x!="epang"]) )
    l.append( expand(config["workdir"]+"/summary_table_ND_{soft}.csv",soft=[x for x in config["test_soft"] if x!="epang"]) )
    return l

'''
define plots that will be computed in 'accuracy' mode
'''
def accuracy_plots_eND_outputs():
    l=list()
    #epa-ng
    if "epang" in config["test_soft"] :
        l.append( expand(config["workdir"]+"/summary_plot_eND_epang_{heuristic}.svg",heuristic=config["config_epang"]["heuristics"]) )
        l.append( expand(config["workdir"]+"/summary_table_eND_epang_{heuristic}.csv",heuristic=config["config_epang"]["heuristics"]) )
    #all other software
    l.append( expand(config["workdir"]+"/summary_plot_eND_{soft}.svg",soft=[x for x in config["test_soft"] if x!="epang"]) )
    l.append( expand(config["workdir"]+"/summary_table_eND_{soft}.csv",soft=[x for x in config["test_soft"] if x!="epang"]) )
    return l

'''
define plots that will be computed in 'resources' mode
'''
def resource_plots_outputs():
    l=list()
    l.append( expand(config["workdir"]+"/benchmarks.csv"))
    return l
