'''
functions related to workflow constructions
e.g., define snakemake outputs depending on tested software

@author Benjamin Linard
'''


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
builds the list of outputs,for a "accuracy" workflow
'''
def build_accuracy_workflow():
    l=list()
    #placements
    l.append(
        build_placements_workflow()
    )
    #generate node distances
    l.append(config["workdir"]+"/results.csv")
    #collection of results and generation of summary plots
    l.append(set_plot_outputs())

    return l

'''
builds the list of outputs,for a "resources" workflow
'''
def build_resources_workflow():

    l=list()

    #call outputs from operate_inputs module to build input reads as pruning=0 and r=0
    l.append( config["workdir"]+"/A/0.align")
    l.append( config["workdir"]+"/T/0.tree")
    l.append( config["workdir"]+"/G/0.fasta")
    l.append( config["workdir"]+"/R/0_r0.fasta")

    #placements
    l.append(
        build_placements_workflow()
    )

    #collection of results and generation of summary plots
    #l.append(build_plots())

    return l

'''
builds expected outputs from placement software are tested.
("test_soft" field in the config file)
'''
def build_placements_workflow():

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
                config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer.jplace",
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

    if "rappas2" in config["test_soft"]:
        l.append(
            expand(
                config["workdir"]+"/RAPPAS2/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_rappas.jplace",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"]
            )
        )

    return l


'''
define plot that will be computed
'''
def set_plot_outputs():
    l=list()
    #epa-ng
    l.append( expand(config["workdir"]+"/summary_plot_epang_{heuristic}.svg",heuristic=config["config_epang"]["heuristics"]) )
    #all other software
    l.append( expand(config["workdir"]+"/summary_plot_{soft}.svg",soft=[x for x in config["test_soft"] if x!="epang"]) )
    return l