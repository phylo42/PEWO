'''
A module to operate placements with RAPPAS v2

@author Nikolai Romashchenko
'''

rule aronly_rappas:
    input:
        a=config["workdir"]+"/A/{pruning}.align",
        t=config["workdir"]+"/T/{pruning}.tree",
        arseq=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/AR/extended_align.phylip_phyml_ancestral_seq.txt",
        artree=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/AR/extended_align.phylip_phyml_ancestral_tree.txt",
    output:
        ar_mapping=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/AR/ARtree_id_mapping.tsv"
    log:
        config["workdir"]+"/logs/aronly_rappas2/{pruning}_red{reduction}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_red{reduction}_rappas-dbbuild_benchmark.tsv", config["repeats"])
    version:
        "1.00"
    params:
        states=["nucl"] if config["states"]==0 else ["amino"],
        ardir=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/AR",
        workdir=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/k{k}_o{omega}",
    run:
         shell(
            "java -Xms2G -Xmx"+str(config["config_rappas"]["memory"])+"G -jar $(which RAPPAS.jar) -p b -b $(which phyml) "
            "-k {wildcards.k} --omega {wildcards.omega} -t {input.t} -r {input.a} -q {params.querystring} "
            "-w {params.workdir} --ardir {params.ardir} -s {params.states} --ratio-reduction {wildcards.reduction} "
            "--use_unrooted --aronly &> {log} "
         )

# Usage of the rappas-buildn:
# rappas-buildn
# -t tree.newick:
# -x extended_tree_withBL.tree
# -a extended_align.phylip_phyml_ancestral_seq.txt
# -e extended_tree_node_mapping.tsv
# -m ARtree_id_mapping.tsv
# -w working_dir
# -k kmer_size
# -o omega
# -j num_threds

rule dbbuild_rappas2:
    input:
        t=config["workdir"]+"/T/{pruning}.tree",
        x=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/extended_trees/extended_tree_withBL.tree",
        arseq=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/AR/extended_align.phylip_phyml_ancestral_seq.txt",
        ext_mapping=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/extended_trees/extended_tree_node_mapping.tsv",
        ar_mapping=config["workdir"]+"/RAPPAS/{pruning}/red{reduction}/AR/ARtree_id_mapping.tsv"
    output:
        q=config["workdir"]+"/RAPPAS2/{pruning}/red{reduction}/k{k}_o{omega}/DB_k{k}_o{omega}.rps"
    log:
        config["workdir"]+"/logs/dbbuild_rappas2/{pr2uning}_k{k}_o{omega}_red{reduction}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_k{k}_o{omega}_red{reduction}_rappas-dbbuild_benchmark.tsv", config["repeats"])
    version:
        "1.00"
    params:
        tmpdir=config["workdir"]+"/RAPPAS2/{pruning}/red{reduction}/k{k}_o{omega}"
    run:
        shell(
            "rappas-buildn "
            "-t {input.t} -x {input.x} -a {input.arseq} -e {input.ext_mapping} -m {input.ar_mapping} "
            "-w {params.tmpdir} -k {wildcards.k} -o {wildcards.omega} -j 1 &> {log}"
        )

rule placement_rappas:
    input:
        db=config["workdir"]+"/RAPPAS2/{pruning}/red{reduction}/k{k}_o{omega}/DB_k{k}_o{omega}.rps",
        r=config["workdir"]+"/R/{pruning}_r{length}.fasta",
    output:
        config["workdir"]+"/RAPPAS2/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_rappas.jplace"
    log:
        config["workdir"]+"/logs/placement_rappas/{pruning}/red{reduction}/k{k}_o{omega}/{pruning}_r{length}_k{k}_o{omega}_red{reduction}.log"
    benchmark:
        repeat(config["workdir"]+"/benchmarks/{pruning}_r{length}_k{k}_o{omega}_red{reduction}_rappas-placement_benchmark.tsv", config["repeats"])
    version: "1.00"
    params:
        workdir=config["workdir"]+"/RAPPAS2/{pruning}/red{reduction}/k{k}_o{omega}",
    run:
        shell(
            "rappas-placen {input.db} {params.workdir} 1 {input.r} &> {log}"
        )

        for length in config["read_length"]:
            shell(
                "mv {params.workdir}/placements_{wildcards.pruning}_r"+str(length)+".fasta.jplace "
                "{params.workdir}/{wildcards.pruning}_r"+str(length)+"_k{wildcards.k}_o{wildcards.omega}_red{wildcards.reduction}_rappas.jplace "
            )