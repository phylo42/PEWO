"""
This module contains functions that generate snakemake templates
for output files.
"""


__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
from typing import Union, Any, Dict, List
from pewo.software import PlacementSoftware
from pewo.config import is_supported, prunings_enabled
from pewo.io import fasta


def _check_software(software: Union[PlacementSoftware, Any]) -> None:
    """
    Assert wrapper for _is_supported().
    """
    assert is_supported(software), str(software) + " is not valid placement software."


def get_template_wildcards(template: str) -> List[str]:
    """
    Returns the list of wildcards in the input template.
    """
    pass


def get_base_outputdir_template(config: Dict, software: PlacementSoftware) -> str:
    """
    Creates a name template for the main output directory of given software.
    This directory is used to store .jplace output and other files.
    """
    _check_software(software)

    if software == PlacementSoftware.EPA:
        return os.path.join(config["workdir"], "EPA", "{pruning}", "g{gepa}")
    elif software == PlacementSoftware.EPA_NG:
        raise NotImplementedError()
    elif software == PlacementSoftware.PPLACER:
        raise NotImplementedError()
    elif software == PlacementSoftware.APPLES:
        raise NotImplementedError()
    elif software == PlacementSoftware.RAPPAS:
        return os.path.join(config["workdir"], "RAPPAS", "{pruning}", "red{reduction}_ar{arsoft}", "k{k}_o{omega}")
    elif software == PlacementSoftware.RAPPAS2:
        raise NotImplementedError()


def get_log_outputdir_template(config: Dict, software: PlacementSoftware) -> str:
    """
    Creates an output directory name template for .log files depends on software used.
    """
    _check_software(software)
    return os.path.join(config["workdir"], "logs", "placement_" + software.value, "{pruning}")


def get_common_queryname_template(config: Dict) -> str:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates an placement output filename template, based on the
    first type of inputs, and is independent of placement software used.
    """

    # For generated queries take the pruning and read length as an output template name.
    # For user queries take query file name as a template
    return "{pruning}_r{length}" if prunings_enabled(config) else "{query}"


def get_common_template_args(config: Dict) -> Dict[str, Any]:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates a dict of common template arguments that can be passed to
    'expand' function of snakemake to resolve the common query name template given
    by get_common_queryname_template().
    """

    if prunings_enabled(config):
        return {"prunings": range(config["pruning_count"]),
                "length": config["read_length"]}
    else:
        query_ids = fasta.get_sequence_ids(config["dataset_reads"])
        return {"query": query_ids}


def get_full_queryname_template(config: Dict, software: PlacementSoftware) -> str:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates a full placement output filename template, based on the
    both types of inputs. Thus it extends the name given by
    get_common_queryname_template(), specifying it by the software given.
    It is used to produce .jplace files, .log files etc.s
    """
    _check_software(software)

    if software == PlacementSoftware.EPA:
        return get_common_queryname_template(config,) + "_g{gepa}"
    elif software == PlacementSoftware.EPA_NG:
        raise NotImplementedError()
    elif software == PlacementSoftware.PPLACER:
        raise NotImplementedError()
    elif software == PlacementSoftware.APPLES:
        raise NotImplementedError()
    elif software == PlacementSoftware.RAPPAS:
        return get_common_queryname_template(config) + "_k{k}_o{omega}_red{reduction}_ar{arsoft}"
    elif software == PlacementSoftware.RAPPAS2:
        raise NotImplementedError()


def get_output_template_args(config: Dict, software: PlacementSoftware) -> Dict[str, Any]:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates a dict of specified template arguments that depends on the
    software given. These arguments can be passed to 'expand' function of snakemake
    to resolve the full query name template given by get_full_queryname_template().
    """
    _check_software(software)

    # get common template arguments
    template_args = get_common_template_args(config)

    # specify template arguments based on software
    if software == PlacementSoftware.EPA:
        template_args["gepa"] = config["config_epa"]["G"]
    elif software == PlacementSoftware.EPA_NG:
        raise NotImplementedError()
    elif software == PlacementSoftware.PPLACER:
        raise NotImplementedError()
    elif software == PlacementSoftware.APPLES:
        raise NotImplementedError()
    elif software == PlacementSoftware.RAPPAS:
        template_args.update(config["config_rappas"])
    elif software == PlacementSoftware.RAPPAS2:
        raise NotImplementedError()
    else:
        raise RuntimeError("Unsupported software: " + software.value)

    # a general rule for all software
    if not prunings_enabled(config):
        template_args["pruning"] = ["full"]

    return template_args


def get_jplace_filename_template(config: Dict, software: PlacementSoftware) -> str:
    """
    Creates a .jplace filename template based on software used.
    """
    _check_software(software)

    # get the sofware name in lower case from Enum value
    software_name = software.value

    # {full_template}_{software}.jplace
    return get_full_queryname_template(config, software) + "_" + software_name + ".jplace"


def get_output_filename_template(config: Dict, software: PlacementSoftware, extension: str) -> str:
    """
    Creates a .{extension} filename template based on software used.
    """
    assert len(extension) > 0
    extension = "." + extension if extension[0] != "." else extension
    return get_full_queryname_template(config, software) + extension


def get_jplace_output_template(config: Dict, software: PlacementSoftware) -> str:
    """
    Creates a name template of .jplace output files produced by specific software.
    """
    return os.path.join(get_base_outputdir_template(config, software),
                        get_jplace_filename_template(config, software))


def get_log_output_template(config: Dict, software: PlacementSoftware) -> str:
    """
    Creates a name template of .log output files produced by specific software.
    """
    return os.path.join(get_log_outputdir_template(config, software),
                        get_output_filename_template(config, software, "log"))


def get_output_template(config: Dict, software: PlacementSoftware, extension: str) -> str:
    """
    Creates a name template of .{extension} output files produced by specific software.
    Used to produce .tree, .align etc. file name templates. Stored in the output
    directory of given software.
    """
    return os.path.join(get_base_outputdir_template(config, software),
                        get_output_filename_template(config, software, extension))
