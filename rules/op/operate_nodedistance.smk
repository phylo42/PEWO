"""
Computes the ND (node distance) metric using .jplace output files
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

import os
import pewo.config as cfg

_working_dir = cfg.get_work_dir(config)


rule compute_nodedistance:
    input:
        jplace_files=get_jplace_outputs(config)
    output:
        os.path.join(_working_dir, "results.csv")
    log:
        os.path.join(_working_dir, "logs", "compute_nd.log")
    params:
          workdir=_working_dir,
          compute_epa=1 if "epa" in config["test_soft"] else 0,
          compute_epang=1 if "epang" in config["test_soft"] else 0,
          compute_pplacer=1 if "pplacer" in config["test_soft"] else 0,
          compute_rappas=1 if "rappas" in config["test_soft"] else 0,
          compute_apples=1 if "apples" in config["test_soft"] else 0,
          compute_appspam=1 if "appspam" in config["test_soft"] else 0,
          jar=config["pewo_jar"]
    shell:
         "java -cp {params.jar} DistanceGenerator_LITE2 {params.workdir} "
         "{params.compute_epa} {params.compute_epang} {params.compute_pplacer} {params.compute_rappas} {params.compute_apples} {params.compute_appspam} &> {log}"
