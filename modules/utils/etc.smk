'''
diverse utilitarian functions

@author Benjamin Linard
'''


'''
extract phylo parameters from info file to transfer them to phyml
'''
def extract_params(file):
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