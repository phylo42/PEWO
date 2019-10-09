'''
WORKFLOW TO EVALUATE PLACEMENT ACCURACY, GIVEN PARAMATERS SET IN eval_accuracy_config.yaml
This top snakefile loads all modules necessary to the evaluation itself.

@author Benjamin Linard
'''

#this config file is set globally for all subworkflows
configfile: "config.yaml"

#prunings
include:
    "modules/op/operate_prunings.smk"
#tree optimisation
include:
    "modules/op/operate_optimisation.smk"
#alignment-free placements, e.g. : rappas
include:
    "modules/op/operate_ar.smk"
include:
    "modules/placement/placement_rappas_dbinram.smk"
#alignments
include:
    "modules/alignment/alignment_hmm.smk"
#alignment-based placements, e.g. : epa, epang, pplacer
include:
    "modules/placement/placement_epa.smk"
include:
    "modules/placement/placement_ppl.smk"
include:
    "modules/placement/placement_epang_h1.smk"
include:
    "modules/placement/placement_epang_h2.smk"
include:
    "modules/placement/placement_epang_h3.smk"
include:
    "modules/placement/placement_epang_h4.smk"
#distance-based placements:
include:
    "modules/placement/placement_apples.smk"

#results evaluation and plots
include:
    "modules/op/operate_nodedistance.smk"
include:
    "modules/op/operate_plots.smk"

import numpy as numpy

'''
list of tested ks
'''
def k_list():
    l=[]
    for k in range(config["config_rappas"]["kmin"],config["config_rappas"]["kmax"]+1,config["config_rappas"]["kstep"]):
        l.append(str(k))
    return l

'''
list of tested omegas
'''
def omega_list():
    l=[]
    for o in numpy.arange(config["config_rappas"]["omin"], config["config_rappas"]["omax"]+config["config_rappas"]["ostep"], config["config_rappas"]["ostep"]):
        l.append(str(o))
    return l

'''
accessory function to correctly set which epa-ng heuristics are tested and with which parameters
'''
def select_epang_heuristics():
    l=[]
    if "h1" in config["config_epang"]["heuristics"]:
        l.append(
            expand(     config["workdir"]+"/EPANG/{pruning}/h1/{pruning}_r{length}_h1_g{gepang}_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        gepang=config["config_epang"]["h1"]["g"]
                   )
        )
    if "h2" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/EPANG/{pruning}/h2/{pruning}_r{length}_h2_bigg{biggepang}_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        biggepang=config["config_epang"]["h2"]["G"]
                        )
        )
    if "h3" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/EPANG/{pruning}/h3/{pruning}_r{length}_h3_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"]
                        )
        )
    if "h4" in config["config_epang"]["heuristics"]:
        l.append(
            expand(
                config["workdir"]+"/EPANG/{pruning}/h4/{pruning}_r{length}_h4_epang.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"]
                )
            )
    return l


'''
top rule defining the workflow
'''
rule all:
     input:
         #tree optimization
         expand(    config["workdir"]+"/T/{pruning}_optimised.tree",
                    pruning=range(0,config["pruning_count"],1)
                    ),

         #hmm alignments for alignment-based methods
         expand(    config["workdir"]+"/HMM/{pruning}_r{length}.fasta",
                    pruning=range(0,config["pruning_count"],1),
                    length=config["read_length"]
                    ),

         #pplacer placements
         expand(    config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_ppl.jplace",
                    pruning=range(0,config["pruning_count"]),
                    length=config["read_length"],
                    msppl=config["config_pplacer"]["max-strikes"],
                    sbppl=config["config_pplacer"]["strike-box"],
                    mpppl=config["config_pplacer"]["max-pitches"]
                    ),

         #epa placements
         expand(    config["workdir"]+"/EPA/{pruning}/g{gepa}/{pruning}_r{length}_g{gepa}_epa.jplace",
                    pruning=range(0,config["pruning_count"]),
                    length=config["read_length"],
                    gepa=config["config_epa"]["G"]
                    ),

         #epa-ng placements
         #different heuristics can be called, leading to different results and completely different runtimes
         select_epang_heuristics(),

         #apples placements
         expand(    config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace",
                    pruning=range(0,config["pruning_count"]),
                    length=config["read_length"],
                    meth=config["config_apples"]["methods"],
                    crit=config["config_apples"]["criteria"]
                    ),

         #RAPPAS placements
         #for accuracy evalution, the dbinram mode is used to avoid redundant database constructions
         expand(    config["workdir"]+"/RAPPAS/{pruning}/k{k}_o{omega}_red{reduction}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_rappas.jplace",
                     pruning=range(0,config["pruning_count"]),
                     k=k_list(),
                     omega=omega_list(),
                     length=config["read_length"],
                     reduction=config["config_rappas"]["reduction"]
                     ),

         #collection of results and generation of summary plots
         #config["workdir"]+"/experience_complitude.pdf"

