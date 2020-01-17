"""
A module to work with .fasta-formatted files.
"""

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"


import os
from Bio import SeqIO
from typing import List, List


def get_sequence_ids(input_file: str) -> List[str]:
    """
    Retrieves sequence IDs from the input .fasta file.
    """

    # replace underscores with dashes, needed to have nice output
    # filename templates with underscore as a delimiter for parameters
    underscore_filter = lambda x: x.replace("_", "-")
    return [underscore_filter(record.id) for record in SeqIO.parse(input_file, "fasta")]


def _write_fasta(records: List[SeqIO.SeqRecord], filename: str) -> None:
    with open(filename, "w") as output:
        SeqIO.write(records, output, "fasta")


def split_fasta(input_file: str, output_dir: str) -> List[str]:
    """
    Splits the input .fasta file into multiple .fasta files,
    one sequence per file. Returns the list of resulting files.
    """
    files = []
    for record in SeqIO.parse(input_file, "fasta"):
        output_file = os.path.join(output_dir, record.id + ".fasta")
        _write_fasta([record], output_file)
        files.append(output_file)

    return files
