'''
module to split hmm alignment results in "query only" and "reference alignment only" su-alignments
contrary to other placement software, such input is required by epa-ng
@author Benjamin Linard
'''

configfile: "config.yaml"

rule all:
    input: expand("HMM/{pruning}_r{length}.fasta", pruning=range(1,config["pruning_count"]+1,1), length=config["read_length"])