"""
This module contains functions that generate snakemake templates for output files and directories.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
from typing import Union, Any, Dict, List
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


def get_experiment_dir_template(config: Dict, software: PlacementSoftware, **kwargs) -> str:
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
        return os.path.join(software_dir, input_set_dir_template, "g{g}")
    elif software == PlacementSoftware.EPANG:
        # Output template depends on the heuristic enabled.
        # Get the heuristic
        heuristic = kwargs.get("heuristic", None)
        valid_heuristics = ("h1", "h2", "h3", "h4")
        assert heuristic and heuristic in valid_heuristics, f"{heuristic} is not a valid heuristic."

        if heuristic == "h1":
            return os.path.join(software_dir, input_set_dir_template, "h1", "g{g}",
                                get_common_queryname_template(config))
        elif heuristic == "h2":
            return os.path.join(software_dir, input_set_dir_template, "h2", "bigg{bigg}",
                                get_common_queryname_template(config))
        elif heuristic in ("h3", "h4"):
            return os.path.join(software_dir, input_set_dir_template, heuristic,
                                get_common_queryname_template(config))
    elif software == PlacementSoftware.PPLACER:
        return os.path.join(software_dir, input_set_dir_template, "ms{ms}_sb{sb}_mp{mp}")
    elif software == PlacementSoftware.APPLES:
        return os.path.join(software_dir, input_set_dir_template, "meth{meth}_crit{crit}")
    elif software == PlacementSoftware.RAPPAS:
        return os.path.join(software_dir, input_set_dir_template, "red{red}_ar{ar}", "k{k}_o{o}")
    elif software == PlacementSoftware.APPSPAM:
        return os.path.join(software_dir, input_set_dir_template, "mode{mode}_w{w}")


def get_experiment_log_dir_template(config: Dict, software: Software) -> str:
    """
    Returns a name template of a log directory path for an experiment.
    One experiment is conducted by given software with fixed specific
    software parameters and a fixed input set (i.e. phylogenetic tree and alignment).
    """
    _check_software(software)
    software_name = software.value
    return os.path.join(cfg.get_work_dir(config), "logs", software_name, "{pruning}")


def get_name_prefix(config: Dict) -> str:
    return "query" if cfg.get_mode(config) == cfg.Mode.LIKELIHOOD else "pruning"


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
    return "{" + get_name_prefix(config) + "}_r{length}"


def get_common_template_args(config: Dict) -> Dict[str, Any]:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates a dict of common template arguments that can be passed to
    'expand' function of snakemake to resolve the common query name template given
    by get_common_queryname_template().
    """

    if cfg.get_mode(config) == cfg.Mode.LIKELIHOOD:
        return {
            "pruning": ["0"],
            "length": ["0"],
            "query": fasta.get_sequence_ids(config["query_user"])
        }
    else:
        return {
            "pruning": range(config["pruning_count"]),
            "length": config["read_length"]
        }


def get_queryname_template(config: Dict, software: PlacementSoftware, **kwargs) -> str:
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
        return get_common_queryname_template(config) + "_g{g}"
    elif software == PlacementSoftware.EPANG:
        # Output template depends on the heuristic enabled.
        # Get the heuristic
        heuristic = kwargs.get("heuristic", None)
        valid_heuristics = ("h1", "h2", "h3", "h4")
        assert heuristic and heuristic in valid_heuristics, f"{heuristic} is not a valid heuristic."

        if heuristic == "h1":
            return get_common_queryname_template(config) + "_h1_g{g}"
        elif heuristic == "h2":
            return get_common_queryname_template(config) + "_h2_bigg{bigg}"
        elif heuristic in ("h3", "h4"):
            return get_common_queryname_template(config) + "_" + heuristic
    elif software == PlacementSoftware.PPLACER:
        return get_common_queryname_template(config) + "_ms{ms}_sb{sb}_mp{mp}"
    elif software == PlacementSoftware.APPLES:
        return get_common_queryname_template(config) + "_meth{meth}_crit{crit}"
    elif software == PlacementSoftware.RAPPAS:
        return get_common_queryname_template(config) + "_k{k}_o{o}_red{red}_ar{ar}"
    elif software == PlacementSoftware.APPSPAM:
        return get_common_queryname_template(config) + "_mode{mode}_w{w}"


