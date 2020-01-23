"""
Functions related to workflow constructions,
e.g. define snakemake outputs depending on tested software
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import os
import itertools
from typing import List
import pewo.config as cfg
from pewo.software import AlignmentSoftware, PlacementSoftware
from pewo.templates import get_software_dir, get_common_queryname_template, get_common_template_args,\
    get_output_template, get_output_template_args



def accuracy_plots_nd_outputs() -> List[str]:
    """
    Creates a list of plot files that will be computed in the accuracy mode.
    """
    l=list()
    #epa-ng
    if "epang" in config["test_soft"] :
        l.append( expand(config["workdir"]+"/summary_plot_ND_epang_{heuristic}.svg",heuristic=config["config_epang"]["heuristics"]) )
        l.append( expand(config["workdir"]+"/summary_table_ND_epang_{heuristic}.csv",heuristic=config["config_epang"]["heuristics"]) )
    #all other software
    l.append( expand(config["workdir"]+"/summary_plot_ND_{soft}.svg",soft=[x for x in config["test_soft"] if x!="epang"]) )
    l.append( expand(config["workdir"]+"/summary_table_ND_{soft}.csv",soft=[x for x in config["test_soft"] if x!="epang"]) )
    return l


def accuracy_plots_end_outputs() -> List[str]:
    """
    Creates a list of plot files that will be computed in the accuracy mode
    """
    l=list()
    #epa-ng
    if "epang" in config["test_soft"] :
        l.append( expand(config["workdir"]+"/summary_plot_eND_epang_{heuristic}.svg",heuristic=config["config_epang"]["heuristics"]) )
        l.append( expand(config["workdir"]+"/summary_table_eND_epang_{heuristic}.csv",heuristic=config["config_epang"]["heuristics"]) )
    #all other software
    l.append( expand(config["workdir"]+"/summary_plot_eND_{soft}.svg",soft=[x for x in config["test_soft"] if x!="epang"]) )
    l.append( expand(config["workdir"]+"/summary_table_eND_{soft}.csv",soft=[x for x in config["test_soft"] if x!="epang"]) )
    return l


def get_likelihood_plots_outputs() -> List[str]:
    """
    Define plots that will be computed in the likelihood mode
    """
    _working_dir = cfg.get_work_dir(config)

    #FIXME: Add heuristic-based output names for EPA-NG
    software_list = [software for software in config["test_soft"] if software != "epang"]

    tables = expand("/summary_table_LL_{software}.csv", software = software_list)
    plots = expand("/summary_plot_LL_{software}.svg", software = software_list)

    return list(itertools.chain(tables, plots))



def resource_plots_outputs() -> List[str]:
    """
    Creates a list of plot files that will be computed in the resources mode
    """
    return [config["workdir"]+"/ressource_results.tsv"]


'''
accessory function to correctly set which epa-ng heuristics are tested and with which parameters
'''
def select_epang_heuristics_benchmarks():
    l=[]
    if "h1" in config["config_epang"]["heuristics"]:
        l.append(
            expand(     config["workdir"]+"/benchmarks/{pruning}_r{length}_h1_g{gepang}_epang_benchmark.tsv",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        gepang=config["config_epang"]["h1"]["g"]
                   )
        )
    if "h2" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/benchmarks/{pruning}_r{length}_h2_bigg{biggepang}_epang_benchmark.tsv",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        biggepang=config["config_epang"]["h2"]["G"]
                        )
        )
    if "h3" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/benchmarks/{pruning}_r{length}_h3_epang_benchmark.tsv",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"]
                        )
        )
    if "h4" in config["config_epang"]["heuristics"]:
        l.append(
            expand(
                config["workdir"]+"/benchmarks/{pruning}_r{length}_h4_epang_benchmark.tsv",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"]
                )
            )
    return l


def build_accuracy_workflow() -> List[str]:
    """
    Creates a list of output files for the accuracy workflow.
    """
    # .jplace files
    placements = build_placements_workflow()

    # node distances from jplace outputs
    csv = [config["workdir"] + "/results.csv"]

    # collection of results and generation of summary plots
    node_distance_reports = accuracy_plots_nd_outputs()
    expected_node_distance_reports = accuracy_plots_end_outputs()

    return list(itertools.chain(placements, csv, node_distance_reports, expected_node_distance_reports))


def build_resources_workflow() -> List[str]:
    """
    builds the list of outputs,for a "resources" workflow
    """
    l=list()
    #call outputs from operate_inputs module to build input reads as pruning=0 and r=0
    l.append(config["workdir"] + "/A/0.align")
    l.append(config["workdir"] + "/T/0.tree")
    l.append(config["workdir"] + "/G/0.fasta")
    l.append(config["workdir"] + "/R/0_r0.fasta")

    #placements
    l.append(
        build_placements_workflow()
    )
    #benchmarks
    l.append(build_benchmarks_workflow())
    #collection of results and generation of summary plots
    l.append(resource_plots_outputs())
    return l


def build_likelihood_workflow() -> List[str]:
    """
    Creates a list of output files for the likelihood workflow
    """
    # .jplace output files
    placements = build_placements_workflow()

    # likelihood values from jplace outputs
    csvs = [config["workdir"] + "/likelihood.csv"]

    return list(itertools.chain(placements, csvs))


def _get_aligned_queries() -> List[str]:
    """
    Returns the list of .fasta files of aligned query files. These files
    must be produced by the alignment stage.
    """
    _alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)
    query_alignment_template = os.path.join(_alignment_dir,
                                            "{pruning}",
                                            get_common_queryname_template(config) + ".fasta")
    return expand(query_alignment_template, **get_common_template_args(config))



def _get_jplace_outputs(config: Dict, software: PlacementSoftware) -> List[str]:
    """
    Creates a list of .jplace output files produced by specific software.
    """
    return expand(get_output_template(config, software, "jplace"),
                  **get_output_template_args(config, software))


def get_jplace_outputs() -> List[str]:
    """
    Creates a list of all .jplace files that are produced by all placement software
    """
    inputs = []

    if "epa" in config["test_soft"]:
        inputs.extend(_get_jplace_outputs(config, PlacementSoftware.EPA))
    if "pplacer" in config["test_soft"]:
        inputs.extend(_get_jplace_outputs(config, PlacementSoftware.PPLACER))
    if "epang" in config["test_soft"]:
        inputs.extend(select_epang_heuristics())
    if "rappas" in config["test_soft"]:
        inputs.extend(_get_jplace_outputs(config, PlacementSoftware.RAPPAS))
    if "apples" in config["test_soft"]:
        inputs.extend(
            expand(
                config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                meth=config["config_apples"]["methods"],
                crit=config["config_apples"]["criteria"]
            )
        )
    return inputs

def build_placements_workflow() -> List[str]:
    """
    Builds expected outputs from tested placement software ("test_soft" field in the config file)
    """
    # list of optimized trees
    trees = expand(config["workdir"] + "/T/{pruning}_optimised.tree",
                   pruning = range(config["pruning_count"]))

    # hmm alignments for alignment-based methods
    # TODO: implement it with pewo.software types
    alignments = []
    require_alignment = ["epa", "epang", "pplacer", "apples"]
    # check if there is any software that requires alignment
    if any(soft in config["test_soft"] for soft in require_alignment):
        alignments = _get_aligned_queries()

    # get .jplace files produced by all tested software
    placements = get_jplace_outputs()

    return list(itertools.chain(trees, alignments, placements))


'''
define expected benchmark outputs, which are written by snakemake in workdir/benchmarks 
'''
def build_benchmarks_workflow() -> List[str]:
    l=list()
    #hmm alignments for alignment-based methods
    if ("epa" in config["test_soft"]) or ("epang" in config["test_soft"]) or ("pplacer" in config["test_soft"]) or ("apples" in config["test_soft"]) :
        l.append(
            expand(
                config["workdir"]+"/benchmarks/{pruning}_r{length}_hmmalign_benchmark.tsv",
                pruning=range(0,config["pruning_count"],1),
                length=config["read_length"]
            )
        )
    #pplacer placements
    if "pplacer" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/benchmarks/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer_benchmark.tsv",
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
                config["workdir"]+"/benchmarks/{pruning}_r{length}_g{gepa}_epa_benchmark.tsv",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                gepa=config["config_epa"]["G"]
            )
        )
    #epa-ng placements
    if "epang" in config["test_soft"] :
        l.append(
            #different heuristics can be called, leading to different results and completely different runtimes
            select_epang_heuristics_benchmarks()
        )
    #apples placements
    if "apples" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/benchmarks/{pruning}_r{length}_m{meth}_c{crit}_apples_benchmark.tsv",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                meth=config["config_apples"]["methods"],
                crit=config["config_apples"]["criteria"]
            )
        )
    #rappas
    #for resource evaluation, AR, dbbuild and placement are split for independent measures
    if "rappas" in config["test_soft"] :
        #ar
        l.append(
            expand(
                config["workdir"]+"/benchmarks/{pruning}_red{reduction}_ar{arsoft}_ansrec_benchmark.tsv",
                pruning=range(0,config["pruning_count"]),
                reduction=config["config_rappas"]["reduction"],
                arsoft=config["config_rappas"]["arsoft"]
            )
        )
        #dbbuild
        l.append(
            expand(
                config["workdir"]+"/benchmarks/{pruning}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas-dbbuild_benchmark.tsv",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                reduction=config["config_rappas"]["reduction"],
                arsoft=config["config_rappas"]["arsoft"]
            )
        )
        #placement
        l.append(
            expand(
                config["workdir"]+"/benchmarks/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas-placement_benchmark.tsv",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"],
                arsoft=config["config_rappas"]["arsoft"]
            )
        )
    return l
