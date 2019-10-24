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


def tmpdir_prefix(wildcards):
    return wildcards.pruning+"_r"+wildcards.length

'''
operate placement
note: epa-ng does not allow to set a name for outputs, it always uses epa_info.log and epa_result.log
moreover, it will refuse to rerun if epa-info.log is present, this obliges to built a temporary working directory
for each launch (if not concurrent launches will fail if epa_info.log is present or worse write in the same file
if --redo option is used).
'''
rule placement_epang_h2:
    input:
        r=config["workdir"]+"/HMM/{pruning}_r{length}.fasta_refs",
        q=config["workdir"]+"/HMM/{pruning}_r{length}.fasta_queries",
        t=config["workdir"]+"/T/{pruning}.tree",
        m=config["workdir"]+"/T/{pruning}_optimised.info"
    output:
        os.path.join(config["workdir"],"EPANG")+"/{pruning}/h2/{pruning}_r{length}_h2_bigg{biggepang}_epang.jplace"
    log:
        config["workdir"]+"/logs/placement_epang/{pruning}_r{length}_h2_bigg{biggepang}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_r{length}_h2_bigg{biggepang}.epang.benchmark.tsv", config["repeats"])
    version: "1.0"
    params:
        tmpdir=os.path.join(config["workdir"],"EPANG","{pruning}/h2/{pruning}_r{length}_bigg{biggepang}"),
        dir=config["workdir"]+"/EPANG/{pruning}/h2",
        maxp=config["maxplacements"],
        minlwr=config["minlwr"]
    run:
        if config["config_epang"]["premask"]==1:
            shell(
                """
                mkdir -p {params.tmpdir}
                epa-ng --preserve-rooting on --filter-max {params.maxp} --filter-min-lwr {params.minlwr} -G {wildcards.biggepang} --verbose -w {params.tmpdir} -q {input.q} -t {input.t} --ref-msa {input.r} -T 1 -m {input.m} &> {log}
                cp {params.tmpdir}/epa_info.log {params.dir}/{wildcards.pruning}_r{wildcards.length}_h2_bigg{wildcards.biggepang}_epang_info.log
                cp {params.tmpdir}/epa_result.jplace {params.dir}/{wildcards.pruning}_r{wildcards.length}_h2_bigg{wildcards.biggepang}_epang.jplace
                rm -r {params.tmpdir}
                """
            )
        else:
            shell(
                """
                mkdir -p {params.tmpdir}
                epa-ng --no-pre-mask --preserve-rooting on --filter-max {params.maxp} --filter-min-lwr {params.minlwr} -G {wildcards.biggepang} --verbose -w {params.tmpdir} -q {input.q} -t {input.t} --ref-msa {input.r} -T 1 -m {input.m} &> {log}
                cp {params.tmpdir}/epa_info.log {params.dir}/{wildcards.pruning}_r{wildcards.length}_h2_bigg{wildcards.biggepang}_epang_info.log
                cp {params.tmpdir}/epa_result.jplace {params.dir}/{wildcards.pruning}_r{wildcards.length}_h2_bigg{wildcards.biggepang}_epang.jplace
                rm -r {params.tmpdir}
                """
            )