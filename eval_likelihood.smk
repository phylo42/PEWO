'''
@author Nikolai Romashchenko
'''

configfile: "config.yaml"


#utils
include:
    "modules/utils/wk.smk"
include:
    "modules/utils/etc.smk"
#prunings
include:
    "modules/op/operate_prunings.smk"
#tree optimisation
include:
    "modules/op/operate_optimisation.smk"
#phylo-kmer placement, e.g.: rappas
include:
    "modules/op/operate_ar.smk"
include:
    "modules/placement/placement_rappas_dbinram.smk"
include:
       "modules/placement/placement_rappas2.smk"
#alignment (for distance-based and ML approaches)
include:
    "modules/alignment/alignment_hmm.smk"
#ML-based placements, e.g.: epa, epang, pplacer
include:
    "modules/placement/placement_epa.smk"
include:
    "modules/placement/placement_pplacer.smk"
include:
    "modules/placement/placement_epang_h1.smk"
include:
    "modules/placement/placement_epang_h2.smk"
include:
    "modules/placement/placement_epang_h3.smk"
include:
    "modules/placement/placement_epang_h4.smk"
#distance-based placements, e.g.: apples
include:
    "modules/placement/placement_apples.smk"
#results evaluation and plots
include:
    "modules/op/operate_nodedistance.smk"
include:
    "modules/op/operate_plots.smk"

'''
top snakemake rule, necessary to launch the workflow
'''
rule all:
     input:
         build_accuracy_workflow()