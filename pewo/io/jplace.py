import json
import os
from typing import Dict, List


class Placement:
    """
    simple representation of a unique placement
    """

    def __init__(self, nodeId=-1, weight_ratio=0.0):
        self._node_id = nodeId
        self._weight_ratio = weight_ratio

    def get_node_id(self):
        return self._node_id

    def get_weight_ratio(self):
        return self._weight_ratio

    def set_node_id(self, node_id: int):
        self._node_id = node_id

    def set_weight_ratio(self, weight_ratio: float):
        self._weight_ratio = weight_ratio

    # TODO make sure all object comparison methods are set

    def __ge__(self, other):
        return self._weight_ratio > other.get_weight_ratio()

    def __lt__(self, other):
        return self._weight_ratio < other.get_weight_ratio()

    def __cmp__(self, other):
        return self._weight_ratio > other.get_weight_ratio()


class JPlaceLoader:

    def __init__(self, jplace_file: str, reverseEPANGUnrooting: bool):
        # TODO load tree as ete3 object
        self._tree_string = ""
        self._placements: Dict[str, List[Placement]] = dict()
        if os.path.exists(jplace_file) and os.path.isfile(jplace_file):
            self._load_jplace(jplace_file)
        else:
            raise Exception("Cannot read " + jplace_file)

    def _load_jplace(self, jplace_file: str, reverseEPANGUnrooting: bool):
        # TODO JSON parsing to fill _placements
        with open(jplace_file, 'r') as f:
            data = json.load(f)
            self._tree_string = data["tree"]
            # if this is from a EPANG output, a rooted input will be unrooted as
            # ((A,B),C)root; --> (C,B,A);
            # so to get same postorder node_id enumeration, need to reorder string elements, then reroot the tree
            if reverseEPANGUnrooting:
                print("Reversing EPA-ng unrooting...")
                # first change newick string to get root sons
                # order from (C3,C2,C1); to (C1,C2,C3);

                # 1st, define root
                clade_closing_index = -1
                for i in range(len(self._tree_string) - 1, -1):
                    if self._tree_string[i] == ')':
                        clade_closing_index = i
                        break
                # 2nd, extract C1 to C3
                clades = [4]  # 4th element contains the root node
                depth = 0
                clade_start = 1
                clade_counter = 0
                for i in range(0, len(self._tree_string)):
                    c = self._tree_string[i]
                    if c == '(':
                        depth += 1
                    if c == ')':
                        depth -= 1
                    if ((depth == 1) and (c == ',')) or ((depth == 0) and (i == clade_closing_index)):
                        if i > 0:
                            clades[clade_counter] = self._tree_string[clade_start:i]
                            clade_counter += 1
                        clade_start = i + 1
                        continue
                # last one = the root
                clades[clade_counter] = self._tree_string[clade_start:len(self._tree_string)]
                # reorder
                self._tree_string = "(" + clades[2] + "," + clades[1] + "," + clades[0] + ")" + clades[3]
                # self._tree =  ete3.parse(self._tree_string)  # TODO ete3 parsing

    def get_placements(self) -> Dict[str, List]:
        return self._placements

    def get_tree(self):
        return None
        # TODO return ete3 tree

    def get_tree_string(self):
        return self._tree_string
