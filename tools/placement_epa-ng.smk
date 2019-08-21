'''
module to operate placements with EPA-ng
@author Benjamin Linard
'''

# TODO add support of model parameters once module for pruned tree optimisation is done

configfile: "config.yaml"

rule all:
    input: expand("EPA/RAxML_portableTree.{pruning}_r{length}.jplace", pruning=range(1,config["pruning_count"]+1,1), length=config["read_length"])

'''
split hmm alignment results in "query only" and "reference alignment only" su-alignments
contrary to other placement software, such input is required by epa-ng
'''
rule split_alignment:
    input:
        align="HMM/{pruning}_r{length}.fasta",
        reads="R/{pruning}_r{length}.fasta"
    output:
        "HMM/{pruning}_r{length}.fasta_queries",
        "HMM/{pruning}_r{length}.fasta_refs"
    version: "1.0"
    shell:
        "scripts/split_hmm_alignment.py {input.reads} {input.align}"


def tmpdir_prefix(wildcards):
    return wildcards.pruning+"_r"+wildcards.length

'''
operate placement
'''
rule placement_epa:
    input:
        r="HMM/{pruning}_r{length}.fasta_refs",
        q="HMM/{pruning}_r{length}.fasta_queries",
        t="T/{pruning}.tree",
        m="T/RAxML_info.optim_{pruning}.tree"
    output:
        protected("EPANG/{pruning}_r{length}_epa_result.jplace")
    log:
        "logs/placement_epang/{pruning}_r{length}.log"
    version: "1.0"
    params:
        tmpdir="{pruning}_r{length}"
    shell:
        """
        mkdir -p EPANG/{params.tmpdir}
        epa-ng --verbose -w EPANG/{params.tmpdir} -q {input.q} -t {input.t} --ref-msa {input.r} -T 1 -m {input.m} &> {log}
        mv EPANG/{params.tmpdir}/epa_info.log EPANG/{wildcards.pruning}_r{wildcards.length}_epa_info.log
        mv EPANG/{params.tmpdir}/epa_result.jplace EPANG/{wildcards.pruning}_r{wildcards.length}_epa_result.jplace
        rm -r EPANG/{params.tmpdir}
        """