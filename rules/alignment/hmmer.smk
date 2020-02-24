"""
A module to operate hmm alignments for likelihood evaluations
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
import pewo.config as cfg
from pewo.software import AlignmentSoftware, CustomScripts
from pewo.templates import get_software_dir, get_experiment_log_dir_template, \
    get_common_queryname_template, get_benchmark_template, get_common_template_args


_work_dir = cfg.get_work_dir(config)
_alignment_dir = get_software_dir(config, AlignmentSoftware.HMMER)


_hmmer_benchmark_align_template = get_benchmark_template(config, AlignmentSoftware.HMMER,
                                                         p="pruning", length="length",
                                                         rule_name="align") if cfg.get_mode(config) == cfg.Mode.RESOURCES else ""
hmmer_benchmark_templates = [_hmmer_benchmark_align_template]
hmmer_benchmark_template_args = [get_common_template_args(config)]


rule hmm_build:
    """
    Builds an hmm profile.
    """
    input:
        alignment = os.path.join(_work_dir, "A", "{pruning}.align")
    output:
        hmm = os.path.join(_alignment_dir, "{pruning}.hmm")
    log:
        os.path.join(get_experiment_log_dir_template(config, AlignmentSoftware.HMMER),
                     "{pruning}.log")
    version:
        "1.0"
    params:
        states = ["dna"] if config["states"] == 0 else ["amino"]
    threads: 1
    shell:
        "hmmbuild --cpu {threads} --{params.states} {output.hmm} {input.alignment} &> {log}"


rule hmm_align:
    """
    Aligns a query to a profile.
    """
    input:
        hmm = os.path.join(_alignment_dir, "{pruning}.hmm"),
        alignment = os.path.join(_work_dir, "A", "{pruning}.align"),
        query = os.path.join(_work_dir,
                             "R",
                             get_common_queryname_template(config) + ".fasta")
    output:
        psiblast = os.path.join(_alignment_dir,
                                "{pruning}",
                                get_common_queryname_template(config) + ".psiblast")
    version:
        "1.0"
    log:
        os.path.join(get_experiment_log_dir_template(config, AlignmentSoftware.HMMER),
                     get_common_queryname_template(config) + ".log")
    benchmark:
        repeat(_hmmer_benchmark_align_template, config["repeats"])
    params:
        states = ["dna"] if config["states"] == 0 else ["amino"],
    shell:
        "hmmalign --{params.states} --outformat PSIBLAST -o {output.psiblast} " +
        "--mapali {input.alignment} {input.hmm} {input.query} &> {log}"


rule psiblast_to_fasta:
    """
    Converts psiblast to fasta format.
    """
    input:
        psiblast = os.path.join(_alignment_dir,
                                "{pruning}",
                                get_common_queryname_template(config) + ".psiblast")
    output:
        alignment = os.path.join(_alignment_dir,
                                 "{pruning}",
                                 get_common_queryname_template(config) + ".fasta")
    version:
        "1.0"
    log:
        os.path.join(get_experiment_log_dir_template(config, CustomScripts.PSIBLAST_2_FASTA),
                     get_common_queryname_template(config) + ".log")
    shell:
        "pewo/alignment/psiblast2fasta.py {input.psiblast} {output.alignment} &> {log}"


rule split_alignment:
    """
    Splits hmm alignment results in "query only" and "reference alignment only" sub-alignments.
    Contrary to other placement software, such input is required by epa-ng
    """
    input:
        align = os.path.join(_alignment_dir,
                            "{pruning}",
                             get_common_queryname_template(config) + ".fasta"),
        reads = os.path.join(_work_dir,
                            "R",
                             get_common_queryname_template(config) + ".fasta"),
    output:
          os.path.join(_alignment_dir,
                       "{pruning}",
                        get_common_queryname_template(config) + ".fasta_queries"),
          os.path.join(_alignment_dir,
                       "{pruning}",
                        get_common_queryname_template(config) + ".fasta_refs"),
    version: "1.0"
    shell:
        "pewo/alignment/split_hmm_alignment.py {input.reads} {input.align}"
