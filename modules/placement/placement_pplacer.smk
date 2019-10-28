'''
module to operate placements with PPLACER
builds first a pplacer packe with taxtastic, then compute placement using the package

@author Benjamin Linard
'''

import os

#debug
if (config["debug"]==1):
    print("ppl: "+os.getcwd())
#debug

#rule all:
#    input: expand(config["workdir"]+"/PPLACER/{pruning}_r{length}_pplacer.jplace", pruning=range(0,config["pruning_count"],1), length=config["read_length"])

'''
build pplacer pkgs using taxtastic
'''
rule build_package:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}.tree",
        s=config["workdir"]+"/T/{pruning}_optimised.info"
    output:
        directory(config["workdir"]+"/PPLACER/{pruning}/{pruning}_refpkg")
    log:
        config["workdir"]+"/logs/taxtastic/{pruning}.log"
    version: "1.00"
    params:
        dir=config["workdir"]+"/PPLACER/{pruning}/{pruning}_refpkg"
    shell:
        "taxit create -P {params.dir} -l locus -f {input.a} -t {input.t} -s {input.s} &> {log}"


'''
placement itself
note: pplacer option '--out-dir' is not functional, it writes the jplace in current directory
which required the addition of the explicit 'cd'
'''
rule placement_pplacer:
    input:
        a=config["workdir"]+"/HMM/{pruning}_r{length}.fasta",
        p=config["workdir"]+"/PPLACER/{pruning}/{pruning}_refpkg"
    output:
        config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer.jplace"
    log:
        config["workdir"]+"/logs/placement_pplacer/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer_benchmark.tsv", config["repeats"])
    version: "1.00"
    params:
        o=config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer.jplace",
        maxp=config["maxplacements"],
        minlwr=config["minlwr"]
    run:
        if config["config_pplacer"]["premask"]==1 :
            shell("pplacer -o {params.o} --verbosity 2 --max-strikes {wildcards.msppl} --strike-box {wildcards.sbppl} --max-pitches {wildcards.mpppl} --keep-at-most {params.maxp} --keep-factor {params.minlwr} -c {input.p} {input.a} &> {log}")
        else:
            shell("pplacer -o {params.o} --verbosity 2 --max-strikes {wildcards.msppl} --strike-box {wildcards.sbppl} --max-pitches {wildcards.mpppl} --keep-at-most {params.maxp} --keep-factor {params.minlwr} --no-pre-mask -c {input.p} {input.a} &> {log}")