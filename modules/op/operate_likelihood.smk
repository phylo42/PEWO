"""
This module computes the likelihood of a tree.
"""

__author__ = "Nikolai Romashchenko"

import os
from Bio import SeqIO


def split_fasta(input_file):
    """
    Splits the input .fasta file into multiple .fasta files,
    one sequence per file.
    """
    output_directory = os.path.join(config["workdir"], "R+")

    for record in SeqIO.parse(input_file, "fasta"):
        output_file = os.path.join(output_directory, record.id + ".fasta")

        with open(output_file, "w") as output:
            SeqIO.write([record], output, "fasta")


rule split_queries:
    """
    Splits input .fasta file into multiple fasta files.
    """
    input:
        reads = config["dataset_reads"]
    output:
        queries = expand(config["workdir"] + "/R+/{query}.fasta", query=query_ids)
    log:
        config["workdir"] + "/logs/split_queries.log"
    version:
        "1.00"
    run:
        split_fasta(config["dataset_reads"])


rule extend_trees:
    """
    Extends a tree with given sequences.
    """
    input:
        fasta = config["workdir"] + "/R+/{query}.fasta",
        #jplace_files = get_jplace_outputs(),
        jplace = get_jplace_output_template(PlacementSoftware.RAPPAS),
        tree = config["dataset_tree"]
    output:
        ext_trees = get_output_template(PlacementSoftware.RAPPAS, "tree"),
    #log:
    #    config["workdir"] + "/logs/extend_tree_{query}.log"
    version:
        "1.00"
    run:
        shell("echo {input.jplace}")


rule calculate_likelihood:
    input:
        alignment = os.path.join(config["workdir"], "HMM+", "{query}.align"),
        tree = get_output_template(PlacementSoftware.RAPPAS, "tree")
    output:
        likelihood = get_output_template(PlacementSoftware.RAPPAS, "txt")
    params:
        workdir = config["workdir"]
    #log:
    #    config["workdir"] + "/logs/likelihood.log"
    version:
        "1.00"
    run:
        "mkdir -p {params.workdir}/LL"
        'raxml-ng --evaluate --msa {input.alignment} --tree {input.tree} --model GTR+G | '
        'grep "Final LogLikelihood" > {output.likelihood}'



rule operate_likelihood:
    input:
        likelihood = expand(get_output_template(PlacementSoftware.RAPPAS, "txt"),
                            **get_output_template_args(PlacementSoftware.RAPPAS))
    output:
        result = config["workdir"] + "/likelihood.csv"
    run:
        pass