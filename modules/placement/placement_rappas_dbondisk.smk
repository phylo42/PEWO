'''
module to operate placements with RAPPAS
note: this module expect AR to be already computed

@author Benjamin Linard
'''

#TODO: add model parameters support

import os

#debug
if (config["debug"]==1):
    print("epa: "+os.getcwd())
#debug

rule dbbuild_rappas:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}.tree",
        ar=lambda wildcards: expected_ar_outputs(wildcards.arsoft)
    output:
        q=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/k{k}_o{omega}/DB.bin"
    log:
        config["workdir"]+"/logs/dbbuild_rappas/{pruning}_k{k}_o{omega}_red{reduction}_ar{arsoft}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas-dbbuild_benchmark.tsv", config["repeats"])
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR",
        workdir=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/k{k}_o{omega}",
        dbfilename="DB.bin",
        arbin=select_arbin(wildcards.arsoft)
    run:
         shell(
            "java -Xms2G -Xmx"+str(config["config_rappas"]["memory"])+"G -jar $(which RAPPAS.jar) -v 1 -p b -b $(which {params.arbin}) "
            "-k {wildcards.k} --omega {wildcards.omega} -t {input.t} -r {input.a} "
            "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {wildcards.reduction} "
            "--use_unrooted --dbfilename {params.dbfilename} &> {log} "
         )


rule placement_rappas:
    input:
        db=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/k{k}_o{omega}/DB.bin",
        r=config["workdir"]+"/R/{pruning}_r{length}.fasta",
    output:
        config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas.jplace"
    log:
        config["workdir"]+"/logs/placement_rappas/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_ar{arsoft}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas-placement_benchmark.tsv", config["repeats"])
    version: "1.00"
    params:
        workdir=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/k{k}_o{omega}",
        maxp=config["maxplacements"],
        minlwr=config["minlwr"]
    run:
         shell(
            "java -Xms2G -Xmx"+str(config["config_rappas"]["memory"])+"G -jar $(which RAPPAS.jar) "
            "--keep-at-most {params.maxp} --keep-factor {params.minlwr} "
            "-v 1 -p p -d {input.db} -q {input.r} -w {params.workdir}  &> {log} ; "
            "mv {params.workdir}/placements_{wildcards.pruning}_r{wildcards.length}.fasta.jplace {params.workdir}/{wildcards.pruning}_r{wildcards.length}_k{wildcards.k}_o{wildcards.omega}_red{wildcards.reduction}_ar{arsoft}_rappas.jplace"
         )