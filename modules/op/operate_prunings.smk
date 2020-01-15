"""
This module computes different prunings using the alignment/tree set from the config file.

"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"

# TODO: add trifurcations tests? currently disabled
# TODO: keep or remove read length sd ?

import os


if config["debug"] == 1:
    print("prunings: ", os.getcwd())


def get_input_reads():
    """
    Creates an input read file parameter.
    """
    return [] if prunings_enabled() else config["dataset_reads"]


def get_output_alignments():
    """
    Creates a list of output alignment files.
    """
    output_directory = os.path.join(config["workdir"], "A")
    if prunings_enabled():
        return [os.path.join(output_directory, "{}.align".format(pruning))
                for pruning in range(config["pruning_count"])]
    else:
        return [os.path.join(output_directory, "full.align")]


def get_output_trees():
    """
    Creates a list of output tree files.
    """
    output_directory = os.path.join(config["workdir"], "T")
    if prunings_enabled():
        return [os.path.join(output_directory, "{}.tree".format(pruning))
                for pruning in range(config["pruning_count"])]
    else:
        return [os.path.join(output_directory, "full.tree")]


def get_output_leaves():
    """
    Creates a list of output fasta files with removed leaves.
    """
    output_directory = os.path.join(config["workdir"], "G")
    if prunings_enabled():
        return [os.path.join(output_directory, "{}.fasta".format(pruning))
                for pruning in range(config["pruning_count"])]
    else:
        return []


def get_output_read_files():
    """
    Creates a list of output read files.
    """
    output_directory = os.path.join(config["workdir"], "R")
    if prunings_enabled():
        return [os.path.join(output_directory, "{0}_r{1}.fasta".format(pruning, length))
                for pruning in range(config["pruning_count"])
                for length in config["read_length"]]
    else:
        return [os.path.join(output_directory, "full.fasta")]


def get_params_length():
    """
    Creates {params.length} parameter if needed.
    """
    if prunings_enabled():
        return str(config["read_length"]).replace("[","").replace("]","").replace(" ","")
    else:
        return None


rule operate_pruning:
    """
    Runs PrunedTreeGenerator to creates prunings.
    """
    input:
        a = config["dataset_align"],
        t = config["dataset_tree"],
        r = get_input_reads()
    output:
        a = get_output_alignments(),
        t = get_output_trees(),
        g = get_output_leaves(),
        r = get_output_read_files()
    log:
        config["workdir"] + "/logs/operate_pruning.log"
    version:
        "1.00"
    params:
        wd = config["workdir"],
        count = config["pruning_count"],
        states = config["states"],
        length = get_params_length()
        #length_sd=config["read_length_sd"],
        #bpe=config["bpe"],
    run:
        if prunings_enabled():
            shell(
                "java -cp `which RAPPAS.jar`:PEWO.jar PrunedTreeGenerator_LITE "
                "{params.wd} {input.a} {input.t} "
                "{params.count} {params.length} 0 1 {params.states} "
                "&> {log}"
            )
        else:
            shell(
                "mkdir -p {params.wd}/A {params.wd}/T {params.wd}/G {params.wd}/R;"
                "cp {input.a} {params.wd}/A/full.align;"
                "cp {input.t} {params.wd}/T/full.tree;"
                "cp {input.r} {params.wd}/R/full.fasta;"
            )


