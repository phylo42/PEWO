"""
This module operates placements with PPLACER.
It builds first a pplacer package with taxtastic, then computes placement using the package
"""


__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import os
from typing import Dict
import pewo.config as cfg
from pewo.software import PlacementSoftware, AlignmentSoftware
from pewo.templates import get_experiment_dir_template, get_software_dir, get_common_queryname_template, \
    get_output_template, get_log_template, get_benchmark_template, get_output_template_args


_working_dir = cfg.get_work_dir(config)
_pplacer_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.PPLACER)

# FIXME:
# Unnecessary dependendancy on the alignment software
_alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)


_pplacer_place_benchmark_template = get_benchmark_template(config, PlacementSoftware.PPLACER,
                                                           p="pruning", length="length", ms="ms",
                                                           sb="sb", mp="mp", rule_name="placement") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""

pplacer_benchmark_templates = [_pplacer_place_benchmark_template]
pplacer_benchmark_template_args = [get_output_template_args(config, PlacementSoftware.PPLACER)]


def _get_pplacer_refpkg_template(config: Dict) -> str:
    return os.path.join(get_software_dir(config, PlacementSoftware.PPLACER),
                        "{pruning}", "{pruning}_refpkg")


rule build_pplacer:
    """
    Build pplacer pkgs using taxtastic.
    Model parameters are loaded in pplacer via the 'info' file, the output of raxml optimisation
    """
    input:
        a = os.path.join(_working_dir, "A", "{pruning}.align"),
        t = os.path.join(_working_dir, "T", "{pruning}.tree"),
        s = os.path.join(_working_dir, "T", "{pruning}_optimised.info")
    output:
        directory(_get_pplacer_refpkg_template(config))
    log:
        os.path.join(_working_dir, "logs", "taxtastic", "{pruning}.log")
    params:
        refpkg_dir = _get_pplacer_refpkg_template(config)
    shell:
        "taxit create -P {params.refpkg_dir} -l locus -f {input.a} -t {input.t} -s {input.s} &> {log}"


rule placement_pplacer:
    """ 
    Runs placement using PPLACER.
    Note: pplacer option '--out-dir' is not functional, it writes the jplace in current directory
    which required the addition of the explicit 'cd'
    """
    input:
        alignment = os.path.join(_alignment_dir,
                                 "{pruning}",
                                 get_common_queryname_template(config) + ".fasta"),
        pkg = _get_pplacer_refpkg_template(config)
    output:
        jplace = get_output_template(config, PlacementSoftware.PPLACER, "jplace")
    log:
        get_log_template(config, PlacementSoftware.PPLACER)

    params:
        maxp = config["maxplacements"],
        minlwr = config["minlwr"]
    run:
        pplacer_command = "pplacer -o {output.jplace} --verbosity 1 --max-strikes {wildcards.ms}" \
                          " --strike-box {wildcards.sb} --max-pitches {wildcards.mp}" \
                          " --keep-at-most {params.maxp} --keep-factor {params.minlwr}"

        if not config["config_pplacer"]["premask"]:
            pplacer_command += " --no-pre-mask"

        pplacer_command += " -c {input.pkg} {input.alignment} &> {log}"
        shell(pplacer_command)

if cfg.get_mode(config) == cfg.Mode.RESOURCES:
    rule placement_pplacer:
        benchmark:
            repeat(_pplacer_place_benchmark_template, config["repeats"])