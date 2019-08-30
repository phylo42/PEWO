'''
module to operate placements with EPA-ng

@author Benjamin Linard
'''

# TODO add support of model parameters once module for pruned tree optimisation is done
# TODO used optimsed tree version

#configfile: "config.yaml"

import os

#debug
if (config["debug"]==1):
    print("epang: "+os.getcwd())
#debug

#rule all:
#    input: expand(os.path.join(config["workdir"],"EPANG")+"/{pruning}_r{length}_epang.jplace", pruning=range(0,config["pruning_count"],1), length=config["read_length"])

'''
split hmm alignment results in "query only" and "reference alignment only" su-alignments
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


def tmpdir_prefix(wildcards):
    return wildcards.pruning+"_r"+wildcards.length

'''
operate placement
note: epa-ng does not allow to set a name for outputs, it always uses epa_info.log and epa_result.log
moreover, it will refuse to rerun if epa-info.log is present, this obliges to built a temporary working directory
for each launch (if not concurrent launches will fail if epa_info.log is present or worse write in the same file
if --redo option is used).
'''
rule placement_epang:
    input:
        r=config["workdir"]+"/HMM/{pruning}_r{length}.fasta_refs",
        q=config["workdir"]+"/HMM/{pruning}_r{length}.fasta_queries",
        t=config["workdir"]+"/T/{pruning}.tree",
        m=config["workdir"]+"/T/{pruning}_optimised.info"
    output:
        os.path.join(config["workdir"],"EPANG")+"/{pruning}_r{length}_epang.jplace"
    log:
        config["workdir"]+"/logs/placement_epang/{pruning}_r{length}.log"
    version: "1.0"
    params:
        tmpdir="{pruning}_r{length}",
        dir=os.path.join(config["workdir"],"EPANG")
    shell:
        """
        mkdir -p {params.dir}/{params.tmpdir}
        epa-ng --preserve-rooting on --verbose -w {params.dir}/{params.tmpdir} -q {input.q} -t {input.t} --ref-msa {input.r} -T 1 -m {input.m} &> {log}
        cp {params.dir}/{params.tmpdir}/epa_info.log {params.dir}/{wildcards.pruning}_r{wildcards.length}_epang_info.log
        cp {params.dir}/{params.tmpdir}/epa_result.jplace {params.dir}/{wildcards.pruning}_r{wildcards.length}_epang.jplace
        rm -r {params.dir}/{params.tmpdir}
        """
