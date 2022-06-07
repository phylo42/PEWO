#!/usr/bin/env python
# -*-coding: utf-8 -*

import os
import random
from typing import List, Dict

import numpy as np
import pandas as pd
from ete3 import Tree


def postorder_explo(tree) -> List:  # Exploring path (postorder) of the studied tree
    traverse = list(tree.traverse("postorder"))
    return traverse


def tree_root(traverse : List) -> bool:  # Boolean function. True = tree is root, False = tree is unroot
    j = 0
    n = 0
    for node in traverse:  # use tree path
        n = n + 1  # iterator of node
        if node.is_leaf():  # check if node is leaf
            j = j + 1  # iterator of leave
    if n == ((2 * j) - 1):  # check if rooted
        return True
    if n == ((2 * j) - 2):  # check if unrooted
        return False


def id_and_labels_features(traverse : List):  # create new features
    inter = 0
    nod = 0
    leaf = 0
    if tree_root(traverse):  # Use tree_root function to test if tree is rooted or not
        for node in traverse:
            if node.is_leaf():
                leaf = leaf + 1
                # create a new features newNameNode for leave and we keep the old name inside
                node.add_features(newNameNode="Leaf_" + str(leaf) + "__" + node.name)
            else:
                # create a new features newNameNode for root and we keep the old name inside
                if node.is_root():
                    node.add_features(newNameNode="Root___" + node.name)
                # create a new features newNameNode for node and we keep the old name inside
                else:
                    nod = nod + 1
                    node.add_features(newNameNode="Node_" + str(nod) + "__" + node.name)
            # create a new features nodeId for old the node and keep the old name inside
            node.add_features(nodeId=inter)

            inter = inter + 1
    else:  # Exactly the same than previously view but for unroot tree
        for node in traverse:
            if node.is_leaf():
                leaf = leaf + 1
                node.add_features(newNameNode="Leaf_" + str(leaf) + "__" + node.name)
            else:
                if node.is_root():
                    node.add_features(newNameNode="FAKEROOT___" + node.name)
                else:
                    nod = nod + 1
                    node.add_features(newNameNode="Node_" + str(nod) + "__" + node.name)
            node.add_features(nodeId=inter)

            inter = inter + 1

    return 0


def list_pruned_node(traverse : List, tree , minimumleaf : int, Nbrpruning: int):  # Choose a node to prune
    matches: List = []
    nbrleaves = int(len(tree))
    shuffle_traverse = traverse[:]
    random.shuffle(shuffle_traverse)
    it=-1
    for node in shuffle_traverse:
        it=it+1
        count = 0
        NP = tree.search_nodes(name=node.name)[0]
        for i in NP.iter_leaves():
            count+=1
        if count <= int(nbrleaves)-int(minimumleaf):
            matches.append(node)
        if len(matches) == int(Nbrpruning):
            print(str(Nbrpruning), "distinct pruning available for that tree")
            return matches
        if it == len(shuffle_traverse)-1:
            print("Only", len(matches), "pruning are possible on this tree. Config will be update to avoid error ...")
            return matches


def get_child(tree , nodeprune :List, liste : List):  # Get the names of a node and of all children
    liste.append(nodeprune.nodeId)  # Add nodename to a list
    NP = tree.search_nodes(nodeId=nodeprune.nodeId)[0]
    child = NP.children  # Search child
    if not nodeprune.is_leaf():
        for i in range(len(child)):
            get_child(tree, child[i], liste)
    return


def get_leafchild_name(tree , nodeprune : List, liste : List):  # Get the names of all children nodes
    if not nodeprune.is_leaf():
        NP = tree.search_nodes(nodeId=nodeprune.nodeId)[0]
        child = NP.children  # Search child
        for i in range(len(child)):
            get_leafchild_name(tree, child[i], liste)
    else:
        liste.append(nodeprune.name)  # Add nodename to a list
    return


