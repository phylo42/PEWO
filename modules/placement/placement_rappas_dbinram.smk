'''
module to operate placements with RAPPAS
note: this module expect AR to be already computed

@author Benjamin Linard
'''

# TODO: SSE3 version is currently used, there should be a way to test SSE3/AVX availability and launch correct version accordingly
# TODO: use optimised tree version

configfile: "config.yaml"


import os

#debug
if (config["debug"]==1):
    print("epa: "+os.getcwd())
#debug

rule all:
    input: expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}/{pruning}_r{length}_rappas.jplace", pruning=1, length=config["read_length"],k=6, omega=1.0)



rule placement_rappas:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}_optimised.tree",
        r=config["workdir"]+"/R/{pruning}_r{length}.fasta",
        arseq=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_seq.txt",
        artree=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_tree.txt",
        workdir=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}"
    output:
        q=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}/{pruning}_r{length}_rappas.jplace",
    log:
        config["workdir"]+"/logs/rappas/k{k}_o{omega}/{pruning}_r{length}.log"
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        reduc=config["config_rappas"]["reduction"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/AR"
    shell:
         "java -jar RAPPAS.jar -p b -b $(which phyml) "
         "-k {wildcards.k} -o {wildcards.omega} -t {input.t} -r {input.a} -q {input.r} "
         "-w {input.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {params.reduc} "
         "--use_unrooted --dbinram &> {log} "
         """
         mv {input.workdir}/placements_{pruning}_r{length}.fasta_union.jplace {input.workdir}/{pruning}_r{length}_rappas.jplace
         """