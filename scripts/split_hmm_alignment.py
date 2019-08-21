#!/usr/bin/env python

###############################
# Split an alignment into queries-only and reference-only sub-alignments
# usage: split_hmm_alignments.py queries.fasta alignment.fasta
###############################

from Bio import SeqIO
import sys

#set which identifiers are queries
queries={}
for record in SeqIO.parse(sys.argv[1], "fasta"):
    queries[record.id]=1

#parse and split alignment
with open(sys.argv[2]+"_queries", "w") as output_queries:
    with open(sys.argv[2]+"_refs", "w") as output_refs:
        for record in SeqIO.parse(sys.argv[2], "fasta"):
            if record.id in queries:
                output_queries.write('>%s\n' % record.id)
                output_queries.write('%s\n' % record.seq)
            else:
                output_refs.write('>%s\n' % record.id)
                output_refs.write('%s\n' % record.seq)

print("DONE")