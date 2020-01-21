"""
A module to operate hmm alignments for likelihood evaluations
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
import pewo.config as cfg
from pewo.software import AlignmentSoftware
from pewo.templates import get_software_dir, get_experiment_log_dir_template


_work_dir = cfg.get_work_dir(config)
_hmm_software_dir = get_software_dir(config, AlignmentSoftware.HMMER)


rule hmm_build:
    """
    build hmm profile
    """
    input:
        alignment = config["dataset_align"]
    output:
        hmm = os.path.join(_hmm_software_dir, "{pruning}.hmm")
    # TODO: add logs
    log: config["workdir"]+"/logs/hmmbuild/{pruning}.log"
    version: "1.0"
    params:
        states=["dna"] if config["states"]==0 else ["amino"]
    threads: 1
    shell:
        "hmmbuild --cpu {threads} --{params.states} {output.hmm} {input.alignment} &> {log}"


rule hmm_align:
    """
    Aligns a query to a profile
    """
    input:
        hmm = os.path.join(_hmm_software_dir, "{pruning}.hmm"),
        alignment = config["dataset_align"],
        query = os.path.join(_work_dir, "R", "{query}.fasta")
    output:
        psiblast = os.path.join(_hmm_software_dir, "{pruning}", "{query}.psiblast")
    version:
        "1.0"
    log: os.path.join(get_experiment_log_dir_template(config, AlignmentSoftware.HMMER), "{query}.log")
    benchmark:
        repeat(
            os.path.join(_work_dir, "benchmarks", "{pruning}", "{query}_hmmbuild_benchmark.tsv"),
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
        psiblast = os.path.join(_hmm_software_dir, "{pruning}", "{query}.psiblast")
    output:
        alignment = os.path.join(_hmm_software_dir, "{pruning}", "{query}.align")
    version:
        "1.0"
    log: os.path.join(get_experiment_log_dir_template(config, "psiblast2fasta"), "{query}.log")
    shell:
        "pewo/alignment/psiblast2fasta.py {input.psiblast} {output.alignment} &> {log}"

