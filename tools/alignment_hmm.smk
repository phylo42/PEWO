'''
module to operate hmm profile alignments between pruned leaves and pruned alignments
1) build hmm profile from pruned alignment
2) align reads to profile
3) convert psiblast output alignment to fasta alignment
@author Benjamin Linard
'''

configfile: "config.yaml"

rule all:
    input: expand("HMM/{pruning}_r{length}.fasta", pruning=range(1,config["pruning_count"]+1,1), length=config["read_length"])

'''
build hmm profile
'''
rule hmmbuild:
    input:
        "A/{pruning}.align"
    output:
        "HMM/{pruning}.hmm"
    log:
        "logs/hmmbuild/{pruning}.log"
    version: "1.0"
    params:
        states=config["states"]
    threads: 1
    shell:
        "hmmbuild --cpu {threads} --{params.states} "
        "{output} {input} &> {log}"

'''
align to profile
'''
rule hmmalign:
    input:
        hmm="HMM/{pruning}.hmm",
        align="A/{pruning}.align",
        reads="R/{pruning}_r{length}.fasta"
    output:
        temp("HMM/{pruning}_r{length}.psiblast")
    version: "1.0"
    log:
        "logs/hmmbuild/{pruning}_r{length}.log"
    params:
        states=config["states"]
    shell:
        "hmmalign --{params.states} --outformat PSIBLAST -o {output} "
        "--mapali {input.align} {input.hmm} {input.reads} &> {log}"

'''
convert from psiblast to fast format
'''
rule psiblast_to_fasta:
    input:
        "HMM/{pruning}_r{length}.psiblast"
    output:
        "HMM/{pruning}_r{length}.fasta"
    version: "1.0"
    log:
        "logs/psiblast2fasta/{pruning}_r{length}.log"
    shell:
        "scripts/psiblast2fasta.py {input} {output} &> {log}"