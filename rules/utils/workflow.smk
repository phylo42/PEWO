"""
Functions related to workflow constructions,
e.g. define snakemake outputs depending on tested software
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

import os
import itertools
from typing import List, Dict
import pewo.config as cfg
from pewo.software import AlignmentSoftware, PlacementSoftware
from pewo.templates import get_software_dir, get_common_queryname_template, get_common_template_args, \
    get_output_template, get_output_template_args

def get_accuracy_nd_plots() -> List[str]:
    """
    Creates a list of plot files that will be computed in the accuracy mode.
    """
    l = list()
    #epa-ng
    if "epang" in config["test_soft"]:
        l.append(expand(config["workdir"] + "/summary_plot_ND_epang_{heuristic}.svg",
                        heuristic=config["config_epang"]["heuristics"]))
        l.append(expand(config["workdir"] + "/summary_table_ND_epang_{heuristic}.csv",
                        heuristic=config["config_epang"]["heuristics"]))
    #all other software
    l.append(expand(config["workdir"] + "/summary_plot_ND_{soft}.svg",
                    soft=[x for x in config["test_soft"] if x != "epang"]))
    l.append(expand(config["workdir"] + "/summary_table_ND_{soft}.csv",
                    soft=[x for x in config["test_soft"] if x != "epang"]))
    return l


def get_accuracy_end_plots() -> List[str]:
    """
    Creates a list of plot files that will be computed in the accuracy mode
    """
    l = list()
    #epa-ng
    if "epang" in config["test_soft"]:
        l.append(expand(config["workdir"] + "/summary_plot_eND_epang_{heuristic}.svg",
                        heuristic=config["config_epang"]["heuristics"]))
        l.append(expand(config["workdir"] + "/summary_table_eND_epang_{heuristic}.csv",
                        heuristic=config["config_epang"]["heuristics"]))
    #all other software
    l.append(expand(config["workdir"] + "/summary_plot_eND_{soft}.svg",
                    soft=[x for x in config["test_soft"] if x != "epang"]))
    l.append(expand(config["workdir"] + "/summary_table_eND_{soft}.csv",
                    soft=[x for x in config["test_soft"] if x != "epang"]))
    return l


def get_likelihood_plots() -> List[str]:
    """
    Returns a list of plots that will be computed in the likelihood mode
    """
    _working_dir = cfg.get_work_dir(config)

    #FIXME: Add heuristic-based output names for EPA-NG
    software_list = [software for software in config["test_soft"] if software != "epang"]

    tables = expand(config["workdir"] + "/summary_table_LL_{software}.csv", software=software_list)
    plots = expand(config["workdir"] + "/summary_plot_LL_{software}.svg", software=software_list)

    return list(itertools.chain(tables, plots))


def get_resources_outputs() -> List[str]:
    return [os.path.join(config["workdir"], "resources.tsv")]


#def get_resources_plots() -> List[str]:
#    """
#    Returns a list of plots files that will be computed in the resources mode
#    """
#    return ["resources_results.tsv"]


def build_accuracy_workflow() -> List[str]:
    """
    Creates a list of output files for the accuracy workflow.
    """
    # .jplace files
    placements = build_placements_workflow()

    # node distances from jplace outputs
    csv = [config["workdir"] + "/results.csv"]

    # collection of results and generation of summary plots
    node_distance_reports = get_accuracy_nd_plots()
    expected_node_distance_reports = get_accuracy_end_plots()

    return list(itertools.chain(placements, csv, node_distance_reports, expected_node_distance_reports))


def build_resources_workflow() -> List[str]:
    """
    builds the list of outputs, for the resources workflow
    """
    l = []

    # call outputs from operate_inputs module to build input reads as pruning=0 and r=0
    l.append(config["workdir"] + "/A/0.align")
    l.append(config["workdir"] + "/T/0.tree")
    l.append(config["workdir"] + "/G/0.fasta")
    l.append(config["workdir"] + "/R/0_r0.fasta")

    # placements
    l.extend(build_placements_workflow())

    # benchmarks
    l.extend(build_benchmarks_workflow())

    # collection of results and generation of summary plots
    l.extend(get_resources_outputs())
    return l


