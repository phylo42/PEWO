#!/usr/bin/env python3


__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import json
import sys
from copy import deepcopy
from Bio import Phylo
from typing import Tuple


def get_best_placement(jplace_filename: str) -> Tuple[int, str]:
    """
    Reads .jplace file of one sequence placement,
    returns the name of the placed sequence and the best placement node id
    """
    with open(jplace_filename) as jplace_file:
        content = json.load(jplace_file)

        # check if .jplace has at least one placement
        assert "placements" in content
        placements = content["placements"]

        assert len(placements) > 0
        place_dict = placements[0]

        # get the best placement
        assert "p" in place_dict
        assert len(place_dict["p"]) > 0

        best_placement = place_dict["p"][0]

        # check if the placement is well-formed
        assert len(best_placement) == 5
        best_branch = best_placement[0]

        # get query name
        assert ("nm" in place_dict or "n" in place_dict)
        if "nm" in place_dict:
            seq_name = place_dict["nm"][0][0]
        elif "n" in place_dict:
            seq_name = place_dict["n"][0]
        else:
            raise RuntimeError("An error occured while parsing " + jplace_filename)

        print(seq_name)

        return best_branch, seq_name


def get_node_by_id(tree: Phylo.BaseTree, postorder_node_id: int) -> Phylo.BaseTree.Clade:
    """
    Finds a tree node by its post-order DFS id.
    These IDs are used in .jplace formatted files.
    """
    postorder_id = 0
    for node in tree.find_elements(order='postorder'):
        if postorder_id == postorder_node_id:
            return node
        postorder_id += 1
    raise RuntimeError(postorder_node_id + " not found.")


def extend_tree(tree: Phylo.BaseTree, branch_id: int, node_name: str) -> None:
    """
    Extends a tree by adding a placed sequence.
    Changes the input tree
    """
    # The node under the branch where the sequence must be placed
    x = get_node_by_id(tree, branch_id)

    # the half of the old branch leading to the old sub tree
    y = Phylo.BaseTree.Clade(x.branch_length / 2, x.name)
    y.clades = deepcopy(x.clades)

    # the half of the old branch leading to the placed sequence
    z = Phylo.BaseTree.Clade(x.branch_length / 2, node_name)

    # modify the original node
    x.branch_length /= 2
    x.clades = [y, z]
    x.name = ''


def make_extended_tree(input_file: str, output_file: str, jplace_file: str) -> None:
    # get the placed sequence id and the best branch post-order id
    branch_id, seq_name = get_best_placement(jplace_file)

    # read the tree
    tree = Phylo.read(input_file, "newick")

    # extend the tree with the placed sequence
    extend_tree(tree, branch_id, seq_name)

    # output the modified tree
    Phylo.write(tree, output_file, "newick")


if __name__ == "__main__":
    assert len(sys.argv) == 4

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    jplace_file = sys.argv[3]
    make_extended_tree(input_file, output_file, jplace_file)
