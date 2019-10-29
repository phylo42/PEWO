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

def tmpdir_prefix(wildcards):
    return wildcards.pruning+"_r"+wildcards.length