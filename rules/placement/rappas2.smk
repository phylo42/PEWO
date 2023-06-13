"""
This module makes placements with RAPPAS2.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
from pathlib import Path
import pewo.config as cfg
from pewo.software import PlacementSoftware, get_ar_binary
from pewo.templates import get_output_template, get_log_template, get_experiment_dir_template, \
    get_ar_output_templates, get_benchmark_template, get_output_template_args


_working_dir = cfg.get_work_dir(config)
_rappas2_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.RAPPAS2)
_rappas_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.RAPPAS)
_rappas_experiment_parent = Path(_rappas_experiment_dir).parent



# Benchmark templates
_rappas2_build_benchmark_template = get_benchmark_template(config, PlacementSoftware.RAPPAS2,
    p="pruning", k="k", o="o", red="red", ar="ar", filter="filter", mu="mu",
    rule_name="build") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""
_rappas2_place_benchmark_template = get_benchmark_template(config, PlacementSoftware.RAPPAS2,
    p="pruning", length="length", k="k", o="o", red="red", ar="ar", filter="filter", mu="mu",
    rule_name="placement")  if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""

rappas2_benchmark_templates = [_rappas2_build_benchmark_template, _rappas2_place_benchmark_template]

# Benchmark template args
_rappas2_build_benchmark_template_args = get_output_template_args(config, PlacementSoftware.RAPPAS2)
_rappas2_build_benchmark_template_args.pop("length")
_rappas2_place_benchmark_template_args = get_output_template_args(config, PlacementSoftware.RAPPAS2)

rappas2_benchmark_template_args = [
    _rappas2_build_benchmark_template_args,
    _rappas2_place_benchmark_template_args
]

print(_rappas2_place_benchmark_template)
print(get_log_template(config, PlacementSoftware.RAPPAS2))

rule db_build_rappas2:
    """
    Build a RAPPAS database in RAM.
    """
    # model parameters do not need to be passed, as they are useful only at AR
    input:
        a = os.path.join(_working_dir, "A", "{pruning}.align"),
        t = os.path.join(_working_dir, "T", "{pruning}.tree"),
        ar = lambda wildcards: get_ar_output_templates(config, wildcards.ar)
    output:
        database = os.path.join(_rappas2_experiment_dir, "DB_k{k}_o{o}.rps")
    log:
        os.path.join(_rappas2_experiment_dir, "db_build.log")
    benchmark:
        repeat(_rappas2_build_benchmark_template, config["repeats"])
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        model = select_model_phymlstyle(),
        ardir = os.path.join(Path(_rappas_experiment_dir).parent, "AR"),
        workdir = _rappas2_experiment_dir,
        arbin = lambda wildcards: get_ar_binary(config, wildcards.ar),
        arthreads = config["config_rappas2"]["arthreads"]
    run:
        filter = wildcards.filter.lower() if wildcards.filter else "no-filter"
        ghosts = wildcards.ghosts.lower() if wildcards.ghosts else "both"
        shell(
            "xpas.py build " +
            "--states {params.states} " +
            "-b $(which {params.arbin}) " +
            "-k {wildcards.k} " +
            "--omega {wildcards.o} " +
            "-u {wildcards.mu} " +
            "-m {params.model} "
            "-t {input.t} " +
            "-r {input.a} " +
            "--filter {filter} " +
            "--ghosts {ghosts} " +
            "-w {params.workdir} " +
            "--threads {params.arthreads} " +
            "--ar-dir {params.ardir} " +
            "--reduction-ratio {wildcards.red} " +
            "--use-unrooted  &> {log} "
        )

rule placement_rappas2:
    input:
        database = os.path.join(_rappas2_experiment_dir, "DB_k{k}_o{o}.rps"),
        r = lambda wildcards: get_rappas_input_reads(wildcards.pruning)
    output:
        jplace = get_output_template(config, PlacementSoftware.RAPPAS2, "jplace")
    log:
        get_log_template(config, PlacementSoftware.RAPPAS2)
    benchmark:
        repeat(_rappas2_place_benchmark_template, config["repeats"])
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        workdir = _rappas2_experiment_dir,
        maxp = config["maxplacements"],
        minlwr = config["minlwr"]
    run:
        ghosts = wildcards.ghosts.lower() if wildcards.ghosts else "both"
        rappas_command = "epik.py place " + \
            "--states {params.states} " + \
            "-i {input.database} " + \
            "-o {params.workdir} " + \
            "--threads 1 " + \
            "{input.r} " + \
            "&> {log} "
        query_wildcard = "{wildcards.query}" if cfg.get_mode(config) == cfg.Mode.LIKELIHOOD else "{wildcards.pruning}"
        move_command = "mv {params.workdir}/placements_" + query_wildcard + "_r{wildcards.length}.fasta.jplace " + \
                       "{params.workdir}/" + \
                       query_wildcard + \
                       "_r{wildcards.length}_k{wildcards.k}_o{wildcards.o}_red{wildcards.red}_ar{wildcards.ar}_mu{wildcards.mu}_filter{wildcards.filter}_ghosts{wildcards.ghosts}_rappas2.jplace"
        shell(";".join(_ for _ in [rappas_command, move_command]))
