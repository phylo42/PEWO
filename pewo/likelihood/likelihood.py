

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"

import pandas as pd
from typing import List


def combine_csv(input_files: List[str], output_file: str) -> None:
    l = []
    for f in input_files:
        print(f)
        l.append(pd.read_csv(f, delimiter=";"))

    df = pd.concat(l)
    df.to_csv(output_file, sep=";", index=False)

