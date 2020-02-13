"""
module to operate placements with EPA-ng
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

# TODO: Add support of model parameters once the module for pruned tree optimisation is done
# TODO: Use optimised tree version

import os
import pewo.config as cfg
from pewo.software import PlacementSoftware, AlignmentSoftware
from pewo.templates import get_output_template, get_log_template, get_software_dir, \
    get_common_queryname_template, get_experiment_dir_template, get_benchmark_template

_working_dir = cfg.get_work_dir(config)
_epang_soft_dir = get_software_dir(config, PlacementSoftware.EPA_NG)

# FIXME: Unnecessary dependendancy on the alignment software
_alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)


def _make_epang_command(**kwargs) -> str:
    """
    All the rules for EPA-NG run essentially the same sequence of commands, differed by
    one option for a heuristic used. This function creates such a sequence.
    """

    # get the heuristic
    heuristic = kwargs.get("heuristic", None)
    assert heuristic in ["h1", "h2", "h3", "h4"]

    # enable or disable premasking
    premask_option = "--no-pre-mask " if config["config_epang"]["premask"] == 0 else ""

    # add the heuristic option
    if heuristic == "h1":
        heuristic_option = "-g {wildcards.gepang} "
    elif heuristic == "h2":
        heuristic_option = "-G {wildcards.biggepang} "
    elif heuristic == "h3":
        heuristic_option = "--baseball-heur "
    else:
        heuristic_option = "--no-heur "

    # make the EPA-NG command
    epang_command = "epa-ng " \
                    "--redo " \
                    + premask_option + \
                    "--preserve-rooting on " \
                    "--filter-max {params.maxp} " \
                    "--filter-min-lwr {params.minlwr} " \
                    + heuristic_option + \
                    "--verbose " \
                    "-w {params.tmpdir} " \
                    "-q {input.q} " \
                    "-t {input.t} " \
                    "--ref-msa {input.r} " \
                    "-T 1 " \
                    "-m {input.m} " \
                    "&> {log.logfile}"

    # make a resulting sequence of commands
    return ";\n".join(c for c in ["mkdir -p {params.tmpdir}",
                                  epang_command,
                                  "mv {params.tmpdir}/epa_info.log {log.logfile}",
                                  "mv {params.tmpdir}/epa_result.jplace {output.jplace}",
                                  ]
                      )


def _get_epang_input_reads(config) -> str:
    return os.path.join(_alignment_dir, "{pruning}", get_common_queryname_template(config) + ".fasta_refs")


def _get_epang_input_queries(config) -> str:
    return os.path.join(_alignment_dir, "{pruning}", get_common_queryname_template(config) + ".fasta_queries")


def _get_epang_input_tree() -> str:
    return os.path.join(_working_dir, "T", "{pruning}.tree")


def _get_epang_input_info() -> str:
    return os.path.join(_working_dir, "T", "{pruning}_optimised.info")


rule placement_epang_h1:
    '''
    operate placement
    note: epa-ng does not allow to set a name for outputs, it always uses epa_info.log and epa_result.log
    moreover, it will refuse to rerun if epa-info.log is present, this obliges to built a temporary working directory
    for each launch (if not concurrent launches will fail if epa_info.log is present or worse write in the same file
    if --redo option is used).
    '''
    input:
        r=_get_epang_input_reads(config),
        q=_get_epang_input_queries(config),
        t=_get_epang_input_tree(),
        m=_get_epang_input_info()
    output:
        jplace=get_output_template(config, PlacementSoftware.EPA_NG, "jplace", heuristic="h1")
    log:
        logfile=get_log_template(config, PlacementSoftware.EPA_NG, heuristic="h1")
    #benchmark:
    #    repeat(get_benchmark_template(config, PlacementSoftware.EPA_NG, heuristic="h1"), config["repeats"])
    version: "1.0"
    params:
        tmpdir=get_experiment_dir_template(config, PlacementSoftware.EPA_NG, heuristic="h1"),
        dir=os.path.join(_epang_soft_dir, "{pruning}", "h1"),
        maxp=config["maxplacements"],
        minlwr=config["minlwr"]
    run:
        shell(_make_epang_command(heuristic="h1"))

rule placement_epang_h2:
    '''
    operate placement
    note: epa-ng does not allow to set a name for outputs, it always uses epa_info.log and epa_result.log
    moreover, it will refuse to rerun if epa-info.log is present, this obliges to built a temporary working directory
    for each launch (if not concurrent launches will fail if epa_info.log is present or worse write in the same file
    if --redo option is used).
    '''
    input:
        r=_get_epang_input_reads(config),
        q=_get_epang_input_queries(config),
        t=_get_epang_input_tree(),
        m=_get_epang_input_info()
    output:
        jplace=get_output_template(config, PlacementSoftware.EPA_NG, "jplace", heuristic="h2")
    log:
        logfile=get_log_template(config, PlacementSoftware.EPA_NG, heuristic="h2")
    #benchmark:
    #    repeat(get_benchmark_template(config, PlacementSoftware.EPA_NG, heuristic="h2"),config["repeats"])
    version: "1.0"
    params:
        tmpdir=get_experiment_dir_template(config, PlacementSoftware.EPA_NG, heuristic="h2"),
        dir=os.path.join(_epang_soft_dir, "{pruning}", "h2"),
        maxp=config["maxplacements"],
        minlwr=config["minlwr"]
    run:
        shell(_make_epang_command(heuristic="h2"))

rule placement_epang_h3:
    '''
    operate placement
    note: epa-ng does not allow to set a name for outputs, it always uses epa_info.log and epa_result.log
    moreover, it will refuse to rerun if epa-info.log is present, this obliges to built a temporary working directory
    for each launch (if not concurrent launches will fail if epa_info.log is present or worse write in the same file
    if --redo option is used).
    '''
    input:
        r=_get_epang_input_reads(config),
        q=_get_epang_input_queries(config),
        t=_get_epang_input_tree(),
        m=_get_epang_input_info()
    output:
        jplace=get_output_template(config, PlacementSoftware.EPA_NG, "jplace", heuristic="h3")
    log:
        logfile=get_log_template(config, PlacementSoftware.EPA_NG, heuristic="h3")
    #benchmark:
    #    repeat(get_benchmark_template(config, PlacementSoftware.EPA_NG, heuristic="h3"), config["repeats"])
    version: "1.0"
    params:
        tmpdir=get_experiment_dir_template(config, PlacementSoftware.EPA_NG, heuristic="h3"),
        dir=os.path.join(_epang_soft_dir, "{pruning}", "h3"),
        maxp=config["maxplacements"],
        minlwr=config["minlwr"]
    run:
        shell(_make_epang_command(heuristic="h3"))

rule placement_epang_h4:
    '''
    operate placement
    note: epa-ng does not allow to set a name for outputs, it always uses epa_info.log and epa_result.log
    moreover, it will refuse to rerun if epa-info.log is present, this obliges to built a temporary working directory
    for each launch (if not concurrent launches will fail if epa_info.log is present or worse write in the same file
    if --redo option is used).
    '''
    input:
        r=_get_epang_input_reads(config),
        q=_get_epang_input_queries(config),
        t=_get_epang_input_tree(),
        m=_get_epang_input_info()
    output:
        jplace=get_output_template(config, PlacementSoftware.EPA_NG, "jplace", heuristic="h4")
    log:
        logfile=get_log_template(config, PlacementSoftware.EPA_NG, heuristic="h4")
    #benchmark:
    #    repeat(get_benchmark_template(config, PlacementSoftware.EPA_NG, heuristic="h4"), config["repeats"])
    version: "1.0"
    params:
        tmpdir=get_experiment_dir_template(config, PlacementSoftware.EPA_NG, heuristic="h4"),
        dir=os.path.join(_epang_soft_dir, "{pruning}", "h4"),
        maxp=config["maxplacements"],
        minlwr=config["minlwr"]
    run:
        shell(_make_epang_command(heuristic="h4"))
