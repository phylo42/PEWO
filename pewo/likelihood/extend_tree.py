#!/usr/bin/env python3


__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import json
import sys
from copy import deepcopy
from Bio import Phylo
from typing import Dict, List, Union


Number = Union[int, float]


class PlacementRecord:
    """
    A container for a placement record, e.g.
    Example: [1, -0.1, 0.9, 0.1, 0.0]
    """
    def __init__(self, values: List[Number], fields: List[str]) -> None:
        self._values = values
        self._fields = fields

    def __getattr__(self, item: str):
        """
        'fields' indicated which fields are reported in the .jplace,
        so the list of values can be ordered differently. This method returns
        a value from the list of values by its name.
        Examples of : "edge_num"
        """
        if item not in self._fields:
            raise RuntimeError(f"Wrong field: {item}. "
                               f"Fields listed in the file: {self._fields}")

        return self._values[self._fields.index(item)]


class PlacedSeq:
    """
    A container for a placed sequence.
    """
    def __init__(self,
                 # can be one placement (list) or list of placements
                 placements: Union[PlacementRecord, List[PlacementRecord]],
                 # can be a list with one name or a list of lists with name multiplicity
                 names: Union[List[str], List[List[Union[str, int]]]]) -> None:
        self._placements = placements
        self._names = names

    @staticmethod
    def from_dict(placement_dict: Dict, fields: List[str]) -> "PlacedSeq":
        """
        Creates a PlacedSeq from a placement dictionary.
        Example:
            {
                "p": [...]
                "n": [...]
            }
        """
        placements = [PlacementRecord(p, fields) for p in placement_dict["p"]]

        # Sequence name can be in the field "n" or "nm"
        names_key = "n" if "n" in placement_dict else "nm"
        assert names_key in placement_dict
        names = placement_dict[names_key]

        return PlacedSeq(placements, names)

    @property
    def placements(self):
        return self._placements

    @property
    def names(self):
        return self._names

    @property
    def sequence_name(self):
        # if "name multiplicity"
        if type(self._names[0]) == list:
            return self._names[0][0]
        # if just a name
        else:
            return self._names[0]


class JplaceParser:
    """
    Parses .jplace file, creating a DOM-like data structure using
    PlacedSeq and PlacementRecord.
    """
    def __init__(self, input_file: str) -> None:
        self._input_file = input_file
        self._placements = []

    def parse(self) -> None:
        """
        Parser the input file, creating a list of PlacedSeq in self._placements.
        WARNING: It parser only "edge_num" and "likelihood" fields.
        """

        self._placements = []
        with open(self._input_file) as jplace_file:
            content = json.load(jplace_file)

            # .jplace file has to have "fields" that determines the order of
            # output fields for each placement. Make sure it is there
            assert "fields" in content, f'{self._input_file} must contain "fields"'
            fields = content["fields"]

            # Make sure the most important two fields are present
            required_fields = ["edge_num", "likelihood"]
            assert all(field in fields for field in required_fields), "Error while parsing " \
                f"{self._input_file}: fields must declare {required_fields}"

            # check if .jplace has at least one placement
            assert "placements" in content,  "Error while parsing " \
                f'{self.input_file}: input file must have the "placements" section.'

            for placement_dict in content["placements"]:
                placed_seq = PlacedSeq.from_dict(placement_dict, fields)
                self._placements.append(placed_seq)

    @property
    def placements(self) -> List[PlacedSeq]:
        return self._placements


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
    raise RuntimeError(str(postorder_node_id) + " not found.")


def extend_tree(tree: Phylo.BaseTree, placement: PlacementRecord, node_name: str) -> None:
    """
    Extends a tree by adding a placed sequence.
    Changes the input tree
    """
    # The node under the branch where the sequence must be placed
    x = get_node_by_id(tree, placement.edge_num)

    # the half of the old branch leading to the old sub tree
    y = Phylo.BaseTree.Clade(x.branch_length - placement.distal_length, x.name)
    y.clades = deepcopy(x.clades)

    # the half of the old branch leading to the placed sequence
    z = Phylo.BaseTree.Clade(placement.pendant_length, node_name)

    # modify the original node
    x.branch_length = placement.distal_length
    x.clades = [y, z]
    x.name = ''


def make_extended_tree(input_file: str, output_file: str, jplace_file: str) -> None:
    try:
        # parse the .jplace file
        parser = JplaceParser(jplace_file)
        parser.parse()

        # we assume there was only one sequence placed.
        placement = parser.placements[0]
        # get the best placement reported
        best_record = placement.placements[0]

        # get the placed sequence id
        seq_name = placement.sequence_name

        # read the tree
        tree = Phylo.read(input_file, "newick")

        # extend the tree with the placed sequence
        extend_tree(tree, best_record, seq_name)

        # output the modified tree
        Phylo.write(tree, output_file, "newick")

    except json.JSONDecodeError as e:
        print("Error: Invalid JSON file ", jplace_file)
        print(e.msg)


if __name__ == "__main__":
    assert len(sys.argv) == 4

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    jplace_file = sys.argv[3]
    make_extended_tree(input_file, output_file, jplace_file)
