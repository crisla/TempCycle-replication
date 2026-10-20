#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TempCycle - master replication script (Python stage).

    "So alike, yet so different: A non-parametric variance decomposition
     of unstable employment cycles"
    Guell, Lafuente, Peters, Sanchez, Turon

This script runs the Python stage of the pipeline: it turns the Stata
decomposition and descriptive-statistics outputs in `data/intermediate/`
into the LaTeX tables and figures used in the paper.

Run from the repository root:

    python run_all.py

The Stata stage comes first and is *not* run from here, because it needs
restricted microdata that is not distributed with this package. See
`data/raw/README.md` for how to obtain the SIAB (Germany) and the MCVL
(Spain), and `code/germany/master.do` / `code/spain/master.do` for the
Stata run order.

Every step below runs against the intermediate files that ship with this
package, so the full set of paper tables can be rebuilt without any
microdata access -- with one exception, flagged as REQUIRES_RAW below.
"""

import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# Steps run with cwd=ROOT, so the scripts' relative paths resolve.
#   script, description, expected output, needs_restricted_microdata
STEPS = [
    ("code/python/results_tables.py",
     "Decomposition tables -> output/tables/results_tables.tex",
     "output/tables/results_tables.tex",
     False),
    ("code/python/descriptive_stats_tables.py",
     "Descriptive statistics -> output/tables/descriptive_stats_tables.tex",
     "output/tables/descriptive_stats_tables.tex",
     False),
    ("code/python/sample_selection_germany.py",
     "Sample selection, Germany (discrete 2x2 GMM)",
     "output/sample_selection/selection_germany.json",
     False),
    ("code/python/sample_selection_spain.py",
     "Sample selection, Spain (discrete 2x2 GMM)",
     "output/sample_selection/selection_spain.json",
     True),
    ("code/python/sample_selection_tables.py",
     "Sample-selection tables -> output/tables/sample_selection_tables.tex",
     "output/tables/sample_selection_tables.tex",
     False),
]

# Inputs that only exist if the user has placed restricted microdata.
RAW_MARKER = ROOT / "data" / "raw" / "spain" / "duration"


def run_step(script, description):
    print(f"\n{'=' * 78}\n>>> {description}\n    ({script})\n{'=' * 78}", flush=True)
    t0 = time.time()
    result = subprocess.run([sys.executable, script], cwd=ROOT)
    dt = time.time() - t0
    if result.returncode != 0:
        print(f"\n!!! {script} FAILED (exit {result.returncode}) after {dt:.1f}s",
              flush=True)
        return False
    print(f"\n    OK ({dt:.1f}s)", flush=True)
    return True


def main():
    print("TempCycle - Python replication stage")
    failed, skipped = [], []

    for script, description, _output, needs_raw in STEPS:
        if not (ROOT / script).exists():
            print(f"!!! missing script: {script}")
            failed.append(script)
            continue

        if needs_raw and not RAW_MARKER.is_dir():
            print(f"\n{'=' * 78}\n--- SKIPPED: {description}\n    ({script})")
            print("    This step needs restricted Spanish microdata (MCVL), which")
            print("    is not distributed with this package. The fitted estimates it")
            print("    would produce ship pre-computed at")
            print("    output/sample_selection/selection_spain.json, so the step")
            print("    below still builds the paper's table.")
            print("    See data/raw/README.md to obtain the MCVL.")
            print('=' * 78, flush=True)
            skipped.append(script)
            continue

        if not run_step(script, description):
            failed.append(script)

    print(f"\n{'=' * 78}\nSUMMARY\n{'=' * 78}")
    for script, _description, output, _needs_raw in STEPS:
        if script in skipped:
            status = "skipped (no microdata)"
        elif script in failed:
            status = "FAILED"
        elif (ROOT / output).exists():
            status = "ok"
        else:
            status = "ran, output missing"
        print(f"  [{status:>22}]  {Path(script).name:<30} -> {output}")

    if failed:
        print(f"\n{len(failed)} step(s) failed: {', '.join(failed)}")
        sys.exit(1)
    if skipped:
        print(f"\nCompleted. {len(skipped)} step(s) skipped for lack of restricted "
              f"microdata; all paper tables were still produced.")
    else:
        print("\nAll steps completed successfully.")


if __name__ == "__main__":
    main()
