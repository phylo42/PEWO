"""
This module contains functions that generate snakemake templates for output files and directories.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
from typing import Union, Any, Dict
import pewo.config as cfg
from pewo.software import Software, PlacementSoftware, AlignmentSoftware
from pewo.io import fasta


def _check_software(software: Any) -> None:
    """
    Assert wrapper for _is_supported().
    """
    assert cfg.is_supported(software), str(software) + " is not valid placement software."


def get_software_dir(config: Dict,
                     software: Union[PlacementSoftware, AlignmentSoftware]) -> str:
    """
    Returns a working directory for given software.
    """
    _check_software(software)

    work_dir = cfg.get_work_dir(config)
    return os.path.join(work_dir, software.value.upper())


def get_experiment_dir_template(config: Dict, software: PlacementSoftware) -> str:
    """
    Returns a name template of a working directory path for an experiment.
    One experiment is conducted by given software with fixed specific
    software parameters and a fixed input set (i.e. phylogenetic tree and alignment).
    """
    _check_software(software)

    software_dir = get_software_dir(config, software)

    # A subdirectory template for the given input set
    input_set_dir_template = "{pruning}"

    if software == PlacementSoftware.EPA:
        return os.path.join(software_dir, input_set_dir_template, "g{gepa}")
    elif software == PlacementSoftware.EPA_NG:
        raise NotImplementedError()
    elif software == PlacementSoftware.PPLACER:
        return os.path.join(software_dir, input_set_dir_template, "ms{msppl}_sb{sbppl}_mp{mpppl}")
    elif software == PlacementSoftware.APPLES:
        raise NotImplementedError()
    elif software == PlacementSoftware.RAPPAS:
        return os.path.join(software_dir, input_set_dir_template, "red{reduction}_ar{arsoft}", "k{k}_o{omega}")
    elif software == PlacementSoftware.RAPPAS2:
        raise NotImplementedError()


def get_experiment_log_dir_template(config: Dict, software: Software) -> str:
    """
    Returns a name template of a log directory path for an experiment.
    One experiment is conducted by given software with fixed specific
    software parameters and a fixed input set (i.e. phylogenetic tree and alignment).

    Software can be a value of a type from pewo.software, or a string
    for scripts (e.g. psiblast2fasta.py).
    """
    _check_software(software)
    software_name = software.value
    return os.path.join(cfg.get_work_dir(config), "logs", software_name, "{pruning}")


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
    return "{pruning}_r{length}" if cfg.generate_reads(config) else "{query}_r{length}"


def get_common_template_args(config: Dict) -> Dict[str, Any]:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates a dict of common template arguments that can be passed to
    'expand' function of snakemake to resolve the common query name template given
    by get_common_queryname_template().
    """

    if cfg.generate_reads(config):
        return {
            "pruning": range(config["pruning_count"]),
            "length": config["read_length"]
        }
    else:
        return {
            "pruning": ["0"],
            "length": ["0"],
            "query": fasta.get_sequence_ids(config["dataset_reads"])
        }


def get_queryname_template(config: Dict, software: PlacementSoftware) -> str:
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
        return get_common_queryname_template(config) + "_g{gepa}"
    elif software == PlacementSoftware.EPA_NG:
        raise NotImplementedError()
    elif software == PlacementSoftware.PPLACER:
        return get_common_queryname_template(config) + "_ms{msppl}_sb{sbppl}_mp{mpppl}"
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
    to resolve the full query name template given by get_queryname_template().
    """
    _check_software(software)

    # get common template arguments
    template_args = get_common_template_args(config)

    template_args["software"] = software.value

    # specify template arguments based on software
    if software == PlacementSoftware.EPA:
        template_args["gepa"] = config["config_epa"]["G"]
    elif software == PlacementSoftware.EPA_NG:
        raise NotImplementedError()
    elif software == PlacementSoftware.PPLACER:
        template_args["msppl"] = config["config_pplacer"]["max-strikes"]
        template_args["sbppl"] = config["config_pplacer"]["strike-box"]
        template_args["mpppl"] = config["config_pplacer"]["max-pitches"]
    elif software == PlacementSoftware.APPLES:
        raise NotImplementedError()
    elif software == PlacementSoftware.RAPPAS:
        template_args.update(config["config_rappas"])
    elif software == PlacementSoftware.RAPPAS2:
        raise NotImplementedError()
    else:
        raise RuntimeError("Unsupported software: " + software.value)
    return template_args


def get_output_filename_template(config: Dict, software: PlacementSoftware, extension: str) -> str:
    """
    Creates a .{extension} filename template based on software used.
    """
    assert len(extension) > 0
    _check_software(software)

    extension = "." + extension if extension[0] != "." else extension
    return get_queryname_template(config, software) + "_" + software.value + extension


def get_log_template(config: Dict, software: Software) -> str:
    """
    Creates a name template of .log output files produced by specific software.
    """
    return os.path.join(get_experiment_log_dir_template(config, software),
                        get_output_filename_template(config, software, "log"))


def get_output_template(config: Dict, software: Union[PlacementSoftware, AlignmentSoftware], extension: str) -> str:
    """
    Creates a name template of .{extension} output files produced by specific software.
    Used to produce .tree, .align etc. file name templates. Stored in the output
    directory of given software.
    """
    _check_software(software)
    return os.path.join(get_experiment_dir_template(config, software),
                        get_output_filename_template(config, software, extension))
