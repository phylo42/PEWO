'''
module to operate placements with RAPPAS
note: this module expect AR to be already computed

@author Benjamin Linard
'''

#TODO: add model parameters support


#configfile: "config.yaml"


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
        t=config["workdir"]+"/T/{pruning}.tree",
        arseq=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_seq.txt",
        artree=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_tree.txt",
    output:
        q=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/DB.bin"
    log:
        config["workdir"]+"/logs/dbbuild_rappas/{pruning}_k{k}_o{omega}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_k{k}_o{omega}.dbbuild_rappas.benchmark.tsv", config["repeats"])
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        reduc=config["config_rappas"]["reduction"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/AR",
        workdir=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config",
        dbfilename="DB.bin"
    run:
         shell(
            "java -Xms2G -Xmx"+str(config["config_rappas"]["memory"])+"G -jar $(which RAPPAS.jar) -v 1 -p b -b $(which phyml) "
            "-k {wildcards.k} --omega {wildcards.omega} -t {input.t} -r {input.a} "
            "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {params.reduc} "
            "--use_unrooted --dbfilename {params.dbfilename} &> {log} "
         )


rule placement_rappas:
    input:
        db=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/DB.bin",
        r=config["workdir"]+"/R/{pruning}_r{length}.fasta",
    output:
        config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_r{length}_k{k}_o{omega}.placement_rappas.benchmark.tsv", config["repeats"])
    log:
        config["workdir"]+"/logs/placement_rappas/{pruning}/k{k}_o{omega}_config/r{length}.log"
    version: "1.00"
    params:
        workdir=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config"
    run:
         shell(
            "java -Xms2G -Xmx"+str(config["config_rappas"]["memory"])+"G -jar $(which RAPPAS.jar) -v 1 -p p -d {input.db} -q {input.r} -w {params.workdir}  &> {log} ; "
            "mv {params.workdir}/placements_{wildcards.pruning}_r{wildcards.length}.fasta.jplace {params.workdir}/{wildcards.pruning}_r{wildcards.length}_k{wildcards.k}_o{wildcards.omega}_rappas.jplace"
         )