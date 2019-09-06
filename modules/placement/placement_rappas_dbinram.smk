'''
module to operate placements with RAPPAS
note: this module expect AR to be already computed

@author Benjamin Linard
'''

# TODO: manage model parameters

configfile: "config.yaml"


import os

#debug
if (config["debug"]==1):
    print("epa: "+os.getcwd())
#debug

'''
all read lengths are passed in a single rappas execution
so read length cannot be wildcards and must be set manually
'''
def setinputsreads(pruning):
    l=list()
    for length in config["read_length"]:
        l.append(config["workdir"]+"/R/"+pruning+"_r"+str(length)+".fasta")
    return l

def setoutputs():
    l=list()
    for length in config["read_length"]:
        l.append(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r"+str(length)+"_k{k}_o{omega}_rappas.jplace")
    return l

#rule all:
#    input: expand(config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config/{pruning}_r{length}_k{k}_o{omega}_rappas.jplace", pruning=1, length=config["read_length"],k=6, omega=1.0)

rule dbbuild_rappas:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}.tree",
        arseq=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_seq.txt",
        artree=config["workdir"]+"/RAPPAS/{pruning}/AR/extended_align.phylip_phyml_ancestral_tree.txt",
        r=lambda wildcards: setinputsreads(wildcards.pruning)
    output:
        setoutputs()
    log:
        config["workdir"]+"/logs/placement_rappas/{pruning}_k{k}_o{omega}.log"
    version: "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        reduc=config["config_rappas"]["reduction"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/AR",
        workdir=config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_config",
        dbfilename="DB.bin",
        querystring=lambda wildcards, input : ",".join(input.r)
    run:
         shell(
            "java -Xms8G -jar RAPPAS.jar -p b -b $(which phyml) -m GTR -c 4 "
            "-k {wildcards.k} --omega {wildcards.omega} -t {input.t} -r {input.a} -q {params.querystring} "
            "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {params.reduc} "
            "--use_unrooted --dbinram --dbfilename {params.dbfilename} &> {log} "
         )
         for length in config["read_length"]:
            shell(
                "mv {params.workdir}/placements_{wildcards.pruning}_r"+str(length)+".fasta.jplace "
                "{params.workdir}/{wildcards.pruning}_r"+str(length)+"_k{wildcards.k}_o{wildcards.omega}_rappas.jplace "
            )