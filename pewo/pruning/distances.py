import os
from typing import Dict, List

from pewo.software import PlacementSoftware


class DistanceGenerator:
    # fixed names
    __NODEDISTANCE_MATRIX_FILENAME = "Dtx.tsv"
    __BRANCHDISTANCE_MATRIX_FILENAME = "Dtx2.tsv"

    def __init__(self, config: Dict):
        """
        software_list as defined by PlacementSoftware
        """
        workdir = config["workdir"]
        # test directories
        if not os.path.exists(workdir):
            raise Exception("Directory do not exists: " + workdir)
        nd_matrix_path = os.path.join(workdir, self.__NODEDISTANCE_MATRIX_FILENAME)
        bd_matrix_path = os.path.join(workdir, self.__BRANCHDISTANCE_MATRIX_FILENAME)
        if not os.path.exists(nd_matrix_path):
            raise Exception("tsv file do not exists: " + workdir)
        elif not os.path.exists(bd_matrix_path):
            raise Exception("tsv file do not exists:: " + workdir)
        # software list
        software_list = list()
        for soft in PlacementSoftware:
            if soft.value in config["test_soft"]:
                software_list.append(soft.name)
        # parse ND et BD matrices content
        self._ND = self.Dtx(nd_matrix_path)
        self._BD = self.Dtx(bd_matrix_path)
        # TODO: make that Dx contains the expected_placement

        # load all all jplaces resulting form experiments
        soft_dir = ""
        for soft in software_list:
            soft_dir = os.path.join(workdir, soft)
        jplace_results = [
            str(os.path.join(r, fn))
            for r, ds, fs in os.walk(soft_dir)
            for fn in fs if fn.endswith(".jplace")
        ]

        # define list of parameters
        param_set = dict()
        column_counter = -1
        param_set["software"] = column_counter + 1
        param_set["pruning"] = column_counter + 1
        param_set["rstart"] = column_counter + 1
        param_set["rend"] = column_counter + 1
        param_set["nd"] = column_counter + 1
        param_set["e_nd"] = column_counter + 1

        # pattern to detemine parameter values
        pattern = "([a-z]+)([0-9A-Z\\.]+)"
        #TODO python pattern

        for i in jplace_results:
            jplace_label = os.path.basename(i).split(".jplace")[0]
            elts = jplace_label.split("_")
            # 1st element is pruning id, last is "software.jplace"
            for j in range(1, len(elts)):
                #Matcher = pat.matcher(elts[j]);
                #if m.matches:
                    #param = m.group(1)
                    if param not in param_set:
                        param_set[param] = column_counter+1

        # prepare a nice csv file with all distances
        csv_path = os.path.join(workdir, "results.csv")
        col = 0
        with open(csv_path, 'w') as writer:
            for key in param_set.keys():
                if col > 0:
                    writer.write(";")
                writer.write(key)
                col += 1
            writer.write('\n')


        # for each jplace, compute node distance
        for i in jplace_results:
            print("Parsing "+i)
            jplace_label = os.path.basename(i).split(".jplace")[0]
            elts = jplace_label.split('_')
            # information related to this placement
            pruning = int(elts[0])
            software = elts[len(elts)-1]
            infos = jplace_label.split('_')
            params_values = dict()
            # define from jplace filenames which parameters were tested
            pattern = "([a-z]+)([0-9A-Z\\.]+)"

            for ids in range(1, len(infos)):
                #Matcher m = pat.matcher(infos[idx])
                matches = True
                if matches:
                    param = m.group(1)
                    if param in param_set:
                        v = m.group(2)
                        params_values[param_set[param]] = v
                else:
                    print("Error in jplace filename parameters coding, do not matches expected pattern.")
                    exit(1)
            params_values[param_set["pruning"]] = int(pruning)
            params_values[param_set["software"]] = software

            # TODO replace expect_placement mechanism via Dtx

            # TODO python jplace loader
            # TODO make mapping between jplace and pruned tree if any software change the newick representation
            # placements: Dict[str, List[Placement]] = dict()

            # TODO iterate on placements and report distances
            for name in placements:
                top_ND = -1
                top_BD = -1
                top_lwr = -1
                nds = []
                lwrs = []
                lwr_sum = 0.0

                # iterate on placement branches once to compute (distance)*LWR sums
                for idx, p in enumerate(name):
                    jplace_tree_node_id = p.get_node_id()
                    lwr =  p.get_lwr()
                    # TODO check node id mapping beetween jplace / experimental
                    experiment_node_id = 0
                    pruning_idx = 0
                    node_distance = self._ND.get_distance(pruning_idx, experiment_node_id)
                    lwr_sum += lwr

                # iterate again to compute "expected" distances
                eND = 0.0
                eBD = 0.0
                for idx in range(0, name):
                    jplace_tree_node_id = name[idx].get_node_id()
                    lwr = name[idx].get_weight_ratio()
                    if idx == 0:
                        top_lwr = lwr
                    # TODO check node id mapping between jplace / experimental
                    experiment_node_id = 0
                    pruning_idx = 0
                    node_distance = self._ND.get_distance(pruning_idx, experiment_node_id)
                    branch_distance = self._BD.get_distance(pruning_idx, experiment_node_id)
                    if idx == 0:
                        top_ND = node_distance
                        top_BD = node_distance
                    eND += node_distance * lwr / lwr_sum
                    eBD += branch_distance * lwr / lwr_sum

                # get coordinates of placed read in original alignment (before pruning)
                infos = name.split('_')
                read_start = infos[len(infos)-2]
                read_end = infos[len(infos)-1]
                # set values in csv columns
                params_values[param_set["rstart"]] = str(read_start)
                params_values[param_set["rend"]] = str(read_end)
                params_values[param_set["nd"]] = str(top_ND)
                params_values[param_set["e_nd"]] = str(eND)
                # now build output line
                for column in param_set:
                    if column > 0:
                        writer.write(';')
                    if column in params_values:
                        writer.write(params_values[column])
                writer.write('\n')




    class Dtx:

        def __init__(self, Dtx_file: str):
            self._pruning_labels = dict()
            self._pruning_ids = dict()
            self._col_labels = dict()
            self._col_ids = dict()
            self._data = list()
            # parse Dtx matrix content
            with open(Dtx_file) as matrix:
                line_idx = 1
                data = list()
                for line in matrix:
                    elts = line.split(';')
                    # 1st header
                    if elts[0] == "nodeLabels":
                        for i in range(2, len(elts)):
                            self._col_labels[elts[i]] = i - 2
                        continue
                    # 2nd line
                    if elts[1] == "nodeIds":
                        for i in range(2, len(elts)):
                            self._col_labels[int(elts[i])] = i - 2
                        continue
                    # other lines
                    line_data = []
                    self._pruning_labels[elts[0]] = line_idx
                    self._pruning_ids[int(elts[1])] = line_idx
                    for i in range(2, len(elts)):
                        line_data.append(int(elts[i]))
                        self._data.append(line_data)
                    line_idx += 1

        def get_distance(self, nx_id: int, node_id: int) -> int:
            return self._data[self._pruning_ids[nx_id]][self._col_ids[node_id]]

        def to_string(self) -> str:
            s = ""
            for i in range(0, len(self._data)):
                for j in range(0, len(self._data[i])):
                    v = self._data[i][j]
                    if j > 0:
                        s += ";"
                    s += v
                s += "\n"
            return s
