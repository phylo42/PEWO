'''
WORKFLOW TO EVALUATE PLACEMENT ACCURACY, GIVEN PARAMETERS SET IN "config.yaml"
This snakefile loads all necessary modules and builds the evaluation workflow itself
based on the setup defined in the config file.
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
#phylo-kmer placement, e.g.: rappas
include:
    "modules/op/operate_ar.smk"
include:
    "modules/placement/placement_rappas_dbinram.smk"
#alignment (for distance-based and ML approaches)
include:
    "modules/alignment/alignment_hmm.smk"
#ML-based placements, e.g.: epa, epang, pplacer
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
#distance-based placements, e.g.: apples
include:
    "modules/placement/placement_apples.smk"

#results evaluation and plots
include:
    "modules/op/operate_nodedistance.smk"
include:
    "modules/op/operate_plots.smk"


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
this function builds the list of expected workflow outputs, e.g., which placement software are tested.
("test_soft" field in the config file)
'''
def build_workflow():
    l=list()
    #tree optimization
    l.append(
        expand(
            config["workdir"]+"/T/{pruning}_optimised.tree",
            pruning=range(0,config["pruning_count"],1)
        )
    )
    #hmm alignments for alignment-based methods
    if ("epa" in config["test_soft"]) or ("epang" in config["test_soft"]) or ("pplacer" in config["test_soft"]) or ("apples" in config["test_soft"]) :
        l.append(
            expand(
                config["workdir"]+"/HMM/{pruning}_r{length}.fasta",
                pruning=range(0,config["pruning_count"],1),
                length=config["read_length"]
            )
        )
    #pplacer placements
    if "pplacer" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_ppl.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                msppl=config["config_pplacer"]["max-strikes"],
                sbppl=config["config_pplacer"]["strike-box"],
                mpppl=config["config_pplacer"]["max-pitches"]
            )
        )
    #epa placements
    if "epa" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/EPA/{pruning}/g{gepa}/{pruning}_r{length}_g{gepa}_epa.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                gepa=config["config_epa"]["G"]
            )
        )
    #epa-ng placements
    if "epang" in config["test_soft"] :
        l.append(
            #different heuristics can be called, leading to different results and completely different runtimes
            select_epang_heuristics()
        )
    #apples placements
    if "apples" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                meth=config["config_apples"]["methods"],
                crit=config["config_apples"]["criteria"]
            )
        )
    #rappas placements
    #for accuracy evaluation, the dbinram mode is used to avoid redundant database constructions
    #(basically bulding a DB once per pruning/parameters combination)
    if "rappas" in config["test_soft"] :
        l.append(
            expand(
                config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_rappas.jplace",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"]
            )
        )
    #generate node distances
    l.append(config["workdir"]+"/results.csv")
    #collection of results and generation of summary plots
    l.append(expand(config["workdir"]+"/summary_plot_{soft}.svg",soft=config["test_soft"]));

    return l



'''
top snakemake rule, necessary to launch the workflow
'''
rule all:
     input:
        build_workflow()

