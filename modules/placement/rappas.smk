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
    get_ar_output_templates, get_benchmark_template


_working_dir = cfg.get_work_dir(config)
_rappas_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.RAPPAS)


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


rule db_build_in_ram_rappas:
    """
    Build a RAPPAS database in RAM.
    """
    # model parameters do not need to be passed, as they are useful only at AR
    input:
        a = os.path.join(_working_dir, "A", "{pruning}.align"),
        t = os.path.join(_working_dir, "T", "{pruning}.tree"),
        r = lambda wildcards: get_rappas_input_reads(wildcards.pruning),
        ar = lambda wildcards: get_ar_output_templates(config, wildcards.arsoft)
    output:
        jplace = get_output_template(config, PlacementSoftware.RAPPAS, "jplace")
    log:
        get_log_template(config, PlacementSoftware.RAPPAS)
    version: "1.00"
    params:
        states = ["nucl"] if config["states"]==0 else ["amino"],

        # FIXME:
        # This probably should be changed, because it depends on the
        # implementation of get_experiment_dir_template for RAPPAS in pewo.templates.
        ardir = os.path.join(Path(_rappas_experiment_dir).parent, "AR"),
        workdir = _rappas_experiment_dir,
        dbfilename = "DB.bin",
        querystring = lambda wildcards, input: ",".join(input.r),
        maxp = config["maxplacements"],
        minlwr = config["minlwr"],
        arbin = lambda wildcards: get_ar_binary(config, wildcards.arsoft)
    run:
        shell(
            "java -Xms2G -Xmx" + str(config["config_rappas"]["memory"]) + "G -jar $(which RAPPAS.jar) -p b "
            "-b $(which {params.arbin}) "
            "-k {wildcards.k} --omega {wildcards.omega} -t {input.t} -r {input.a} -q {params.querystring} "
            "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {wildcards.reduction} "
            "--keep-at-most {params.maxp} --keep-factor {params.minlwr} "
            "--use_unrooted --dbinram --dbfilename {params.dbfilename} &> {log} "
        )

        # FIXME:
        # The output file templates here must be consistent with the ones produced by
        # pewo.templates.get_output_template. This dependence is obviously ugly and error-prone,
        # and should not be here. Should we generate the same {wildcard}-like templates there as well?
        # Another way could be to replace all wildcards like {name} to {wildcards.name} in the output of
        # pewo.templates.get_output_template.

        if cfg.get_mode(config) == cfg.Mode.LIKELIHOOD:
            # FIXME:
            # This path depends on the implementation of pewo.io.fasta.split_fasta.
            shell(
                "mv {params.workdir}/placements_{wildcards.query}_r0.fasta.jplace "
                "{params.workdir}/{wildcards.query}_r0_k{wildcards.k}_o{wildcards.omega}_red{wildcards.red}_ar{wildcards.ar}_rappas.jplace"
            )

        else:
            for length in config["read_length"]:
                shell(
                    "mv {params.workdir}/placements_{wildcards.pruning}_r" + str(length) + ".fasta.jplace "
                    "{params.workdir}/{wildcards.pruning}_r" + str(length) + "_k{wildcards.k}_o{wildcards.o}_red{wildcards.red}_ar{wildcards.ar}_rappas.jplace "
                )


def make_log_name(wildcards) -> str:
    x = "_".join(w + f"{w}" for w in wildcards)
    print(x)
    return x


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
    #log:
    #    get_log_template(config, PlacementSoftware.RAPPAS)
    #benchmark:
    #    repeat(get_benchmark_template(config, PlacementSoftware.RAPPAS), config["repeats"])
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/red{red}_ar{ar}/AR",
        workdir=_rappas_experiment_dir,
        dbfilename="DB.bin",
        arbin=lambda wildcards: get_ar_binary(config, wildcards.ar)
    run:
         shell(
            "java -Xms2G -Xmx"+str(config["config_rappas"]["memory"])+"G -jar $(which RAPPAS.jar) -v 1 -p b -b $(which {params.arbin}) "
            "-k {wildcards.k} --omega {wildcards.o} -t {input.t} -r {input.a} "
            "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {wildcards.red} "
            "--use_unrooted --dbfilename {params.dbfilename} "
            #" &> {log} "
         )

rule placement_rappas:
    input:
        database = os.path.join(_rappas_experiment_dir, "DB.bin"),
        r = lambda wildcards: get_rappas_input_reads(wildcards.pruning),
    output:
        jplace = get_output_template(config, PlacementSoftware.RAPPAS, "jplace")
    log:
        get_log_template(config, PlacementSoftware.RAPPAS)
    #benchmark:
    #    repeat(get_output_template(config, PlacementSoftware.RAPPAS, "placement_benchmark.tsv"), config["repeats"])
    version: "1.00"
    params:
        workdir = _rappas_experiment_dir,
        maxp = config["maxplacements"],
        minlwr = config["minlwr"]
    run:
        make_log_name(wildcards)
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

