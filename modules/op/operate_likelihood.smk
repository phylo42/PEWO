"""
This module computes the likelihood of a tree.
"""

__author__ = "Nikolai Romashchenko"

import os
import itertools
from typing import Dict, List
from snakemake.io import InputFiles, Namedlist
import pewo.config as cfg
from pewo.likelihood.likelihood import combine_csv
from pewo.likelihood.extend_tree import make_extended_tree
from pewo.io import fasta
from pewo.software import PlacementSoftware, AlignmentSoftware
from pewo.templates import get_output_template,\
    get_output_template_args, get_software_dir


_work_dir = cfg.get_work_dir(config)


rule split_queries:
    """
    Splits input .fasta file into multiple fasta files.
    """
    input:
        reads = config["dataset_reads"]
    output:
        queries = expand(
            os.path.join(_work_dir, "R", "{query}.fasta"),
            query=fasta.get_sequence_ids(config["dataset_reads"])
        )
    log:
        config["workdir"] + "/logs/split_queries.log"
    version:
        "1.00"
    run:
        output_directory = os.path.join(_work_dir, "R")
        fasta.split_fasta(config["dataset_reads"], output_directory)


rule extend_trees_epa:
    input:
        jplace = get_output_template(config, PlacementSoftware.EPA, "jplace"),
        tree = config["dataset_tree"],
    output:
        ext_tree = get_output_template(config, PlacementSoftware.EPA, "tree")
    version:
        "1.00"
    run:
         make_extended_tree(input.tree, output.ext_tree, input.jplace)


rule extend_trees_rappas:
    input:
        jplace = get_output_template(config, PlacementSoftware.RAPPAS, "jplace"),
        tree = config["dataset_tree"],
    output:
        ext_tree = get_output_template(config, PlacementSoftware.RAPPAS, "tree")
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)


def _calculate_likelihood(input: InputFiles, output: Namedlist, params: Namedlist, wildcards: Namedlist) -> None:
    with open(output.csv, "w") as f_out:
        # make .csv header: placement parameters
        header = [key for key in wildcards.keys()]
        # add the likelihood value
        header.append("likelihood")

        # snakemake.NamedList implemented keys(), but not values()... *sigh*
        values = [wildcards[key] for key in wildcards.keys()]

        # run raxml-ng, parse the output to get the likelihood value and put it in the variable
        likelihood = shell(
                'raxml-ng --evaluate --msa {input.alignment} --tree {input.tree} --model {params.model} --redo'
                '| grep "Final LogLikelihood" | cut -d" " -f3', read=True
            ).decode("utf-8").strip()
        values.append(
            likelihood
        )

        # All the wilcards extracted from the .tree file were input parameters of placement.
        # Print them in the file as a header of two-line .csv file
        print(';'.join(s for s in header), file=f_out)
        print(';'.join(s for s in values), file=f_out)


def _get_aligned_query_template(config: Dict) -> str:
    # TODO: Generalize this for other alignment software
    _hmm_software_dir = get_software_dir(config, AlignmentSoftware.HMMER)
    return os.path.join(_hmm_software_dir, "{pruning}", "{query}.align")

# WARNING
#
# A wall of copy-pasted code below. All the rules calculate_likelihood_XXX are just
# a bunch of copy-paste. Input, output, params patterns are all the same.
# As far as I know, there is no way in beautiful Snakemake to generalize this code.
# *sigh*
#
# Any changes to these rules must be consistent to each other.


rule calculate_likelihood_epa:
    """
    Calculates likelihood values for the placements produced by EPA.
    """
    input:
        alignment =_get_aligned_query_template(config),
        tree = get_output_template(config, PlacementSoftware.EPA, "tree")
    output:
        csv = get_output_template(config, PlacementSoftware.EPA, "csv")
    params:
        workdir = cfg.get_work_dir(config),
        model = "GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)


rule calculate_likelihood_rappas:
    """
    Calculates likelihood values for the placements produced by RAPPAS.
    """
    input:
        alignment =_get_aligned_query_template(config),
        tree = get_output_template(config, PlacementSoftware.RAPPAS, "tree")
    output:
        csv = get_output_template(config, PlacementSoftware.RAPPAS, "csv")
    params:
        workdir = cfg.get_work_dir(config),
        model = "GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)


def _get_csv_output(config: Dict) -> List[str]:
    """
    Generates a full list of output .csv file names for all software tested.
    """
    return list(itertools.chain.from_iterable(
        # do not anything if software is not tested
        [] if not cfg.software_tested(config, software) else
        # otherwise expand the output file name templates
        expand(
            get_output_template(config, software, "csv"),
            **get_output_template_args(config, software)
        ) for software in PlacementSoftware
    ))


rule combine_likelihoods:
    """
    Combines the results of likelihood calculation for all trees in a .csv file.
    """
    input:
        csv_files = _get_csv_output(config)
    output:
        csv_file = config["workdir"] + "/likelihood.csv"
    run:
        combine_csv(input.csv_files, output.csv_file)