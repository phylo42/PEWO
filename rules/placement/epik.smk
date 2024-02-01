"""
This module makes placements with EPIK.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
from pathlib import Path
import numpy as np
import pewo.config as cfg
from pewo.software import PlacementSoftware, get_ar_binary
from pewo.templates import get_output_template, get_log_template, get_experiment_dir_template, \
    get_ar_output_templates, get_benchmark_template, get_output_template_args


_working_dir = cfg.get_work_dir(config)
_ipk_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.IPK)
_epik_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.EPIK)

# In PEWO, IPK takes results of tree extension and ancestral reconstruction done by RAPPAS
# to avoid doing this twice if both programs are evaluated
_rappas_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.RAPPAS)
_rappas_experiment_parent = Path(_rappas_experiment_dir).parent


def has_epik():
    return "config_epik" in config

# Benchmark templates
_ipk_benchmark_template = get_benchmark_template(config, PlacementSoftware.EPIK,
    p="pruning", k="k", red="red", ar="ar", filter="filter", ghosts="ghosts",
    rule_name="build") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""
_epik_benchmark_template = get_benchmark_template(config, PlacementSoftware.EPIK,
    p="pruning", length="length", k="k", o="o", red="red", ar="ar", filter="filter", 
    mu="mu", ghosts="ghosts",
    rule_name="placement")  if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""

if has_epik():
    epik_benchmark_templates = [_ipk_benchmark_template, _epik_benchmark_template]

    # Benchmark template args
    _ipk_benchmark_template_args = get_output_template_args(config, PlacementSoftware.EPIK) if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""
    _ipk_benchmark_template_args.pop("length")
    _epik_benchmark_template_args = get_output_template_args(config, PlacementSoftware.EPIK)

    epik_benchmark_template_args = [
        _ipk_benchmark_template_args,
        _epik_benchmark_template_args
    ]
else:
    epik_benchmark_templates = []
    epik_benchmark_template_args = []




def get_minimal_value(values):
    if isinstance(values, float):
        return values
    elif isinstance(values, list):
        return np.min(values)
    else:
        raise RuntimeError(f"Internal PEWO error: could not parse values {values}")

def get_epik_input_templates(config, wildcards):
    return  os.path.join(_ipk_experiment_dir, "DB_k{k}.ipk")

def get_ipk_output_templates(config):
    #minimal_omega = get_minimal_value(config["config_epik"]["omega"])
    return os.path.join(
        get_experiment_dir_template(config, PlacementSoftware.IPK),
        "DB_k{k}.ipk"
    )

rule ipk:
    """
    Build a phylo-k-mer database with IPK.
    """
    # model parameters do not need to be passed, as they are useful only at AR
    input:
        a = os.path.join(_working_dir, "A", "{pruning}.align"),
        t = os.path.join(_working_dir, "T", "{pruning}.tree"),
        ar = lambda wildcards: get_ar_output_templates(config, wildcards.ar)
    output:
        get_ipk_output_templates(config)
    log:
        os.path.join(_ipk_experiment_dir, "db_build.log")
    benchmark:
        repeat(_ipk_benchmark_template, config["repeats"])
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        model = select_model_phymlstyle(),
        ardir = os.path.join(Path(_rappas_experiment_dir).parent, "AR"),
        workdir = _ipk_experiment_dir,
        arbin = lambda wildcards: get_ar_binary(config, wildcards.ar),
        #arthreads = config["config_epik"]["arthreads"],

        # Build a database with the minimal omega value.
        # Higher omega values will be dealt with by EPIK via dynamic load
        minimal_omega = get_minimal_value(config["config_epik"]["omega"]) if has_epik() else 0.0
    run:
        filter = wildcards.filter.lower() if wildcards.filter else "no-filter"
        ghosts = wildcards.ghosts.lower() if wildcards.ghosts else "both"
        shell(
            "ipk.py build " +
            "--states {params.states} " +
            "-b $(which {params.arbin}) " +
            "-k {wildcards.k} " +
            "--omega {params.minimal_omega} " +
            "-m {params.model} "
            "-t {input.t} " +
            "-r {input.a} " +
            "--filter {filter} " +
            "--ghosts {ghosts} " +
            "-w {params.workdir} " +
            #"--threads {params.arthreads} " +
            "--ar-dir {params.ardir} " +
            "--reduction-ratio {wildcards.red} " +
            "--use-unrooted  &> {log} "
        )
        shell("mv {params.workdir}/DB.ipk {params.workdir}/DB_k{wildcards.k}.ipk")

rule placement_epik:
    input:
        database = lambda wildcards: get_epik_input_templates(config, wildcards),
        r = lambda wildcards: get_rappas_input_reads(wildcards.pruning)
    output:
        jplace = get_output_template(config, PlacementSoftware.EPIK, "jplace")
    log:
        get_log_template(config, PlacementSoftware.EPIK)
    benchmark:
        repeat(_epik_benchmark_template, config["repeats"])
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        workdir = _epik_experiment_dir,
        maxp = config["maxplacements"],
        minlwr = config["minlwr"]
    run:
        ghosts = wildcards.ghosts.lower() if wildcards.ghosts else "both"
        epik_command = "epik.py place " + \
            "--states {params.states} " + \
            "-i {input.database} " + \
            "-o {params.workdir} " + \
            "--mu {wildcards.mu} " + \
            "--omega {wildcards.o} " + \
            "--threads 1 " + \
            "{input.r} " + \
            "&> {log} "
        query_wildcard = "{wildcards.query}" if cfg.get_mode(config) == cfg.Mode.LIKELIHOOD else "{wildcards.pruning}"
        move_command = "mv {params.workdir}/placements_" + query_wildcard + "_r{wildcards.length}.fasta.jplace " + \
                       "{params.workdir}/" + \
                       query_wildcard + \
                       "_r{wildcards.length}_k{wildcards.k}_o{wildcards.o}_red{wildcards.red}_ar{wildcards.ar}_mu{wildcards.mu}_filter{wildcards.filter}_ghosts{wildcards.ghosts}_epik.jplace"
        shell(";".join(_ for _ in [epik_command, move_command]))
