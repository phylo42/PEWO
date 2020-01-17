"""
This is a config helper module. It contains helper functions
to retrieve values from the config files.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


from typing import Union, Any
from pewo.software import PlacementSoftware


def is_supported(software: Union[PlacementSoftware, Any]) -> bool:
    """
    Checks if software is supported. Takes anything as input, returns True
    if the input parameter is PlacementSoftware.
    """
    return type(software) == PlacementSoftware


def prunings_enabled(config) -> bool:
    """
    Checks if prunings are enabled in the config file.
    """
    return "enable_prunings" in config and config["enable_prunings"] == True

