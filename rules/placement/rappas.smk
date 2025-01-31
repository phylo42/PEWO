"""
This module makes placements with RAPPAS
Note: this module expect AR to be already computed
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import os
from pathlib import Path
import pewo.config as cfg
from pewo.software import PlacementSoftware, get_ar_binary
from pewo.templates import get_output_template, get_log_template, get_experiment_dir_template, \
    get_ar_output_templates, get_benchmark_template, get_output_template_args, get_experiment_log_dir_template


_working_dir = cfg.get_work_dir(config)
_rappas_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.RAPPAS)

# Benchmark templates
_rappas_build_benchmark_template = get_benchmark_template(config, PlacementSoftware.RAPPAS,
    p="pruning", k="k", o="o", red="red", ar="ar",
    rule_name="dbbuild") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""
_rappas_place_benchmark_template = get_benchmark_template(config, PlacementSoftware.RAPPAS,
    p="pruning", length="length", k="k", o="o", red="red", ar="ar",
    rule_name="placement")  if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""

rappas_benchmark_templates = [_rappas_build_benchmark_template, _rappas_place_benchmark_template]

# Benchmark template args
_rappas_build_benchmark_template_args = get_output_template_args(config, PlacementSoftware.RAPPAS)
_rappas_build_benchmark_template_args.pop("length")
_rappas_place_benchmark_template_args = get_output_template_args(config, PlacementSoftware.RAPPAS)

rappas_benchmark_template_args = [
    _rappas_build_benchmark_template_args,
    _rappas_place_benchmark_template_args
]


def get_rappas_input_reads(pruning):
    """
    Creates a list of input reads files. For generated reads from a pruning,
    all read lengths are passed in a single RAPPAS execution.
    Read lengths can not be wildcards and must be set manually
    """
    output_dir = os.path.join(_working_dir, "R")

    # one read per fasta
    if cfg.get_mode(config) == cfg.Mode.LIKELIHOOD:
        return [os.path.join(output_dir, "{query}_r0.fasta")]
    # multiple reads per fasta
    else:
        # FIXME:
        # This is a dependency on pewo.templates.get_common_queryname_template result.
        # Look for a decent way to get rid of it.
        return [os.path.join(output_dir, pruning + "_r" + str(l) + ".fasta")
                for l in config["read_length"]]


print(_rappas_experiment_dir)
print(_rappas_build_benchmark_template)

# model parameters do not need to be passed, as they are useful only at AR
rule db_build_rappas:
    """
    Builds a RAPPAS database.
    """
    input:
        a = os.path.join(_working_dir, "A", "{pruning}.align"),
        t = os.path.join(_working_dir, "T", "{pruning}.tree"),
        ar = lambda wildcards: get_ar_output_templates(config, wildcards.ar)
    output:
        database = os.path.join(_rappas_experiment_dir, "DB.bin")
    log:
        os.path.join(get_experiment_log_dir_template(config, PlacementSoftware.RAPPAS),
                     "k{k}_o{o}_red{red}_ar{ar}.log")
    #benchmark:
    #    repeat(_rappas_build_benchmark_template, config["repeats"])
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/red{red}_ar{ar}/AR",
        workdir=_rappas_experiment_dir,
        dbfilename="DB.bin",
        arbin=lambda wildcards: get_ar_binary(config, wildcards.ar)
    run:
         shell(
            "java -Xms2G -Xmx"+str(config["config_rappas"]["memory"])+"G -jar $(which RAPPAS.jar) -v 0 -p b -b $(which {params.arbin}) "
            "-k {wildcards.k} --omega {wildcards.o} -t {input.t} -r {input.a} "                                                          
            "--gap-jump-thresh 1.0 "
            "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {wildcards.red} "
            "--use_unrooted --dbfilename {params.dbfilename} &> {log}"
         )

if cfg.get_mode(config) == cfg.Mode.RESOURCES:
    rule db_build_rappas:
        benchmark:
            repeat(_rappas_build_benchmark_template, config["repeats"])


rule placement_rappas:
    input:
        database = os.path.join(_rappas_experiment_dir, "DB.bin"),
        r = lambda wildcards: get_rappas_input_reads(wildcards.pruning),
    output:
        jplace = get_output_template(config, PlacementSoftware.RAPPAS, "jplace")
    log:
        get_log_template(config, PlacementSoftware.RAPPAS)
    
    params:
        workdir = _rappas_experiment_dir,
        maxp = config["maxplacements"],
        minlwr = config["minlwr"]
    run:
        memory = config['config_rappas']['memory']
        rappas_command = "java -Xms2G " + \
                         f"-Xmx{memory}G " + \
                         "-jar $(which RAPPAS.jar) " + \
                         "--keep-at-most {params.maxp} " + \
                         "--keep-factor {params.minlwr} " + \
                         "-v 1 " + \
                         "-p p " + \
                         "-d {input.database} " + \
                         "-q {input.r} " + \
                         "-w {params.workdir} " + \
                         "&> {log}"
        query_wildcard = "{wildcards.query}" if cfg.get_mode(config) == cfg.Mode.LIKELIHOOD else "{wildcards.pruning}"
        move_command = "mv {params.workdir}/placements_" + query_wildcard + "_r{wildcards.length}.fasta.jplace " + \
                       "{params.workdir}/" + \
                       query_wildcard + \
                       "_r{wildcards.length}_k{wildcards.k}_o{wildcards.o}_red{wildcards.red}_ar{wildcards.ar}_rappas.jplace"
        pipeline = ";".join(_ for _ in [rappas_command, move_command])
        shell(pipeline)
        
if cfg.get_mode(config) == cfg.Mode.RESOURCES:
    rule placement_rappas:
        benchmark:
                repeat(_rappas_place_benchmark_template, config["repeats"])