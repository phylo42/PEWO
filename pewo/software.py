"""
This module contains definitions of data structures for software supported in PEWO.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


from enum import Enum
from typing import Union, Dict


class PlacementSoftware(Enum):
    EPA = "epa"
    EPANG = "epang"
    PPLACER = "pplacer"
    APPLES = "apples"
    RAPPAS = "rappas"
    RAPPAS2 = "rappas2"
    APPSPAM = "appspam"

    @staticmethod
    def get_by_value(value):
        """
        Returns Enum value by string key.
        """
        return PlacementSoftware._value2member_map_[value]


class AlignmentSoftware(Enum):
    HMMER = "hmmer"


class CustomScripts(Enum):
    PSIBLAST_2_FASTA = "psiblast2fasta"


Software = Union[PlacementSoftware, AlignmentSoftware, CustomScripts]


def get_ar_binary(config: Dict, arsoft: str) -> str:
    """
    Selects correct ancestral reconstruction binary depending on the value set in the config.
    """
    # FIXME: Make a software class for every AR software
    if arsoft == "PHYML":
        return "phyml"
    elif arsoft == "RAXMLNG":
        return "raxml-ng"
    elif (arsoft == "PAML") and (config["states"]==0):
        return "baseml"
    elif (arsoft == "PAML") and (config["states"]==1):
        return "codeml"