def distance_and_align(workdir, tree: Tree, nodeprune, traverse, align: str):
    """
    in a single loop over nodes to  prune:
     - Create 2 distinct distance files (Node distance and Branches distance) in which every distance involve in pruning
     operation are saved
     - Create difficulty file (Difficulty of pruning sequences placement depend of the length of the branch previously pruned)
     - Create an alignement fasta file in which pruned sequences are remote of the align file as well as deletion site
     - Create a genome fasta file in which pruned sequences are save (without gap)
    :param workdir:
    :param tree:
    :param nodeprune:
    :param traverse:
    :param align:
    :return:
    """
    # Element necessary to save distance
    dictND = {}  # Create dict in each Node distance are save
    dictBD = {}  # Create dict in each Branche distance are save
    dictND["ID"] = []  # For the format of the csv file. From here
    dictBD["ID"] = []
    dictND[" "] = []
    dictBD[" "] = []
    dictND["ID"].append(" ")
    dictBD["ID"].append(" ")
    dictND[" "].append("LABEL")
    dictBD[" "].append("LABEL")  # to here

    # Element necessary to save Difficulty of pruning
    Diff = {"ID": [], "Nodeprune": [], "Difficulty": []}  # Create a dict in wich difficulty of pruning is save

    for pruned in range(len(nodeprune)): # for each pruning

        ##########
        # DISTANCE
        # Save distance (ND and BD between pruned branch and all other node

        dictND["ID"].append(nodeprune[pruned].nodeId)  # save ID of pruned node
        dictBD["ID"].append(nodeprune[pruned].nodeId)
        dictND[" "].append(nodeprune[pruned].newNameNode)  # save Label of pruned node
        dictBD[" "].append(nodeprune[pruned].newNameNode)

        NP = tree.search_nodes(nodeId=nodeprune[pruned].nodeId)[0]  # identifie pruned node in tree
        parent = NP.up  # identifie parent node
        childliste = []
        get_child(tree, nodeprune[pruned], childliste)  # identify child of pruned node

        Diff["ID"].append(nodeprune[pruned].nodeId)  # save pruned node name and ID
        Diff["Nodeprune"].append(nodeprune[pruned].newNameNode)
        sum = nodeprune[pruned].dist  # addition of branch length pruned with the considered node

        for node in traverse:  # for node in tree

            if node.nodeId in dictND:  # if a list is already done for a tree node
                if node.nodeId in childliste:  # if tree node is a child of pruned one or the pruned one
                    dictND[node.nodeId].append(-1)
                    dictBD[node.nodeId].append(-1)
                    sum = sum + node.dist # sum of pruned branch length = difficulty of pruning.
                else:
                    if node.nodeId == parent.nodeId:
                        dictND[node.nodeId].append(0)  # 0 Because are fix on it
                        dictBD[node.nodeId].append(node.dist)  # Save the length of the branch

                    else: # distance to other node save
                        dictND[node.nodeId].append(int(NP.get_distance(node, topology_only=True)))
                        dictBD[node.nodeId].append(NP.get_distance(node, topology_only=False))

            else:  # Same as previously, but initialisation of node list to save value
                dictND[node.nodeId] = []
                dictBD[node.nodeId] = []
                dictND[node.nodeId].append(node.newNameNode)
                dictBD[node.nodeId].append(node.newNameNode)

                if node.nodeId in childliste:
                    dictND[node.nodeId].append(-1)
                    dictBD[node.nodeId].append(-1)
                    sum = sum + node.dist

                else:
                    if node.nodeId == parent.nodeId:
                        # Dist
                        dictND[node.nodeId].append(0)
                        dictBD[node.nodeId].append(node.dist)

                    else:
                        # Distance
                        dictND[node.nodeId].append(int(NP.get_distance(node, topology_only=True)))
                        dictBD[node.nodeId].append(NP.get_distance(node, topology_only=False))

        ######################
        # For difficulty file :
        # save difficulty of pruning in a list
        Diff["Difficulty"].append(sum)

        #######################################
        # ALIGNMENT FILE and GENOME FILE
        # Update reference alignment file (without pruned leave and site full of gap)
        # Create a fasta file in which genome of pruned leaves are save (not a alignment)

        #Here we save leaf names and sequences in two different list in fonction of it is pruned or not
        childliste = []
        get_leafchild_name(tree, nodeprune[pruned], childliste)  # identify child of pruned node
        name = [] # store name of node not pruned
        prunedname=[] # store name of node and leaves pruned
        seq = [] # store sequence not pruned
        prunedseq=[] # store sequence pruned
        file = open(align, 'r') # read align file
        lines = file.readlines()
        itline = -1
        for line in lines: # for each lines
            itline = itline + 1
            if line.startswith(">"): #if line is a header
                if line[1:-1] in childliste : # if leave is pruned
                    prunedname.append(line[1:-1]) # save header of pruned leaves
                    sous_seq=[]
                    for c in range(len(lines[itline + 1]) - 1): # save sequences of pruned leaves
                        if lines[itline + 1][c] != "-" :
                            sous_seq.append(lines[itline + 1][c])
                    prunedseq.append(sous_seq)
                else:
                    name.append(line[1:-1]) # save header of not pruned leaves
                    sous_seq = []
                    for c in range(len(lines[itline + 1]) - 1): # save sequences of not pruned leaves
                        sous_seq.append(lines[itline + 1][c])
                    seq.append(sous_seq)
        assert len(seq) > 0
        assert len(prunedseq) > 0

        ############
        # Align File:
        # Allow to delete site full of gap
        next_align = np.array(seq)  # Create a matrix for the new alignment without pruned leaves
        gap_only = []
        it = 0
        for i in range(0, next_align.shape[1]):  # Column
            for k in range(0, next_align.shape[0]):  # lines
                if next_align[k, i] == "-":  # Check if the column site is full of gap (90% or more).
                    it = it + 1
            if it >= (0.9 * next_align.shape[0]):
                gap_only.append(True)
                it = 0
            else:
                gap_only.append(False)
        next_align = next_align.compress(np.logical_not(gap_only), axis=1)
        seq = next_align.tolist()
        for i in range(len(seq)):
            seq[i] = ("".join(seq[i]))
        dictionary = {"Node": name, "Seq": seq}
        file = open(os.path.join(workdir, "A", str(int(pruned)) + ".align"), "w")
        for i in range(len(dictionary["Node"])):
            file.write(">" + dictionary["Node"][i] + "\n" + dictionary["Seq"][i] + "\n")


        # GENOME FILE :
        for i in range(len(prunedseq)):
            prunedseq[i] = ("".join(prunedseq[i]))
        # Create a fasta file with pruned sequences
        dictionary = {"Node": prunedname, "Seq": prunedseq}
        file = open(os.path.join(workdir, "G", str(int(pruned)) + ".fasta"), "w")
        for i in range(len(dictionary["Node"])):
            file.write(">" + dictionary["Node"][i] + "\n" + dictionary["Seq"][i] + "\n")

        ### CREAT REQUEST :
        file2 = open(os.path.join(workdir, "R", str(int(pruned)) + "_r150.fasta"), "w")
        for i in range(len(dictionary["Node"])):
            file2.write(">" + dictionary["Node"][i] + "\n" + dictionary["Seq"][i] + "\n")

    # Create csv file to save Distance and Difficulty
    dataframe = pd.DataFrame(dictBD)
    dataframe.to_csv(os.path.join(workdir, 'BrancheDistance.csv'), index=False)

    dataframe2 = pd.DataFrame(dictND)
    dataframe2.to_csv(os.path.join(workdir, 'NodeDistance.csv'), index=False)

    dataframe3 = pd.DataFrame(Diff)
    dataframe3.to_csv(os.path.join(workdir, 'Difficulty.csv'), index=False)

    return 0


