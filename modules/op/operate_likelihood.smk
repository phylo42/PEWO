"""
This module computes the likelihood of a tree.
"""

__author__ = "Nikolai Romashchenko"

import os


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
        queries = expand(config["workdir"] + "/R+/{query}.fasta", query=query_ids),
        placements = get_jplace_inputs(),
        tree = config["dataset_tree"]
    output:
        ext_trees = expand(config["workdir"] + "/T+/{query}.tree", query=query_ids),
    log:
        config["workdir"] + "/logs/extend_trees.log"
    version:
        "1.00"
    run:
        pass


rule calculate_likelihood:
    input:
        alignments = expand(config["workdir"] + "/HMM+/{query}.align", query=query_ids),
        trees = expand(config["workdir"] + "/T+/{query}.tree", query=query_ids),
    output:
        likelihood = expand(config["workdir"] + "/LL/{query}.txt", query=query_ids),
    params:
        workdir = config["workdir"]
    log:
        config["workdir"] + "/logs/likelihood.log"
    version:
        "1.00"
    run:
        "mkdir -p {params.workdir}/LL"
        'raxml-ng --evaluate --msa {input.alignment} --tree {input.tree} --model GTR+G | '
        'grep "Final LogLikelihood" > {output.likelihood}'


rule operate_likelihood:
    input:
        #jplace_files = get_jplace_inputs(),
        likelihoods = expand(config["workdir"] + "/LL/{query}.txt", query=query_ids),
    output:
        result = config["workdir"] + "/likelihood.csv"
    run:
        pass