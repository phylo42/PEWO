"""
A module to operate hmm alignments for likelihood evaluations
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os


rule hmm_build:
    """
    build hmm profile
    """
    input:
        config["dataset_align"]
    output:
        config["workdir"]+"/HMM+/full.hmm"
    log:
        config["workdir"]+"/logs/hmmbuild/full.log"
    version: "1.0"
    params:
        states=["dna"] if config["states"]==0 else ["amino"]
    threads: 1
    shell:
        "hmmbuild --cpu {threads} --{params.states} "
        "{output} {input} &> {log}"

rule hmm_align:
    """
    Aligns a query to a profile
    """
    input:
        hmm = os.path.join(config["workdir"], "HMM+", "full.hmm"),
        align = config["dataset_align"],
        query = os.path.join(config["workdir"], "R+", "{query}.fasta")
    output:
        psiblast = os.path.join(config["workdir"], "HMM+", "{query}.psiblast")
    version:
        "1.0"
    log:
        os.path.join(config["workdir"], "logs", "hmmbuild", "{query}.log")
    benchmark:
        repeat(
            os.path.join(config["workdir"], "benchmarks", "{query}_hmmbuild_benchmark.tsv"),
            config["repeats"]
        )
    params:
        states = ["dna"] if config["states"] == 0 else ["amino"],
    shell:
        "hmmalign --{params.states} --outformat PSIBLAST -o {output.psiblast} " +
        "--mapali {input.align} {input.hmm} {input.query} &> {log}"


rule psiblast_to_fasta:
    """
    Converts psiblast to fasta format.
    """
    input:
        psiblast = os.path.join(config["workdir"], "HMM+", "{query}.psiblast")
    output:
        alignment = os.path.join(config["workdir"], "HMM+", "{query}.align")
    version:
        "1.0"
    log:
        os.path.join(config["workdir"], "logs", "psiblast2fasta", "{query}.log")
    shell:
        "pewo/alignment/psiblast2fasta.py {input.psiblast} {output.alignment} &> {log}"

