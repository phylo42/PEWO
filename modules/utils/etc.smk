"""
Diverse utilitarian functions
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"

import os
from Bio import SeqIO
from enum import Enum
from typing import List, Mapping, Any, Union


class PlacementSoftware(Enum):
    EPA = "epa"
    EPA_NG = "epang"
    PPLACER = "pplacer"
    APPLES = "apples"
    RAPPAS = "rappas"
    RAPPAS2 = "rappas2"


def _is_supported(software: Union[PlacementSoftware, Any]) -> bool:
    """
    Checks if software is supported. Takes anything as input, returns True
    if the input parameter is PlacementSoftware.
    """
    return type(software) == PlacementSoftware


def _check_software(software: Union[PlacementSoftware, Any]) -> None:
    """
    Assert wrapper for _is_supported().
    """
    assert _is_supported(software), str(software) + " is not valid placement software."


def get_sequence_ids(input_file: str) -> List[str]:
    """
    Retrieves sequence IDs from the input .fasta file.
    """
    return [record.id for record in SeqIO.parse(input_file, "fasta")]


# get IDs of all queries in the file
query_ids = get_sequence_ids(config["dataset_reads"])


def prunings_enabled() -> bool:
    """
    Checks if prunings are enabled in the config file.
    """
    return "enable_prunings" in config and config["enable_prunings"] == True


def get_jplace_outputdir_template(software: PlacementSoftware) -> str:
    """
    Creates an output directory name template for .jplace files depends on software used.
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


def get_log_outputdir_template(software: PlacementSoftware) -> str:
    """
    Creates an output directory name template for .log files depends on software used.
    """
    _check_software(software)
    return os.path.join(config["workdir"], "logs", "placement_" + software.value, "{pruning}")


