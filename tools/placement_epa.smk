'''
module to operate placements with EPA (part of raxml)
note1: that raxml outputs many files, but only the jplace is kept
note2: raxml outputs results only in current working directory, so EPA dir needs to be explicitly set
@author Benjamin Linard
'''

# TODO: SSE3 version is currently used, there should be a way to test SSE3/AVX availability and launch correct version accordingly


import os

configfile: "config.yaml"

#as raxml needs absolute path to set workdir
outdir = os.path.join(os.getcwd(),"EPA")

rule all:
    input: expand("EPA/RAxML_portableTree.{pruning}_r{length}.jplace", pruning=range(1,config["pruning_count"]+1,1), length=config["read_length"])

rule placement_epa:
    input:
        hmm="HMM/{pruning}_r{length}.fasta",
        t="T/{pruning}.tree"
    output:
        temp("EPA/RAxML_classificationLikelihoodWeights.{pruning}_r{length}"),
        temp("EPA/RAxML_classification.{pruning}_r{length}"),
        temp("EPA/RAxML_entropy.{pruning}_r{length}"),
        temp("EPA/RAxML_info.{pruning}_r{length}"),
        temp("EPA/RAxML_labelledTree.{pruning}_r{length}"),
        temp("EPA/RAxML_originalLabelledTree.{pruning}_r{length}"),
        temp("HMM/{pruning}_r{length}.fasta.reduced"),      #note this one will disappear if reduction is deactivated
        protected("EPA/RAxML_portableTree.{pruning}_r{length}.jplace"),
    log:
        "logs/placement_epa/{pruning}_r{length}.log"
    version: "1.0"
    params:
        m=config["config_epa"]["m"],
        c=config["config_epa"]["c"],
        G=config["config_epa"]["G"],
        name='{pruning}_r{length}'
    shell:
        "raxmlHPC-SSE3 -f v -w {outdir} -G {params.G} -m {params.m} -c {params.c} -n {params.name} -s {input.hmm} -t {input.t} &> {log} "
