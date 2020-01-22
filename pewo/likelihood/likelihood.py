

__author__ = "Nikolai Romashchenko"
__license__ = "MIT"

import pandas as pd
from typing import List


def combine_csv(input_files: List[str], output_file: str) -> None:
    df = pd.concat([pd.read_csv(f, delimiter=";") for f in input_files])
    df.to_csv(output_file, sep=";", index=False)

