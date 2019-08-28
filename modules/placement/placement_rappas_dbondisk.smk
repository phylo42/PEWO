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

#rule all:
#    input: expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace", pruning=1, length=config["read_length"],k=6, omega=1.0)

rule dbbuild_rappas:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}_optimised.tree",
        arseq=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_seq.txt",
        artree=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_tree.txt",
    output:
        q=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/DB.bin",
    log:
        config["workdir"]+"/logs/rappas_dbbuild/{pruning}_k{k}_o{omega}.log"
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        reduc=config["config_rappas"]["reduction"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/AR",
        workdir=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config",
        dbfilename="DB.bin"
    shell:
         "java -jar RAPPAS.jar -p b -b $(which phyml) "
         "-k {wildcards.k} -o {wildcards.omega} -t {input.t} -r {input.a} "
         "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {params.reduc} "
         "--use_unrooted --dbfilename {params.dbfilename} &> {log} "


rule placement_rappas:
    input:
        db=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/DB.bin",
        r=config["workdir"]+"/R/{pruning}_r{length}.fasta",
    output:
        config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace",
    log:
        config["workdir"]+"/logs/rappas_placement/{pruning}/k{k}_o{omega}_config/r{length}.log"
    version: "1.00"
    params:
        workdir=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config"
    shell:
         """
         java -jar RAPPAS.jar -p p -d {input.db} -q {input.r} -w {params.workdir}  &> {log}
         mv {params.workdir}/placements_{wildcards.pruning}_r{wildcards.length}.fasta.jplace {params.workdir}/{wildcards.pruning}_r{wildcards.length}_k{wildcards.k}_o{wildcards.omega}_rappas.jplace
         """