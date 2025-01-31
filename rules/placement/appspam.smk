"""
Module to operate placements with APPSPAM
"""

__author__ = "Matthias Blanke, Nikolai Romashchenko"
__license__ = "MIT"

import os
from typing import List
import pewo.config as cfg
from pewo.software import PlacementSoftware, AlignmentSoftware
from pewo.templates import get_output_template, get_log_template, get_software_dir, \
    get_common_queryname_template, get_benchmark_template, get_output_template_args

_working_dir = cfg.get_work_dir(config)
_appspam_place_benchmark_template = get_benchmark_template(config, PlacementSoftware.APPSPAM,
                                                          p="pruning", length="length", mode="mode", w="w", pattern="pattern",
                                                          rule_name="placement") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""

appspam_benchmark_templates = [_appspam_place_benchmark_template]
appspam_benchmark_template_args = [get_output_template_args(config, PlacementSoftware.APPSPAM),]

def _get_appspam_input_sequences(config) -> List[str]:
    return os.path.join(_working_dir, "A", "{pruning}.align")

def _get_appspam_input_queries(config) -> str:
    return os.path.join(_working_dir, "R", "{pruning}_r{length}.fasta")

def _get_appspam_input_tree() -> str:
    return os.path.join(_working_dir, "T", "{pruning}.tree")

rule placement_appspam:
    input:
        s=_get_appspam_input_sequences(config),
        q=_get_appspam_input_queries(config),
        t=_get_appspam_input_tree(),
    output:
        jplace=get_output_template(config, PlacementSoftware.APPSPAM, "jplace")
    log:
        get_log_template(config, PlacementSoftware.APPSPAM)
    benchmark:
        repeat(_appspam_place_benchmark_template, config["repeats"])
    shell:
        """
        appspam -s {input.s} -q {input.q} -t {input.t} -m {wildcards.mode} -w {wildcards.w} -p {wildcards.pattern} -o {output.jplace} >& {log}
        """
