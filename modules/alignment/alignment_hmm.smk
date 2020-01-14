'''
module to operate hmm profile alignments between pruned leaves and pruned alignments
1) build hmm profile from pruned alignment
2) align reads to profile
3) convert psiblast output alignment to fasta alignment

@author Benjamin Linard
'''

import os

#debug
if (config["debug"]==1):
    print("hmm: "+os.getcwd())
#debug

#configfile: "config.yaml"

#rule all:
#    input: expand(config["workdir"]+"/HMM/{pruning}_r{length}.fasta", pruning=range(0,config["pruning_count"],1), length=config["read_length"])

'''
build hmm profile
'''
rule hmmbuild:
    input:
        config["workdir"]+"/A/{pruning}.align"
    output:
        config["workdir"]+"/HMM/{pruning}.hmm"
    log:
        config["workdir"]+"/logs/hmmbuild/{pruning}.log"
    version: "1.0"
    params:
        states=["dna"] if config["states"]==0 else ["amino"]
    threads: 1
    shell:
        "hmmbuild --cpu {threads} --{params.states} "
        "{output} {input} &> {log}"

'''
align to profile
'''
rule hmmalign:
    input:
        hmm=config["workdir"]+"/HMM/{pruning}.hmm",
        align=config["workdir"]+"/A/{pruning}.align",
        reads=config["workdir"]+"/R/{pruning}_r{length}.fasta"
    output:
        temp(config["workdir"]+"/HMM/{pruning}_r{length}.psiblast")
    version: "1.0"
    log:
        config["workdir"]+"/logs/hmmbuild/{pruning}_r{length}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_r{length}_hmmalign_benchmark.tsv", config["repeats"])
    params:
        states=["dna"] if config["states"]==0 else ["amino"]
    shell:
        "hmmalign --{params.states} --outformat PSIBLAST -o {output} "
        "--mapali {input.align} {input.hmm} {input.reads} &> {log}"

'''
convert from psiblast to fast format
'''
rule psiblast_to_fasta:
    input:
        config["workdir"]+"/HMM/{pruning}_r{length}.psiblast"
    output:
        config["workdir"]+"/HMM/{pruning}_r{length}.fasta"
    version: "1.0"
    log:
        config["workdir"]+"/logs/psiblast2fasta/{pruning}_r{length}.log"
    shell:
        "scripts/psiblast2fasta.py {input} {output} &> {log}"

'''
split hmm alignment results in "query only" and "reference alignment only" sub-alignments
contrary to other placement software, such input is required by epa-ng
'''
rule split_alignment:
    input:
        align=config["workdir"]+"/HMM/{pruning}_r{length}.fasta",
        reads=config["workdir"]+"/R/{pruning}_r{length}.fasta"
    output:
        config["workdir"]+"/HMM/{pruning}_r{length}.fasta_queries",
        config["workdir"]+"/HMM/{pruning}_r{length}.fasta_refs"
    version: "1.0"
    shell:
        "scripts/split_hmm_alignment.py {input.reads} {input.align}"