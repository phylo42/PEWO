#!/usr/bin/env python
"""
Generate reads with ART.
"""

__author__ = "Matthias Blanke"
__license__ = "MIT"


import sys
import os
import subprocess
import random
from Bio import SeqIO
from typing import Dict
import pewo.config as cfg

def change_reads_to_art(config: Dict):
    print("Changing reads to art simulated reads.")

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
            reference_file = config["workdir"] + "/G/" + str(count) + '.fasta'
            output_file = str(config["workdir"]) + "/R/" + str(count) + "_r" + str(read_length)
            if config['ART_platform'] == 'illumina':
                subprocess.run('art_illumina -na -ss HS25 -sam -i ' + reference_file + ' -l ' + str(read_length) + 
                ' -c ' + str(config['num_reads']) + ' -o ' + str(output_file), shell=True)
            elif config['ART_platform'] == '454':
                subprocess.run('art_454 ' + reference_file + ' ' + output_file + ' ' + str(5))
            else:
                err('Wrong platform specified for ART: ', config['ART_platform'])

            seqs = list(SeqIO.parse(output_file + '.fq', format='fastq'))
            SeqIO.write(seqs, output_file + '.fasta', format='fasta')

    # Delete unecessary files created by ART
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        if file_path.endswith('fq') or file_path.endswith('sam') or file_path.endswith('stat'):
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path)
                elif os.path.isdir(file_path):
                    shutil.rmtree(file_path)
            except Exception as e:
                print('Failed to delete %s. Reason: %s' % (file_path, e))