def multipruning(workdir :str, tree : List , nodeprune : List):
    """
    Create newick files in which pruned branched have been remote of reference tree.
    :param workdir:
    :param tree:
    :param nodeprune:
    :return: 0
    """
    it = 0
    for pruned in range(len(nodeprune)):  # For all pruned nodes
        treecopy = tree.copy(method="deepcopy")  # copy object before modified
        NP = treecopy.search_nodes(nodeId=nodeprune[pruned].nodeId)[0]
        NP.detach()  # pruning
        treecopy.write(format=1, outfile=os.path.join(workdir,"T", str(it) + ".tree"))  # write pruning tree
        it = it + 1
    return 0


def pruning_operations(config: Dict):
    """
    Operation do during the snakemake rule PRUNING
    :param config: snakemake config
    :return:
    """

    # Check if directory already create
    G_dir = os.path.join(config["workdir"], "G")
    A_dir = os.path.join(config["workdir"], "A")
    T_dir = os.path.join(config["workdir"], "T")
    R_dir = os.path.join(config["workdir"], "R")
    DIST_dir = os.path.join(config["workdir"], "DISTANCE")
    DIF_dir = os.path.join(config["workdir"], "DIFFICULTY")
    if not os.path.exists(G_dir):
        os.mkdir(G_dir)
    if not os.path.exists(A_dir):
        os.mkdir(A_dir)
    if not os.path.exists(T_dir):
        os.mkdir(T_dir)
    if not os.path.exists(R_dir):
        os.mkdir(R_dir)
    if not os.path.exists(DIST_dir):
        os.mkdir(DIST_dir)
    if not os.path.exists(DIF_dir):
        os.mkdir(DIF_dir)

    #Use functions previously created
    id_and_labels_features(config["config_general"].traverse)
    random.seed(config["seed"])

    res = distance_and_align(config["workdir"], config["config_general"].tree,config["config_general"].nodeprune,
                             config["config_general"].traverse, config["dataset_align"])
    assert res == 0
    multipruning(config["workdir"], config["config_general"].tree, config["config_general"].nodeprune)