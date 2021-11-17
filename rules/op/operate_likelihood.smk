"""
This module computes the likelihood of a tree.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"

import os
from typing import Dict, List, Type
from snakemake.io import InputFiles, OutputFiles, Params, Wildcards
import pewo.config as cfg
from pewo.likelihood.likelihood import combine_csv
from pewo.likelihood.extend_tree import make_extended_tree
from pewo.io import fasta
from pewo.software import PlacementSoftware, AlignmentSoftware
from pewo.templates import get_output_template, get_common_queryname_template, \
    get_output_template_args, get_software_dir, get_common_template_args

_work_dir = cfg.get_work_dir(config)

RuleInputs = str, Type[InputFiles]
RuleOutputs = Type[OutputFiles]
RuleParams = Type[Params]
RuleWildcards = Type[Wildcards]


def _calculate_likelihood(input: RuleInputs, output: RuleOutputs, params: RuleParams, wildcards: RuleWildcards) -> None:
    with open(output.csv, "w") as f_out:
        # make .csv header: placement parameters
        header = [key for key in wildcards.keys()]
        # add the likelihood value
        header.append("likelihood")
        header.append("software")

        # snakemake.NamedList implemented keys(), but not values()... *sigh*
        values = [wildcards[key] for key in wildcards.keys()]

        # run raxml-ng, parse the output to get the likelihood value and put it in the variable
        likelihood = shell(
            'raxml-ng '
            '--evaluate '
            '--msa {input.alignment} '
            '--tree {input.tree} '
            '--model {params.model} '
            '--redo '
            '--threads 1'
            '| grep "Final LogLikelihood" | cut -d" " -f3', read=True
        ).decode("utf-8").strip()
        values.append(
            likelihood
        )
        values.append(params.software)

        # All the wilcards extracted from the .tree file were input parameters of placement.
        # Print them in the file as a header of two-line .csv file
        print(';'.join(s for s in header), file=f_out)
        print(';'.join(s for s in values), file=f_out)


def _get_aligned_query_template(config: Dict) -> str:
    # TODO: Generalize this for other alignment software
    _alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)
    return os.path.join(_alignment_dir,
                        "{pruning}",
                        get_common_queryname_template(config) + ".fasta")

rule split_queries:
    """
    Splits input .fasta file into multiple fasta files.
    """
    input:
        reads=config["query_user"]
    output:
        queries=expand(
            os.path.join(_work_dir, "R",
                         get_common_queryname_template(config) + ".fasta"),
            **get_common_template_args(config)
        )
    log:
        config["workdir"] + "/logs/split_queries.log"
    version:
        "1.00"
    run:
        output_directory = os.path.join(_work_dir, "R")
        fasta.split_fasta(config["query_user"], output_directory)

# WARNING!
#
# A wall of copy-pasted code below. All the rules extend_trees_XXX and
# calculate_likelihood_XXX are just a bunch of copy-paste. Input, output,
# params patterns are all the same. As far as I know, there is no way to
# generalize this code in beautiful Snakemake.
#
# *sigh*
#
# Any changes to these rules must be consistent to each other.

rule extend_trees_epa:
    input:
         jplace=get_output_template(config, PlacementSoftware.EPA, "jplace"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.EPA, "tree")
    version:
           "1.00"
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_epang_h1:
    input:
         jplace=get_output_template(config, PlacementSoftware.EPANG, "jplace", heuristic="h1"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h1")
    version:
           "1.00"
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_epang_h2:
    input:
         jplace=get_output_template(config, PlacementSoftware.EPANG, "jplace", heuristic="h2"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h2")
    version:
           "1.00"
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_epang_h3:
    input:
         jplace=get_output_template(config, PlacementSoftware.EPANG, "jplace", heuristic="h3"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h3")
    version:
           "1.00"
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_epang_h4:
    input:
         jplace=get_output_template(config, PlacementSoftware.EPANG, "jplace", heuristic="h4"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h4")
    version:
           "1.00"
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_pplacer:
    input:
         jplace=get_output_template(config, PlacementSoftware.PPLACER, "jplace"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.PPLACER, "tree")
    version:
           "1.00"
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_rappas:
    input:
         jplace=get_output_template(config, PlacementSoftware.RAPPAS, "jplace"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.RAPPAS, "tree")
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_apples:
    input:
         jplace=get_output_template(config, PlacementSoftware.APPLES, "jplace"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.APPLES, "tree")
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule extend_trees_appspam:
    input:
         jplace=get_output_template(config, PlacementSoftware.APPSPAM, "jplace"),
         tree=config["dataset_tree"],
    output:
          ext_tree=get_output_template(config, PlacementSoftware.APPSPAM, "tree")
    run:
        make_extended_tree(input.tree, output.ext_tree, input.jplace)

rule calculate_likelihood_epa:
    """
    Calculates likelihood values for the placements produced by EPA.
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.EPA, "tree")
    output:
          csv=get_output_template(config, PlacementSoftware.EPA, "csv")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.EPA.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_epang_h1:
    """
    Calculates likelihood values for the placements produced by EPA-NG (heuristic 1).
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h1")
    output:
          csv=get_output_template(config, PlacementSoftware.EPANG, "csv", heuristic="h1")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.EPANG.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_epang_h2:
    """
    Calculates likelihood values for the placements produced by EPA-NG (heuristic 2).
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h2")
    output:
          csv=get_output_template(config, PlacementSoftware.EPANG, "csv", heuristic="h2")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.EPANG.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_epang_h3:
    """
    Calculates likelihood values for the placements produced by EPA-NG (heuristic 3).
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h3")
    output:
          csv=get_output_template(config, PlacementSoftware.EPANG, "csv", heuristic="h3")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.EPANG.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_epang_h4:
    """
    Calculates likelihood values for the placements produced by EPA-NG (heuristic 4).
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.EPANG, "tree", heuristic="h4")
    output:
          csv=get_output_template(config, PlacementSoftware.EPANG, "csv", heuristic="h4")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.EPANG.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_pplacer:
    """
    Calculates likelihood values for the placements produced by PPLACER.
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.PPLACER, "tree")
    output:
          csv=get_output_template(config, PlacementSoftware.PPLACER, "csv")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.PPLACER.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_rappas:
    """
    Calculates likelihood values for the placements produced by RAPPAS.
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.RAPPAS, "tree")
    output:
          csv=get_output_template(config, PlacementSoftware.RAPPAS, "csv")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.RAPPAS.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_apples:
    """
    Calculates likelihood values for the placements produced by APPLES.
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.APPLES, "tree")
    output:
          csv=get_output_template(config, PlacementSoftware.APPLES, "csv")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.APPLES.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

rule calculate_likelihood_appspam:
    """
    Calculates likelihood values for the placements produced by APPSPAM.
    """
    input:
         alignment=_get_aligned_query_template(config),
         tree=get_output_template(config, PlacementSoftware.APPSPAM, "tree")
    output:
          csv=get_output_template(config, PlacementSoftware.APPSPAM, "csv")
    params:
          workdir=cfg.get_work_dir(config),
          software=PlacementSoftware.APPSPAM.value,
          model="GTR+G"
    run:
        _calculate_likelihood(input, output, params, wildcards)

def _get_csv_output(config: Dict) -> List[str]:
    """
    Generates a full list of output .csv file names for all software tested.
    """
    outputs = []

    for software in PlacementSoftware:
        if cfg.software_tested(config, software):
            #FIXME:
            # Writing if statements like this is not a good way of making software.
            # This is actually a guaranteed way to be cursed by the gods of software development.
            # TODO: Find a proper way around this to save our souls
            if software != PlacementSoftware.EPANG:
                outputs.extend(
                    expand(get_output_template(config, software, "csv"),
                           **get_output_template_args(config, software))
                )
            else:
                #FIXME:
                # The problem here is that we have different rules for each heuristic
                # due to the nature of snakemake. This makes EPA-NG inconsistent with other software
                # that have only one rule per software. I see no right way to generalize this.
                for heuristic in config["config_epang"]["heuristics"]:
                    outputs.extend(
                        expand(get_output_template(config, software, "csv", heuristic=heuristic),
                               **get_output_template_args(config, software, heuristic=heuristic))
                    )
    return outputs


rule combine_likelihoods:
    """
    Combines the results of likelihood calculation for all trees in a .csv file.
    """
    input:
        csv_files=_get_csv_output(config)
    output:
        сsv_file=os.path.join(_work_dir, "likelihood.csv")
    run:
        combine_csv(input.csv_files, output.сsv_file)
