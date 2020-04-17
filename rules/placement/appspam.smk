"""
Module to operate placements with APPSPAM
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

_appspam_place_benchmark_template = get_benchmark_template(config, PlacementSoftware.APPSPAM,
                                                          p="pruning", length="length", mode="mode", d="d",
                                                          rule_name="placement") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""

appspam_benchmark_templates = [_appspam_place_benchmark_template]
appspam_benchmark_template_args = [get_output_template_args(config, PlacementSoftware.APPSPAM),]


# FIXME: These are the same methods as in the epang.smk
def _get_appspam_input_reads(config) -> str:
    return os.path.join(_alignment_dir, "{pruning}", get_common_queryname_template(config) + ".fasta_refs")


def _get_appspam_input_queries(config) -> str:
    return os.path.join(_alignment_dir, "{pruning}", get_common_queryname_template(config) + ".fasta_queries")

def _get_appspam_input_tree() -> str:
    return os.path.join(_working_dir, "T", "{pruning}.tree")

rule placement_appspam:
    input:
        r=_get_appspam_input_reads(config),
        q=_get_appspam_input_queries(config),
        t=_get_appspam_input_tree(),
    output:
        jplace=get_output_template(config, PlacementSoftware.APPSPAM, "jplace")
    log:
        get_log_template(config, PlacementSoftware.APPSPAM)
    benchmark:
        repeat(_appspam_place_benchmark_template, config["repeats"])
    version: "1.0"
    shell:
        """
        fswm -i {input.r} -q {input.q} -t {input.t} -m {wildcards.mode} -d {wildcards.d} -o {output.jplace}
        """