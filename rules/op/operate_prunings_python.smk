import os

from pewo.pruning.pruning import pruning_operations



#########################################
# PIPELINE STARTS AFTER

def get_tree_input(wildcards) : #Fonction which allow to use the path of an tree.newick file from config.yaml
    return config["dataset_tree"]

def get_align_input(wildcards) : #Fonction which allow to use the path of an tree.newick file from config.yaml
    return config["dataset_align"]

def predict_tree_name():
    l=list()
    for i in range(config["pruning_count"]):
        l.append(os.path.join(config["workdir"],"T",str(i)+".tree"))
    return l

def predict_genome_name():
    l=list()
    for i in range(config["pruning_count"]):
        l.append(os.path.join(config["workdir"],"G",str(i)+".fasta"))
    return l

def predict_align_name():
    l=list()
    for i in range(config["pruning_count"]):
        l.append(os.path.join(config["workdir"],"A",str(i)+".align"))
    return l

def predict_request_name():
    l=list()
    for i in range(config["pruning_count"]):
        l.append(os.path.join(config["workdir"],"R",str(i)+"_r150.fasta"))
    return l

#######################
#### Rule part

rule all_of_this_rule:
    input:
        expand(
            os.path.join(config["workdir"],"A","{pruning}.fasta"),
            pruning=range(config["pruning_count"])
        )


rule PRUNING:
    input:
        t=get_tree_input,
        a=get_align_input
    output:
        ND=os.path.join(config["workdir"],"DISTANCE","NODE","ND.csv"),
        BD=os.path.join(config["workdir"],"DISTANCE","BRANCHE","BD.csv"),
        Diff=os.path.join(config["workdir"],"DIFFICULTY","Diff_of_pruning.csv"),
        PrunedTree=predict_tree_name(),
        PrunedGenome=predict_genome_name(),
        PrunedAlign=predict_align_name(),
        request=predict_request_name()

    params:
        #created by script_pruning.py :
        createND_file = lambda wildcards: os.path.join(config["workdir"],"NodeDistance.csv"),
        createBD_file = lambda wildcards: os.path.join(config["workdir"],"BrancheDistance.csv"),
        createDD_file = lambda wildcards: os.path.join(config["workdir"],"Difficulty.csv"),
    log:
        "logs/pruning.log"
    run:
        pruning_operations(config)
        shell(
            """
            mv {params.createND_file} {output.ND} 
            mv {params.createBD_file} {output.BD} 
            mv {params.createDD_file} {output.Diff} 
            """
        )