def get_common_queryname_template() -> str:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates an placement output filename template, based on the
    first type of inputs, and is independent of placement software used.
    """

    # For generated queries take the pruning and read length as an output template name.
    # For user queries take query file name as a template
    return "{pruning}_r{length}" if prunings_enabled() else "{query}"


def get_common_queryname_template_args() -> Mapping[str, Any]:
    """
    Each placement query has a template name based on two type of inputs:
    1) common arguments: tree and query sequences -- independent of software
    2) specific arguments: model params etc. -- depends on software used

    This method creates a dict of common template arguments that can be passed to
    'expand' function of snakemake to resolve the common query name template given
    by get_common_queryname_template().
    """

    if prunings_enabled():
        return {"prunings": range(config["pruning_count"]),
                "length": config["read_length"]}
    else:
        return {"query": query_ids}


def get_full_queryname_template(software: PlacementSoftware) -> str:
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
        return get_common_queryname_template() + "_g{gepa}"
    elif software == PlacementSoftware.EPA_NG:
        raise NotImplementedError()
    elif software == PlacementSoftware.PPLACER:
        raise NotImplementedError()
    elif software == PlacementSoftware.APPLES:
        raise NotImplementedError()
    elif software == PlacementSoftware.RAPPAS:
        return get_common_queryname_template() + "_k{k}_o{omega}_red{reduction}_ar{arsoft}"
    elif software == PlacementSoftware.RAPPAS2:
        raise NotImplementedError()


def get_full_queryname_template_args(software: PlacementSoftware) -> Mapping[str, Any]:
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
    template_args = get_common_queryname_template_args()

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
    if not prunings_enabled():
        template_args["pruning"] = ["full"]

    return template_args


def get_jplace_filename_template(software: PlacementSoftware) -> str:
    """
    Creates a .jplace filename template based on software used.
    """
    _check_software(software)

    # get the sofware name in lower case from Enum value
    software_name = software.value

    # {full_template}_{software}.jplace
    return get_full_queryname_template(software) + "_" + software_name + ".jplace"


def get_jplace_output_template(software: PlacementSoftware) -> str:
    """
    Creates a name template of .jplace output files produced by specific software.
    """
    # general output filename template
    output_dir_template =  get_jplace_outputdir_template(software)
    return os.path.join(output_dir_template, get_jplace_filename_template(software))


def _get_jplace_outputs(software: PlacementSoftware) -> List[str]:
    """
    Creates a list of .jplace output files produced by specific software.
    """
    # get the output template
    template = get_jplace_output_template(software)
    # get the full set of arguments to expand the template
    template_args = get_full_queryname_template_args(software)
    return expand(template, **template_args)


def get_log_filename_template(software: PlacementSoftware) -> str:
    """
    Creates a .log filename template based on software used.
    """
    # {full_template}.log
    return get_full_queryname_template(software)  + ".log"


def get_log_output_template(software: PlacementSoftware) -> str:
    """
    Creates a name template of .log output files produced by specific software.
    """
    # general output filename template
    output_dir_template =  get_log_outputdir_template(software)
    return os.path.join(output_dir_template, get_log_filename_template(software))


def extract_params(file):
    """
    extract phylo parameters from info file to transfer them to phyml
    """
    res={}
    with open(file,'r') as infofile:
        lines = infofile.readlines()
        for l in lines:
            if l.startswith("Substitution Matrix:") :
                res["model"]=l.split(":")[1].strip()
            if l.startswith("alpha:") :
                res["alpha"]=l.split(":")[1].strip()
    infofile.close()
    return res

def select_model_phymlstyle():
    if config["phylo_params"]["model"]=="GTR+G":
        return "GTR"
    if config["phylo_params"]["model"]=="JTT+G":
        return "JTT"
    if config["phylo_params"]["model"]=="WAG+G":
        return "WAG"
    if config["phylo_params"]["model"]=="LG+G":
        return "LG"

def select_model_raxmlstyle():
    if config["phylo_params"]["model"]=="GTR+G":
        return "GTRGAMMA"
    if config["phylo_params"]["model"]=="JTT+G":
        return "PROTGAMMAJTT"
    if config["phylo_params"]["model"]=="WAG+G":
        return "PROTGAMMAWAG"
    if config["phylo_params"]["model"]=="LG+G":
        return "PROTGAMMALG"

'''
select correct ancestral reconstruction binary depending on value set in config for arsoft
'''
def select_arbin(arsoft):
    if arsoft == "PHYML":
        return "phyml"
    elif arsoft == "RAXMLNG" :
        return "raxml-ng"
    elif (arsoft == "PAML") and (config["states"]==0):
        return "baseml"
    elif (arsoft == "PAML") and (config["states"]==1):
        return "codeml"

def expected_ar_outputs(arsoft):
    res=list()
    if arsoft == "PHYML":
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_ancestral_seq.txt")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_ancestral_tree.txt")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_stats.txt")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip_phyml_tree.txt")
    elif arsoft == "RAXMLNG" :
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.log")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.ancestralTree")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.ancestralProbs")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.startTree")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.ancestralStates")
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/extended_align.phylip.raxml.rba")
    elif arsoft == "PAML":
        res.append(config["workdir"]+"/RAPPAS/{pruning}/red{reduction}_ar{arsoft}/AR/rst")
    return res


'''
accessory function to correctly set which epa-ng heuristics are tested and with which parameters
'''
def select_epang_heuristics():
    l=[]
    if "h1" in config["config_epang"]["heuristics"]:
        l.append(
            expand(     config["workdir"]+"/EPANG/{pruning}/h1/{pruning}_r{length}_h1_g{gepang}_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        gepang=config["config_epang"]["h1"]["g"]
                   )
        )
    if "h2" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/EPANG/{pruning}/h2/{pruning}_r{length}_h2_bigg{biggepang}_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"],
                        biggepang=config["config_epang"]["h2"]["G"]
                        )
        )
    if "h3" in config["config_epang"]["heuristics"]:
        l.append(
             expand(    config["workdir"]+"/EPANG/{pruning}/h3/{pruning}_r{length}_h3_epang.jplace",
                        pruning=range(0,config["pruning_count"]),
                        length=config["read_length"]
                        )
        )
    if "h4" in config["config_epang"]["heuristics"]:
        l.append(
            expand(
                config["workdir"]+"/EPANG/{pruning}/h4/{pruning}_r{length}_h4_epang.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"]
                )
            )
    return l


def tmpdir_prefix(wildcards):
    return wildcards.pruning + "_r" + wildcards.length


def get_jplace_outputs() -> List[str]:
    """
    Creates a list of all .jplace files that are produced by all placement software
    """
    inputs = []

    if "epa" in config["test_soft"]:
        #inputs.extend(_get_jplace_outputs(PlacementSoftware.EPA))
        raise NotImplementedError()
    if "pplacer" in config["test_soft"]:
        inputs.extend(
            expand(
                config["workdir"]+"/PPLACER/{pruning}/ms{msppl}_sb{sbppl}_mp{mpppl}/{pruning}_r{length}_ms{msppl}_sb{sbppl}_mp{mpppl}_pplacer.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                msppl=config["config_pplacer"]["max-strikes"],
                sbppl=config["config_pplacer"]["strike-box"],
                mpppl=config["config_pplacer"]["max-pitches"]
            )
        )
    if "epang" in config["test_soft"]:
        inputs.extend(
            select_epang_heuristics()
        )
    if "rappas" in config["test_soft"]:
        inputs.extend(_get_jplace_outputs(PlacementSoftware.RAPPAS))
    if "apples" in config["test_soft"]:
        inputs.extend(
            expand(
                config["workdir"]+"/APPLES/{pruning}/m{meth}_c{crit}/{pruning}_r{length}_m{meth}_c{crit}_apples.jplace",
                pruning=range(0,config["pruning_count"]),
                length=config["read_length"],
                meth=config["config_apples"]["methods"],
                crit=config["config_apples"]["criteria"]
            )
        )
    return inputs