def build_likelihood_workflow() -> List[str]:
    """
    Creates a list of output files for the likelihood workflow
    """
    # .jplace output files
    placements = build_placements_workflow()

    # likelihood values from jplace outputs
    csv = [os.path.join(config["workdir"], "likelihood.csv")]

    # plots
    likelihood_reports = get_likelihood_plots()

    return list(itertools.chain(placements, csv, likelihood_reports))


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


def _get_jplace_outputs(config: Dict, software: PlacementSoftware, **kwargs) -> List[str]:
    """
    Creates a list of .jplace output files produced by specific software.
    """
    return expand(get_output_template(config, software, "jplace", **kwargs),
                  **get_output_template_args(config, software, **kwargs))


def get_jplace_outputs(config) -> List[str]:
    """
    Creates a list of all .jplace files that are produced by all placement software
    """
    output_files = []

    for software_name in config["test_soft"]:
        software = PlacementSoftware.get_by_value(software_name)
        # FIXME
        if software == PlacementSoftware.EPANG:
            for h in config["config_epang"]["heuristics"]:
                output_files.extend(_get_jplace_outputs(config, software, heuristic=h))
        else:
            output_files.extend(_get_jplace_outputs(config, software))
    return output_files

def build_placements_workflow() -> List[str]:
    """
    Builds expected outputs from tested placement software ("test_soft" field in the config file)
    """
    # list of optimized trees
    trees = expand(config["workdir"] + "/T/{pruning}_optimised.tree",
                   pruning=range(config["pruning_count"]))

    # hmm alignments for alignment-based methods
    # TODO: implement it with pewo.software types
    alignments = []
    require_alignment = ["epa", "epang", "pplacer", "apples"]
    # check if there is any software that requires alignment
    if any(soft in config["test_soft"] for soft in require_alignment):
        alignments = _get_aligned_queries()

    # get .jplace files produced by all tested software
    placements = get_jplace_outputs(config)

    return list(itertools.chain(trees, alignments, placements))


def _get_resources_tsv(config: Dict, software: PlacementSoftware, **kwargs) -> List[str]:
    """
    Creates a list of .tsv output files containing benchmark results of given software.
    """
    result = []
    software_templates = []
    software_template_args = []
    if software == PlacementSoftware.RAPPAS:
        software_templates = rappas_benchmark_templates
        software_template_args = rappas_benchmark_template_args
    elif software == PlacementSoftware.EPA:
        software_templates = epa_benchmark_templates + hmmer_benchmark_templates
        software_template_args = epa_benchmark_template_args + hmmer_benchmark_template_args
    elif software == PlacementSoftware.EPANG:
        heuristics = ["h1", "h2", "h3", "h4"]

        software_templates = []
        software_template_args = []
        for h in config["config_epang"]["heuristics"]:
            h_index = heuristics.index(h)
            software_templates.append(epang_benchmark_templates[h_index])
            software_template_args.append(epang_benchmark_template_args[h_index])

    elif software == PlacementSoftware.PPLACER:
        software_templates = pplacer_benchmark_templates + hmmer_benchmark_templates
        software_template_args = pplacer_benchmark_template_args + hmmer_benchmark_template_args
    elif software == PlacementSoftware.APPLES:
        software_templates = apples_benchmark_templates + hmmer_benchmark_templates
        software_template_args = apples_benchmark_template_args + hmmer_benchmark_template_args
    elif software == PlacementSoftware.APPSPAM:
        software_templates = appspam_benchmark_templates
        software_template_args = appspam_benchmark_template_args
    else:
        raise RuntimeError("Unsupported software: " + software.value)

    for template, template_args in zip(software_templates, software_template_args):
        result.extend(expand(template, **template_args))
    return result


def get_resources_tsv(config) -> List[str]:
    """
    Creates a list of all .tsv files that are produced while benchmarking
    """
    output_files = []
    for software_name in config["test_soft"]:
        software = PlacementSoftware.get_by_value(software_name)
        # FIXME
        if software == PlacementSoftware.EPANG:
            for h in config["config_epang"]["heuristics"]:
                output_files.extend(_get_resources_tsv(config, PlacementSoftware.EPANG, heuristic=h))
        else:
            output_files.extend(_get_resources_tsv(config, software))
    return output_files


def build_benchmarks_workflow() -> List[str]:
    """
    Defines expected benchmark outputs, which are written by snakemake in workdir/benchmarks
    """
    return get_resources_tsv(config)
