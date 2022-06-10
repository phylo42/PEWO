"""
Diverse utilitarian functions
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


def extract_params(file):
    """
    extract phylo parameters from info file to transfer them to phyml
    """
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

def extract_params_raxmlng(file):
    """
    extract phylo parameters from info file to transfer them to phyml
    """
    res={}
    with open(file, 'r') as infofile:
        lines = infofile.readlines()
        for l in lines:
            if l.startswith("   Rate heterogeneity:"):
                res["alpha"]=l.split(":")[2][0:9].strip()
    print("coucou",res)
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

def select_model_raxmlngstyle():
    model=config["phylo_params"]["model"]
    category=config["phylo_params"]["categories"]
    if model=="GTR+G":
        return "GTR+FC+G" + str(category)
    if model=="JTT+G":
        return  "JTT+FC+G" + str(category)
    if model=="WAG+G":
        return  "WAG+FC+G" + str(category)
    if model=="LG+G":
        return "LG+FC+G" + str(category)
