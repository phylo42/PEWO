"""
A module to work with .jplace-formatted files.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import json
from typing import Tuple


def get_best_placement(jplace_filename: str) -> Tuple[int, str]:
    """
    Reads .jplace file of one sequence placement,
    returns the name of the placed sequence and the best placement node id
    """
    with open(jplace_filename) as jplace_file:
        content = json.load(jplace_file)

        # check if .jplace has one placement
        assert "placements" in content
        placements = content["placements"]

        assert len(placements) == 1
        place_dict = placements[0]

        # get the best placement
        assert "p" in place_dict
        assert len(place_dict["p"]) > 0

        best_placement = place_dict["p"][0]

        # check if the placement is well-formed and return it
        assert len(best_placement) == 5
        best_branch = best_placement[0]

        # get query name
        assert "nm" in place_dict
        assert len(place_dict["nm"]) > 0

        nm = place_dict["nm"][0]
        assert len(nm) > 0
        seq_name = nm[0]

        return best_branch, seq_name