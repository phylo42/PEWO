'''
module to operate placements with APPLES

@author Benjamin Linard
'''


import os

configfile: "config.yaml"

#debug
if (config["debug"]==1):
    print("epa: "+os.getcwd())

#rule all:
#    input: expand(config["workdir"]+"/EPA/{pruning}/g{gepa}/{pruning}_r{length}_g{gepa}_epa.jplace", pruning=range(0,config["pruning_count"],1), length=config["read_length"], gepa=config["config_epa"]["G"])

rule placement_apples:
    input:
        r=config["workdir"]+"/HMM/{pruning}_r{length}.fasta_refs",
        q=config["workdir"]+"/HMM/{pruning}_r{length}.fasta_queries",
        t=config["workdir"]+"/T/{pruning}.tree",
    output:
        out=config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace"
    log:
        config["workdir"]+"/logs/placement_apples/{pruning}_r{length}_m{meth}_c{crit}_apples.log"
    version: "1.0"
    params:
        outname=config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace"
    shell:
        """
        run_apples.py -s {input.r} -q {input.q} -t {input.t} -T 1 -m {wildcards.meth} -c {wildcards.crit} -o {params.outname}
        """