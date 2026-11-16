"""
Stack NYC Yellow Taxi trip data (August + September 2025)
=========================================================
Step 1 of the pipeline: prepare a single clean CSV for loading into Snowflake.

This step was originally built as an Alteryx workflow. This script reproduces
the same logic in Python and produces an identical output file.

  1. Import each monthly file
  2. Drop empty rows    (every column is empty)
  3. Drop empty columns (every row is empty, e.g. `mileage`)
  4. Stack August and September into one file

Usage (from the repository root):
    python scripts/stack_trip_data.py
"""

from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW_FILES = [
    ROOT / "data" / "raw" / "yellow_tripdata_2025-08.csv",
    ROOT / "data" / "raw" / "yellow_tripdata_2025-09.csv",
]
OUTPUT = ROOT / "data" / "processed" / "yellow_tripdata_stacked.csv"


def clean(df: pd.DataFrame, name: str) -> pd.DataFrame:
    empty_rows = int(df.isna().all(axis=1).sum())
    empty_cols = df.columns[df.isna().all()].tolist()
    df = df.dropna(how="all").dropna(axis=1, how="all")
    print(f"{name}: dropped {empty_rows:,} empty rows and columns {empty_cols} "
          f"-> {df.shape[0]:,} rows x {df.shape[1]} cols")
    return df


def main() -> None:
    frames = [clean(pd.read_csv(path), path.name) for path in RAW_FILES]
    stacked = pd.concat(frames, ignore_index=True)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    stacked.to_csv(OUTPUT, index=False)
    print(f"Stacked: {stacked.shape[0]:,} rows x {stacked.shape[1]} cols -> {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
