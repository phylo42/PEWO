"""
A module to operate hmm alignments for likelihood evaluations
"""

__author__ = "Nikolai Romashchenko"

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
        hmm=config["workdir"]+"/HMM+/full.hmm",
        align=config["dataset_align"],
        reads=expand(config["workdir"] + "/R+/{query}.fasta", query=query_ids)
    output:
        temp(config["workdir"]+"/HMM+/{query}.psiblast")
    version: "1.0"
    log:
        config["workdir"]+"/logs/hmmbuild/{query}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{query}_hmmbuild_benchmark.tsv", config["repeats"])
    params:
        states = ["dna"] if config["states"] == 0 else ["amino"],
        query = query_ids
    run:
        for query in query_ids:
            query_psiblast = config["workdir"] + "/HMM+/{}.psiblast ".format(query)
            query_fasta = config["workdir"] + "/R+/{}.fasta".format(query)
            shell(
                "hmmalign --{params.states} --outformat PSIBLAST -o " + query_psiblast +
                "--mapali {input.align} {input.hmm} " + query_fasta + " &> {log}"
            )



rule psiblast_to_fasta:
    """
    convert from psiblast to fasta format
    """
    input:
        psiblast = expand(config["workdir"] + "/HMM+/{query}.psiblast", query=query_ids)
    output:
        fasta = expand(config["workdir"] + "/HMM+/{query}.align", query=query_ids)
    version:
        "1.0"
    log:
        expand(config["workdir"] + "/logs/psiblast2fasta/{query}.log", query=query_ids)
    run:
        for query in query_ids:
            query_psiblast = config["workdir"] + "/HMM+/{}.psiblast ".format(query)
            query_align = config["workdir"] + "/HMM+/{}.align ".format(query)
            shell(
                "scripts/psiblast2fasta.py " + query_psiblast + " " + query_align + " &> {log}"
            )

