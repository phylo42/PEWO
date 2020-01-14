"""
Diverse utilitarian functions
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"


from Bio import SeqIO


def get_sequence_ids(input_file):
    """
    Retrieves sequence IDs from the input .fasta file.
    """
    return [record.id for record in SeqIO.parse(input_file, "fasta")]


# get IDs of all queries in the file
query_ids = get_sequence_ids(config["dataset_reads"])



def extract_params(file):
    '''
    extract phylo parameters from info file to transfer them to phyml
    '''
    res={}
    with open(file,'r') as infofile:
        lines = infofile.readlines()
        for l in lines:
            if l.startswith("Substitution Matrix:") :
                res["model"]=l.split(":")[1].strip()
            if l.startswith("alpha:") :
                res["alpha"]=l.split(":")[1].strip()
    infofile.close()
    return res

def select_model_phymlstyle():
    if config["phylo_params"]["model"]=="GTR+G":
        return "GTR"
    if config["phylo_params"]["model"]=="JTT+G":
        return "JTT"
    if config["phylo_params"]["model"]=="WAG+G":
        return "WAG"
    if config["phylo_params"]["model"]=="LG+G":
        return "LG"

def select_model_raxmlstyle():
    if config["phylo_params"]["model"]=="GTR+G":
        return "GTRGAMMA"
    if config["phylo_params"]["model"]=="JTT+G":
        return "PROTGAMMAJTT"
    if config["phylo_params"]["model"]=="WAG+G":
        return "PROTGAMMAWAG"
    if config["phylo_params"]["model"]=="LG+G":
        return "PROTGAMMALG"

'''
select correct ancestral reconstruction binary depending on value set in config for arsoft
'''
def select_arbin(arsoft):
    if arsoft == "PHYML":
        return "phyml"
    elif arsoft == "RAXMLNG" :
        return "raxml-ng"
    elif (arsoft == "PAML") and (config["states"]==0):
        return "baseml"
    elif (arsoft == "PAML") and (config["states"]==1):
        return "codeml"

def expected_ar_outputs(arsoft):
    res=list()
    if arsoft == "PHYML":
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_ancestral_seq.txt")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_ancestral_tree.txt")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_stats.txt")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_tree.txt")
    elif arsoft == "RAXMLNG" :
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.log")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.ancestralTree")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.ancestralProbs")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.startTree")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.ancestralStates")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.rba")
    elif arsoft == "PAML":
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/rst")
    return res



def tmpdir_prefix(wildcards):
    return wildcards.pruning+"_r"+wildcards.length


def get_jplace_inputs():
    """
    Creates a list of all .jplace files that should be present before computing node distances/likelihoods
    """
    inputs = []
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
                config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_ar{arsoft}_rappas.jplace",
                pruning=range(0,config["pruning_count"]),
                k=config["config_rappas"]["k"],
                omega=config["config_rappas"]["omega"],
                length=config["read_length"],
                reduction=config["config_rappas"]["reduction"],
                arsoft=config["config_rappas"]["arsoft"]
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
    return inputs

