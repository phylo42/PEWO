"""
This module contains definitions of data structures for software supported in PEWO.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


from enum import Enum
from typing import Union


class PlacementSoftware(Enum):
    EPA = "epa"
    EPA_NG = "epang"
    PPLACER = "pplacer"
    APPLES = "apples"
    RAPPAS = "rappas"
    RAPPAS2 = "rappas2"

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
