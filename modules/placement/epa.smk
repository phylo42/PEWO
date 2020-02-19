"""
This module operates placements with EPA (part of raxml)
note1: that raxml outputs many files, but only the jplace is kept
note2: raxml outputs results only in current working directory, so EPA dir needs to be explicitly set
note3: raxml may create a .reduced file in the directory of the input alignment, while this was initially
managed by using a temp() for the corresponding output, this output may or may not exists
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


#TODO: SSE3 version is used as default, there should be a way to test SSE3/AVX availability
# from python and launch correct version accordingly

import os
from snakemake.io import Namedlist, temp
import pewo.config as cfg
from pewo.software import PlacementSoftware
from pewo.software import AlignmentSoftware
from pewo.templates import get_experiment_dir_template, get_output_template, \
    get_log_template, get_queryname_template,  get_common_queryname_template, \
    get_software_dir, get_benchmark_template, get_output_template_args


_working_dir = cfg.get_work_dir(config)
_epa_experiment_dir = get_experiment_dir_template(config, PlacementSoftware.EPA)

#FIXME:
# Unnecessary dependendancy on the alignment software
_alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)

_epa_place_benchmark_template = get_benchmark_template(config, PlacementSoftware.EPA,
                                                       p="pruning", length="length", g="g", rule_name="placement")

epa_benchmark_templates = [_epa_place_benchmark_template]
epa_benchmark_template_args = [get_output_template_args(config, PlacementSoftware.EPA)]


def _get_epa_placement_output() -> Namedlist:
    """
    Creates a list of output file name templates produced by EPA.
    """
    _experiment_dir = get_experiment_dir_template(config, PlacementSoftware.EPA)

    raxml_templates = [
        # get_queryname_template returns a template like [INPUT SETPARAMS ]_[SOFTWARE PARAMS],
        # e.g. {pruning}_r{read_length}_g{gepa}.
        # Take this template and add as postfix to all RAxML output files
        prefix + "." + get_queryname_template(config, PlacementSoftware.EPA)
        for prefix in [
            "RAxML_classificationLikelihoodWeights",
            "RAxML_entropy",
            "RAxML_info",
            "RAxML_labelledTree",
            "RAxML_originalLabelledTree"
        ]
    ]

    # create an output Namedlist of RAxML file templates
    output = Namedlist(
        [temp(os.path.join(_experiment_dir, template)) for template in raxml_templates]
    )

    # add .jplace name template
    output.append(get_output_template(config, PlacementSoftware.EPA, "jplace"))
    return output


rule placement_epa:
    """
    Runs placement using EPA.
    """

    input:
        hmm = os.path.join(_alignment_dir,
                           "{pruning}",
                           get_common_queryname_template(config) + ".fasta"),
        t = os.path.join(_working_dir,
                         "T",
                         "{pruning}.tree")
    output:
        _get_epa_placement_output()
    log:
        get_log_template(config, PlacementSoftware.EPA)
    benchmark:
        repeat(_epa_place_benchmark_template, config["repeats"])
    version: "1.0"
    params:
        m = select_model_raxmlstyle(),
        c = config["phylo_params"]["categories"],
        name = get_queryname_template(config, PlacementSoftware.EPA),
        raxmlname = os.path.join(_epa_experiment_dir,
                                 "RAxML_portableTree." + get_queryname_template(config, PlacementSoftware.EPA) + ".jplace"),
        outname = get_output_template(config, PlacementSoftware.EPA, "jplace"),

        reduction = os.path.join(_alignment_dir,
                                 get_common_queryname_template(config) + ".fasta.reduced"),
        info = os.path.join(_epa_experiment_dir,
                            "RAxML_info." + get_queryname_template(config, PlacementSoftware.EPA)),
        outdir = _epa_experiment_dir,
        maxp = config["maxplacements"],
        minlwr = config["minlwr"]
    shell:
        """
        rm -f {params.info}
        raxmlHPC-SSE3 -f v --epa-keep-placements={params.maxp} --epa-prob-threshold={params.minlwr} -w {params.outdir} -G {wildcards.g} -m {params.m} -c {params.c} -n {params.name} -s {input.hmm} -t {input.t} &> {log}
        mv {params.raxmlname} {params.outname}
        rm -f {params.reduction}
        """
