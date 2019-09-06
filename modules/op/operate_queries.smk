'''
Prepare directories to run a ressource test.
Basically, it uses same directory structure than a pruning test, but with a unique run '0', which uses full dataset and
in which repeated runs are set via the snakemake benchmark command.
Queries are set as R/O/O_r0.fasta , whatever if they come from a user file or computed from the input alignment.

@author Benjamin Linard
'''

# TODO: script of function to compute reads from alignment

def queries():
    if config["type"]=="file":
        return config["query_file"]
    else:
        #compute queries from alignment
        return ""



rule define_input_from_file:
    input:
        a=config["dataset_align"],
        t=config["dataset_tree"],
        r=queries()
    output:
        aout=expand(config["workdir"]+"/A/{pruning}.align",pruning=0),
        tout=expand(config["workdir"]+"/T/{pruning}.tree",pruning=0),
        gout=expand(config["workdir"]+"/G/{pruning}.fasta", pruning=0),
        rout=expand(config["workdir"]+"/R/{pruning}_r{length}.fasta", pruning=0, length=0)
    run:
        shell(
            """
            cp {input.a} {output.aout}
            cp {input.t} {output.tout}
            """
        )
        if config["type"]=='file':
            shell(
                """
                cp {input.r} {output.rout}
                cp {input.r} {output.gout}
                """
            )