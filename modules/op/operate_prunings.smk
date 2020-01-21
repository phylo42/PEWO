"""
This module computes different prunings using the alignment/tree set from the config file.
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"


# TODO: add trifurcations tests? currently disabled
# TODO: keep or remove read length sd ?

import os
import pewo.config as cfg


_work_dir = cfg.get_work_dir(config)


def get_input_reads():
    """
    Creates an input read file parameter.
    """
    return config["dataset_reads"] if "dataset_reads" in config else []


def get_pruning_output_read_files():
    """
    Creates a list of output read files.
    """
    output_directory = os.path.join(_work_dir, "R")

    return [os.path.join(output_directory, "{0}_r{1}.fasta".format(pruning, length))
            for pruning in range(config["pruning_count"])
            for length in config["read_length"]]


def get_params_length():
    """
    Creates {params.length} parameter.
    """
    return str(config["read_length"]).replace("[","").replace("]","").replace(" ","")


rule operate_pruning:
    """
    Runs PrunedTreeGenerator to creates prunings.
    """
    input:
        a = config["dataset_align"],
        t = config["dataset_tree"],
        r = get_input_reads()
    output:
        a = expand(config["workdir"] + "/A/{pruning}.align", pruning=range(config["pruning_count"])),
        t = expand(config["workdir"] + "/T/{pruning}.tree", pruning=range(config["pruning_count"])),
        g = expand(config["workdir"] + "/G/{pruning}.fasta", pruning=range(config["pruning_count"])),
        r = get_pruning_output_read_files()
    log:
        config["workdir"] + "/logs/operate_pruning.log"
    version:
        "1.00"
    params:
        wd = config["workdir"],
        count = config["pruning_count"],
        states = config["states"],
        jar = config["pewo_jar"],
        length = get_params_length()
        #length_sd=config["read_length_sd"],
        #bpe=config["bpe"],
    run:
        if cfg.generate_reads(config):
            shell(
                "java -cp {params.jar} PrunedTreeGenerator_LITE "
                "{params.wd} {input.a} {input.t} "
                "{params.count} {params.length} 0 1 {params.states} "
                "&> {log}"
            )
        else:
            shell(
                "mkdir -p {params.wd}/A {params.wd}/T {params.wd}/G {params.wd}/R;"
                "cp {input.a} {params.wd}/A/0.align;"
                "cp {input.t} {params.wd}/T/0.tree;"
                "cp {input.r} {params.wd}/R/0_r0.fasta;"
                "touch {params.wd}/G/0.fasta;"
            )