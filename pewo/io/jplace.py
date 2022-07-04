import json
import os
from typing import Dict, List

from ete3 import Tree


class Placement:
    """
    simple representation of a unique placement
    """

    def __init__(self, nodeId=-1, weight_ratio=1.0, pendant_length=0.0, distal_length=0.0, probability=1.0):
        self._node_id = nodeId
        self._weight_ratio = weight_ratio
        self._pendant_length = pendant_length
        self._distal_length = distal_length
        self._probability = probability

    def get_node_id(self):
        return self._node_id

    def get_weight_ratio(self):
        return self._weight_ratio

    def set_node_id(self, node_id: int):
        self._node_id = node_id

    def set_weight_ratio(self, weight_ratio: float):
        self._weight_ratio = weight_ratio

    # called as soon as __lt__(), __gt()__ , etc ... are not implemented
    # x.__cmp__(y) must return -1 if x<y, 0 if equal, 1 if x>y
    def __cmp__(self, other):
        if self._weight_ratio == other.get_weight_ratio():
            return 0
        elif self._weight_ratio < other.get_weight_ratio():
            return -1
        else:
            return 1

    def __repr__(self):
        return f'Placement(nodeid:"{self._node_id}",lwr"{self._weight_ratio})'


class JPlaceParser:
    """
    loads a jplace and index its content as Placement objects
    """

    def __init__(self, jplace_file: str, reverseEPANGUnrooting: bool):
        # class var
        self._reverseEPANGUnrooting = reverseEPANGUnrooting
        self._tree_newick_string = ""
        self._tree: Tree = None
        self._placements: Dict[str, List[Placement]] = dict()
        # used for parsing
        self._edge_id_idx = -1
        self._weight_ratio_idx = -1
        # load
        if os.path.exists(jplace_file) and os.path.isfile(jplace_file):
            self._load_jplace(jplace_file)
        else:
            raise Exception("Cannot read " + jplace_file)

    def _load_jplace(self, jplace_file: str):

        with open(jplace_file, 'r') as f:
            data = json.load(f)
            self._tree_newick_string = data["tree"]
            print(self._tree_newick_string)

            # if this is from a EPANG output, a rooted input will be unrooted as
            # ((A,B),C)root; --> (C,B,A);
            # to get same postorder node_id enumeration, need to reorder string elements, then reroot the tree
            if self._reverseEPANGUnrooting:
                print("Reversing EPA-ng unrooting...")
                # first change newick string to get root sons
                # order from (C3,C2,C1); to (C1,C2,C3);

                # 1st, define root
                clade_closing_index = -1
                for i, v in enumerate(self._tree_newick_string[::-1]):
                    print(i, v)
                    if v == ')':
                        clade_closing_index = len(self._tree_newick_string)-i-1
                        break
                print(clade_closing_index)
                # 2nd, extract C1 to C3
                clades = []  # 4th element contains the root node data, if any
                depth = 0
                clade_start = 1
                for i in range(0, len(self._tree_newick_string)):
                    c = self._tree_newick_string[i]
                    if c == '(':
                        depth += 1
                    if c == ')':
                        depth -= 1
                    if ((depth == 1) and (c == ',')) or ((depth == 0) and (i == clade_closing_index)):
                        if i > 0:
                            print(clade_start, i)
                            print(self._tree_newick_string[clade_start:i])
                            clades.append(self._tree_newick_string[clade_start:i])
                            print(clades)
                        clade_start = i + 1
                        continue
                # last one = the root
                print(clades)
                clades.append(self._tree_newick_string[clade_start:len(self._tree_newick_string)])
                # reorder as (C1,C2,C3)
                self._tree_newick_string = "(" + clades[2] + "," + clades[1] + "," + clades[0] + ")" + clades[3]
                print(self._tree_newick_string)

            # load tree via ete3
            self._tree = Tree(self._tree_newick_string, format=1)
            # if was unrooted by EPANG, reroot as ((C1,C2),C3)
            if self._reverseEPANGUnrooting:
                self._tree.set_outgroup(self._tree.get_children()[2])

            # TODO JSON parsing to fill _placements
            # determine edge_id column
            fields = data["fields"]
            for i, fi in enumerate(fields):
                if fi == "edge_num":
                    self._edge_id_idx = i
                if fi == "like_weight_ratio":
                    self._weight_ratio_idx = i
            # load placements themselves
            placements = data["placements"]

    def get_placements(self) -> Dict[str, List]:
        return self._placements

    def get_tree(self) -> Tree:
        return self._tree

    def get_tree_string(self):
        return self._tree_newick_string
