"""
This module computes the likelihood of a tree.
"""

__author__ = "Nikolai Romashchenko"

import os
from pewo.io import fasta
from pewo.software import PlacementSoftware
from pewo.templates import get_jplace_output_template, \
                           get_output_template, \
                           get_output_template_args


rule split_queries:
    """
    Splits input .fasta file into multiple fasta files.
    """
    input:
        reads = config["dataset_reads"]
    output:
        queries = expand(config["workdir"] + "/R+/{query}.fasta",
                         query=fasta.get_sequence_ids(config["dataset_reads"]))
    log:
        config["workdir"] + "/logs/split_queries.log"
    version:
        "1.00"
    run:
        output_directory = os.path.join(config["workdir"], "R+")
        fasta.split_fasta(config["dataset_reads"], output_directory)


rule extend_trees:
    """
    Extends a tree with given sequences.
    """
    input:
        jplace = get_jplace_output_template(config, PlacementSoftware.RAPPAS),
        mapping = config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/ARtree_id_mapping.tsv",
        tree = config["dataset_tree"],
    output:
        ext_tree = get_output_template(config, PlacementSoftware.RAPPAS, "tree")
    version:
        "1.00"
    run:
        shell(
            "pewo/extend_tree.py {input.tree} {output.ext_tree} {input.jplace}"
        )


rule calculate_likelihood:
    """
    Calculates the likelihood of each extended tree.
    """
    input:
        alignment = os.path.join(config["workdir"], "HMM+", "{query}.align"),
        tree = get_output_template(config, PlacementSoftware.RAPPAS, "tree")
    output:
        likelihood = get_output_template(config, PlacementSoftware.RAPPAS, "txt")
    params:
        workdir = config["workdir"],
        model = "GTR+G"
    #log:
    #    config["workdir"] + "/logs/likelihood.log"
    version:
        "1.00"
    shell:
        # run raxml-ng
        'raxml-ng --evaluate --msa {input.alignment} --tree {input.tree} --model {params.model} --redo'
        # parse the output to get just the number
        '| grep "Final LogLikelihood" | cut -d" " -f3'
        '> {output.likelihood}'



rule combine_likelihoods:
    """
    Combines the results of likelihood calculation for all trees in a .csv file.
    """
    input:
        likelihood = expand(get_output_template(config, PlacementSoftware.RAPPAS, "txt"),
                            **get_output_template_args(config, PlacementSoftware.RAPPAS))
    output:
        result = config["workdir"] + "/likelihood.csv"
    run:
        pass