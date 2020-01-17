"""
This module contains the definition of a data structure
for placement software supported in PEWO.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


from enum import Enum


class PlacementSoftware(Enum):
    EPA = "epa"
    EPA_NG = "epang"
    PPLACER = "pplacer"
    APPLES = "apples"
    RAPPAS = "rappas"
    RAPPAS2 = "rappas2"
