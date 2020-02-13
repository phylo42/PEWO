#!/usr/bin/env python
"""
Split an alignment into queries-only and reference-only sub-alignments
Usage: split_hmm_alignments.py queries.fasta alignment.fasta
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import sys
from Bio import SeqIO
from typing import Dict


def _get_queries(input_file: str) -> Dict:
    queries = {}
    for record in SeqIO.parse(input_file, "fasta"):
        queries[record.id] = 1
    return queries


if __name__ == "__main__":
    # set which identifiers are queries
    input_file = sys.argv[1]
    queries = _get_queries(input_file)

    # parse and split alignment
    with open(sys.argv[2] + "_queries", "w") as output_queries:
        with open(sys.argv[2] + "_refs", "w") as output_refs:
            for record in SeqIO.parse(sys.argv[2], "fasta"):
                if record.id in queries:
                    output_queries.write('>%s\n' % record.id)
                    output_queries.write('%s\n' % record.seq)
                else:
                    output_refs.write('>%s\n' % record.id)
                    output_refs.write('%s\n' % record.seq)
