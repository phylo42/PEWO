'''
compute the ND (node distances) metric using the jplace outputs
@author Benjamin Linard
'''


import os

#debug
if (config["debug"]==1):
    print("prunings: "+os.getcwd())
#debug


#rule all:
#    input: config["workdir"]+"/results.csv"

'''
list all jplaces that should be present before computing node distances
'''
def define_inputs():
    inputs=list()
    if "epa" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/EPA/{pruning}/g{gepa}/{pruning}_r{length}_g{gepa}_epa.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                gepa=config["config_epa"]["G"]
            )
        )
    if "pplacer" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                msppl=config["config_pplacer"]["max-strikes"],
                sbppl=config["config_pplacer"]["strike-box"],
                mpppl=config["config_pplacer"]["max-pitches"]
            )
        )
    if "epang" in config["test_soft"]:
        inputs.append(
            select_epang_heuristics()
        )
    if "rappas" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_rappas.jplace",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"]
            )
        )
    if "apples" in config["test_soft"]:
        inputs.append(
            expand(
                config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                meth=config["config_apples"]["methods"],
                crit=config["config_apples"]["criteria"]
            )
        )
    #print(inputs)
    return inputs


rule compute_nodedistance:
    input:
        jplace_files=define_inputs()
    output:
        config["workdir"]+"/results.csv"
    log:
        config["workdir"]+"/logs/compute_nd.log"
    params:
        workdir=config["workdir"],
        compute_epa= 1 if "epa" in config["test_soft"] else 0 ,
        compute_epang= 1 if "epang" in config["test_soft"] else 0,
        compute_pplacer= 1 if "pplacer" in config["test_soft"] else 0,
        compute_rappas= 1 if "rappas" in config["test_soft"] else 0,
        compute_apples= 1 if "apples" in config["test_soft"] else 0
    shell:
        "java -cp PEWO.jar DistanceGenerator_LITE2 {params.workdir} "
        "{params.compute_epa} {params.compute_epang} {params.compute_pplacer} {params.compute_rappas} {params.compute_apples} &> {log}"