def get_output_template_args(config: Dict, software: PlacementSoftware, **kwargs) -> Dict[str, Any]:
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

    # FIXME: These template arguments should be named in the same way as the input config
    # parameters. Change the name convention so that the config dictionary content
    # is actually the output of this function.

    # specify template arguments based on software
    if software == PlacementSoftware.EPA:
        template_args["g"] = config["config_epa"]["G"]
    elif software == PlacementSoftware.EPANG:
        # Output template depends on the heuristic enabled.
        # Get the heuristic
        heuristic = kwargs.get("heuristic", None)
        valid_heuristics = ("h1", "h2", "h3", "h4")
        assert heuristic and heuristic in valid_heuristics, f"{heuristic} is not a valid heuristic."

        if heuristic == "h1":
            template_args["g"] = config["config_epang"]["h1"]["g"]
        elif heuristic == "h2":
            template_args["bigg"] = config["config_epang"]["h2"]["G"]
    elif software == PlacementSoftware.PPLACER:
        template_args["ms"] = config["config_pplacer"]["max-strikes"]
        template_args["sb"] = config["config_pplacer"]["strike-box"]
        template_args["mp"] = config["config_pplacer"]["max-pitches"]
    elif software == PlacementSoftware.APPLES:
        template_args["meth"] = config["config_apples"]["methods"]
        template_args["crit"] = config["config_apples"]["criteria"]
    elif software == PlacementSoftware.RAPPAS:
        template_args["k"] = config["config_rappas"]["k"]
        template_args["o"] = config["config_rappas"]["omega"]
        template_args["red"] = config["config_rappas"]["reduction"]
        template_args["ar"] = config["config_rappas"]["arsoft"]
    elif software == PlacementSoftware.APPSPAM:
        template_args["w"] = config["config_appspam"]["w"]
        template_args["mode"] = config["config_appspam"]["mode"]
    else:
        raise RuntimeError("Unsupported software: " + software.value)
    return template_args


def get_output_filename_template(config: Dict, software: PlacementSoftware,
                                 extension: str, **kwargs) -> str:
    """
    Creates a .{extension} filename template based on software used.
    """
    assert len(extension) > 0
    _check_software(software)

    extension = "." + extension if extension[0] != "." else extension
    return get_queryname_template(config, software, **kwargs) + "_" + software.value + extension


def get_log_template(config: Dict, software: Software, **kwargs) -> str:
    """
    Creates a name template of .log output files produced by specific software.
    """
    return os.path.join(get_experiment_log_dir_template(config, software),
                        get_output_filename_template(config, software, "log", **kwargs))


def join_kwargs(**kwargs) -> str:
    """
    Joins keyword arguments and their values in parenthesis.
    Example: key1{value1}_key2{value2}
    """
    return "_".join(key + "{" + value + "}" for key, value in kwargs.items())


def get_benchmark_template(config: Dict, software: Software, **kwargs) -> str:
    """
    Creates a name template of .tsv output files produced by specific software.
    """
    rule_name = kwargs.get("rule_name", "rule_name keyword argument must be provided")
    assert rule_name

    template_args = kwargs.copy()
    template_args.pop("rule_name")

    heuristic = kwargs.get("heuristic", None)
    if heuristic:
        template_args.pop("heuristic")

    # Skip the first character assuming to keep the name convention as
    # {pruning}_arg1{arg1}_arg2{arg2}, not p{pruning}_arg1{arg1}...
    filename_template = join_kwargs(**template_args)[1:]

    software_name = software.name.lower()
    if software == PlacementSoftware.EPANG:
        valid_heuristics = ("h1", "h2", "h3", "h4")
        assert heuristic and heuristic in valid_heuristics, f"{heuristic} is not a valid heuristic."
        software_name = software.name.lower() + f"-{heuristic}"

    return os.path.join(cfg.get_work_dir(config), "benchmarks",
                        filename_template + "_" + software_name + "-" + rule_name + "_benchmark.tsv")


def get_output_template(config: Dict, software: Union[PlacementSoftware, AlignmentSoftware],
                        extension: str, **kwargs) -> str:
    """
    Creates a name template of .{extension} output files produced by specific software.
    Used to produce .tree, .align etc. file name templates. Stored in the output
    directory of given software.
    """
    _check_software(software)
    return os.path.join(get_experiment_dir_template(config, software, **kwargs),
                        get_output_filename_template(config, software, extension, **kwargs))


def get_ar_output_templates(config: Dict, arsoft: str) -> List[str]:
    """
    Returns a list of resulting files of the ancestral reconstruction stage.
    """

    # FIXME: Make a software class for every AR software, and make output directories
    # for every AR software
    output_dir = os.path.join(cfg.get_work_dir(config), "RAPPAS", "{pruning}", "red{red}_ar" + arsoft.upper(), "AR")

    if arsoft == "PHYML":
        output_filenames = [
            "extended_align.phylip_phyml_ancestral_seq.txt",
            "extended_align.phylip_phyml_ancestral_tree.txt",
            "extended_align.phylip_phyml_stats.txt",
            "extended_align.phylip_phyml_tree.txt"
        ]
    elif arsoft == "RAXMLNG":
        output_filenames = [
            "extended_align.phylip.raxml.log",
            "extended_align.phylip.raxml.ancestralTree",
            "extended_align.phylip.raxml.ancestralProbs",
            "extended_align.phylip.raxml.startTree",
            "extended_align.phylip.raxml.ancestralStates",
            "extended_align.phylip.raxml.rba"
        ]
    elif arsoft == "PAML":
        output_filenames = [
            "rst"
        ]
    else:
        raise RuntimeError(f"Unknown ancestral reconstruction soft: {arsoft}")

    return [os.path.join(output_dir, filename) for filename in output_filenames]
