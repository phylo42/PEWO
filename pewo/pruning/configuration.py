from pewo.pruning.pruning import *


class RunConfig:
    def __init__(self):
        self.tree: Tree
        self.traverse: List
        self.nodeprune: List


def validate_config(config: Dict):
    """
    validate loaded snakemake config, MUST init config["config_general"]
    :param config:
    :return: True if no error
    """
    conf = RunConfig()
    conf.tree = Tree(config["dataset_tree"], format=1)
    # must be done 1st to set global variable 'traverse'
    conf.traverse = postorder_explo(conf.tree)
    # following functions rely on local variable 'traverse'
    conf.nodeprune = list_pruned_node(conf.tree,
                                   config["minimleaf"],
                                   config["pruning_count"])
    # tree, traversal order, node to prune ids ... all those are saved in
    # snakemake config dict for future uses in the pipeline
    config["config_general"] = conf
    if int(len(conf.nodeprune)) != config["pruning_count"]:
        config["pruning_count"] = int(len(conf.nodeprune))
        print("Update done")
    return True
