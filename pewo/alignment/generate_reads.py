#!/usr/bin/env python
"""
Split an alignment into queries-only and reference-only sub-alignments
Usage: split_hmm_alignments.py queries.fasta alignment.fasta
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"


import sys
import os
import subprocess
import time
import random
from Bio import SeqIO
from typing import Dict
import pewo.config as cfg

def change_reads_to_art(config: Dict):
    print("Changing reads to art simulated reads.")

    # Get lengths of current reads
    number_of_reads = {}
    read_names = {}
    for count in range(config["pruning_count"]):
        number_of_reads[count] = {}
        read_names[count] = {}
        for read_length in config["read_length"]:
            read_names_list = []
            file = str(config["workdir"]) + "/R/" + str(count) + "_r" + str(read_length) + ".fasta" 
            seqs = list(SeqIO.parse(file, format='fasta'))
            number_of_reads[count][read_length] = len(seqs)
            for seq in seqs:
                read_names_list.append(seq.id)
            read_names[count][read_length] = read_names_list

    print(number_of_reads)

    # Delete all current reads
    folder = config["workdir"] + "/R"
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print('Failed to delete %s. Reason: %s' % (file_path, e))

    # Create new reads with ART
    for count in range(config["pruning_count"]):
        for read_length in config["read_length"]:
            print(read_names[count][read_length])
            reference_file = config["workdir"] + "/G/" + str(count) + '.fasta'
            output_file = str(config["workdir"]) + "/R/" + str(count) + "_r" + str(read_length)
            subprocess.run('/home/matthias/Documents/art_bin_MountRainier/art_illumina -ss HS25 -sam -i ' + reference_file + ' -l ' + str(read_length) + 
                ' -c ' + str(4*number_of_reads[count][read_length]) + ' -o ' + str(output_file), shell=True)
            seqs = list(SeqIO.parse(output_file + '.fq', format='fastq'))
            random.shuffle(seqs)
            print('NUMBER OF GENERATED READS:')
            print(len(seqs))
            new_seqs = []
            i = 0
            for seq in seqs:
                seq.id = read_names[count][read_length][i]
                seq.name = ''
                seq.description = ''
                new_seqs.append(seq)
                i += 1
                if i >= len(read_names[count][read_length]):
                    break;
            SeqIO.write(new_seqs, output_file + '.fasta', format='fasta')


