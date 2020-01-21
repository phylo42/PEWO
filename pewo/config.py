"""
This is a config helper module. It contains helper functions
to retrieve values from the config files.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


from typing import Any, Dict
from pewo.software import PlacementSoftware, AlignmentSoftware, CustomScripts


def get_work_dir(config: Dict) -> str:
    """
    Returns working directory path. This is the root directory of PEWO output.
    """
    return config["workdir"]


def is_supported(software: Any) -> bool:
    """
    Checks if software is supported. Takes anything as input, returns True
    if the input parameter is PlacementSoftware, AlignmentSoftware or
    a custom script name.
    """
    return type(software) == PlacementSoftware or \
           type(software) == AlignmentSoftware or \
           type(software) == CustomScripts


def software_tested(config: Dict, software: PlacementSoftware) -> bool:
    """
    Checks if given software is being tested.
    """
    return software.value in config["test_soft"]


def generate_reads(config: Dict) -> bool:
    """
    Returns if PEWO should generate reads from the input tree.
    """
    return "generate_reads" in config and config["generate_reads"]
