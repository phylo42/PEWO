"""
Module to operate placements with APPLES
"""


__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

import os
import pewo.config as cfg
from pewo.software import PlacementSoftware, AlignmentSoftware
from pewo.templates import get_output_template, get_log_template, get_software_dir, \
    get_common_queryname_template, get_benchmark_template, get_output_template_args


_working_dir = cfg.get_work_dir(config)
_alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)

_apples_place_benchmark_template = get_benchmark_template(config, PlacementSoftware.APPLES,
                                                          p="pruning", length="length", meth="meth", crit="crit",
                                                          rule_name="placement") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""

apples_benchmark_templates = [_apples_place_benchmark_template]
apples_benchmark_template_args = [get_output_template_args(config, PlacementSoftware.APPLES),]


# FIXME: These are the same methods as in the epang.smk
def _get_apples_input_reads(config) -> str:
    return os.path.join(_alignment_dir, "{pruning}", get_common_queryname_template(config) + ".fasta_refs")

def _get_apples_input_queries(config) -> str:
    return os.path.join(_alignment_dir, "{pruning}", get_common_queryname_template(config) + ".fasta_queries")


def _get_apples_input_tree() -> str:
    return os.path.join(_working_dir, "T", "{pruning}.tree")


rule placement_apples:
    input:
        r=_get_apples_input_reads(config),
        q=_get_apples_input_queries(config),
        t=_get_apples_input_tree(),
    output:
        jplace=get_output_template(config, PlacementSoftware.APPLES, "jplace")
    params:
        is_protein = config["states"] == 0
    log:
        get_log_template(config, PlacementSoftware.APPLES)
    benchmark:
        repeat(_apples_place_benchmark_template, config["repeats"])
    version: "1.0"
    run:
        #
        command = "run_apples.py -s {input.r} -q {input.q} -t {input.t} -T 1 -m {wildcards.meth} -c {wildcards.crit} -o {output.jplace} "
        if {params.is_protein}:
            command += "-p "
        shell(command)
