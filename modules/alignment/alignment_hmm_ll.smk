"""
A module to operate hmm alignments for likelihood evaluations
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
import pewo.config as cfg
from pewo.software import AlignmentSoftware, CustomScripts
from pewo.templates import get_software_dir, get_experiment_log_dir_template, \
    get_common_queryname_template


_work_dir = cfg.get_work_dir(config)
_alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)


rule hmm_build:
    """
    Builds an hmm profile.
    """
    input:
        alignment = os.path.join(_work_dir, "A", "{pruning}.align")
    output:
        hmm = os.path.join(_alignment_dir, "{pruning}.hmm")
    log:
        os.path.join(get_experiment_log_dir_template(config, AlignmentSoftware.HMMER),
                     "{pruning}.log")
    version:
        "1.0"
    params:
        states = ["dna"] if config["states"] == 0 else ["amino"]
    threads: 1
    shell:
        "hmmbuild --cpu {threads} --{params.states} {output.hmm} {input.alignment} &> {log}"


rule hmm_align:
    """
    Aligns a query to a profile.
    """
    input:
        hmm = os.path.join(_alignment_dir, "{pruning}.hmm"),
        alignment = os.path.join(_work_dir, "A", "{pruning}.align"),
        query = os.path.join(_work_dir,
                             "R",
                             get_common_queryname_template(config) + ".fasta")
    output:
        psiblast = os.path.join(_alignment_dir,
                                "{pruning}",
                                get_common_queryname_template(config) + ".psiblast")
    version:
        "1.0"
    log:
        os.path.join(get_experiment_log_dir_template(config, AlignmentSoftware.HMMER),
                     get_common_queryname_template(config) + ".log")
    benchmark:
        repeat(
            os.path.join(_work_dir, "benchmarks", "{pruning}",
                         get_common_queryname_template(config) + "_hmmbuild_benchmark.tsv"),
            config["repeats"]
        )
    params:
        states = ["dna"] if config["states"] == 0 else ["amino"],
    shell:
        "hmmalign --{params.states} --outformat PSIBLAST -o {output.psiblast} " +
        "--mapali {input.alignment} {input.hmm} {input.query} &> {log}"


rule psiblast_to_fasta:
    """
    Converts psiblast to fasta format.
    """
    input:
        psiblast = os.path.join(_alignment_dir,
                                "{pruning}",
                                get_common_queryname_template(config) + ".psiblast")
    output:
        alignment = os.path.join(_alignment_dir,
                                 "{pruning}",
                                 get_common_queryname_template(config) + ".fasta")
    version:
        "1.0"
    log:
        os.path.join(get_experiment_log_dir_template(config, CustomScripts.PSIBLAST_2_FASTA),
                     get_common_queryname_template(config) + ".log")
    shell:
        "pewo/alignment/psiblast2fasta.py {input.psiblast} {output.alignment} &> {log}"

