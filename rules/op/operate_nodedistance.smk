"""
Computes the ND (node distance) metric using .jplace output files
"""

__author__ = "Benjamin Linard, Nikolai Romashchenko"
__license__ = "MIT"

import os
import pewo.config as cfg
from pewo.software import PlacementSoftware

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
          software_dir_list=','.join(PlacementSoftware.get_by_value(soft_str).value.upper() for soft_str in config["test_soft"]),
          jar=config["pewo_jar"]
    shell:
         """
         java -cp {params.jar} DistanceGenerator_LITE2 {params.workdir} {params.software_dir_list} &> {log}
         """
