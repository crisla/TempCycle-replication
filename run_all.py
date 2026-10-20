#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TempCycle - master replication script (Python stage).

    "So alike, yet so different: A non-parametric variance decomposition
     of unstable employment cycles"
    Guell, Lafuente, Peters, Sanchez, Turon

This script is the single entry point. It runs, in order:

  1. Stata stage (Spain, Germany): `code/<country>/master.do`, but only if a
     Stata executable is on PATH (or $TEMPCYCLE_STATA) AND the restricted
     microdata are in place (Germany: only inside the FDZ, $TEMPCYCLE_FDZ=1).
     Otherwise the stage is skipped with a message.
  2. Python stage: turns the Stata decomposition and descriptive-statistics
     output in `data/intermediate/` into the LaTeX tables and figures.

Every skip is reported and the script still exits 0; it exits 1 only if a
step that did run fails. See `data/raw/README.md` for how to obtain the
SIAB (Germany) and the MCVL (Spain).

Run from the repository root:

    python run_all.py

Without microdata or Stata, every Python step runs against the intermediate
files that ship with this package, so all tables and figures are rebuilt --
with one exception (the Spain GMM re-estimation), flagged REQUIRES_RAW below.
"""

import os
import re
import shutil
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
    ("code/python/results_interpretation_figures.py",
     "Expected-remaining-duration figures -> output/figures/*.png",
     "output/figures/het_DD_base_a.png",
     False),
    ("code/python/sample_selection_figures.py",
     "Spain sample-selection figures (from shipped estimates)",
     "output/sample_selection/type_grid_2x2.png",
     False),
]


# ---------------------------------------------------------------------------
# Stage 1 (Stata). Runs only when BOTH a Stata executable and the restricted
# microdata are present; otherwise it is skipped with a message and the
# shipped intermediate output in data/intermediate/ is used instead, so the
# script still exits 0.
#   name, folder, master do-file, data marker, extra env requirement
# ---------------------------------------------------------------------------
STATA_CANDIDATES = ["stata-mp", "stata-se", "stata", "StataMP", "StataSE"]

STATA_STAGES = [
    # Spain: MCVL placed as described in data/raw/README.md.
    ("Spain (MCVL)", "code/spain", "master.do",
     ROOT / "data" / "raw" / "spain" / "rawfiles" / "2021", None),
    # Germany: the SIAB never leaves the FDZ, so this stage is opt-in and only
    # meaningful inside the FDZ/JoSuA environment (set TEMPCYCLE_FDZ=1 there).
    ("Germany (SIAB)", "code/germany", "master.do",
     None, "TEMPCYCLE_FDZ"),
]

# Fresh Stata logs written by the Spain pipeline -> where the Python stage reads them.
SPAIN_LOG_SYNC = [("code/spain/results", "data/intermediate/spain/results"),
                  ("code/spain/descriptive_stats", "data/intermediate/spain/descriptive_stats")]


def find_stata():
    """Stata executable: $TEMPCYCLE_STATA if set, else the first of STATA_CANDIDATES on PATH."""
    override = os.environ.get("TEMPCYCLE_STATA")
    if override:
        return shutil.which(override) or (override if Path(override).exists() else None)
    for name in STATA_CANDIDATES:
        found = shutil.which(name)
        if found:
            return found
    return None


def stata_log_has_error(log_path):
    """`stata -b` exits 0 even when a do-file fails; a failure leaves a line `r(<code>);`."""
    if not log_path.exists():
        return True
    return any(re.match(r"^r\(\d+\);", line) for line in log_path.read_text(errors="ignore").splitlines())


def run_stata_stage(name, folder, master, stata_exe):
    """Run one master do-file in batch mode from its own folder; return True on success."""
    print(f"\n{'=' * 78}\n>>> Stata stage: {name}\n    ({folder}/{master})\n{'=' * 78}", flush=True)
    t0 = time.time()
    workdir = ROOT / folder
    subprocess.run([stata_exe, "-b", "do", master], cwd=workdir)
    log_path = workdir / (Path(master).stem + ".log")
    ok = not stata_log_has_error(log_path)
    print(f"\n    {'OK' if ok else 'FAILED (see ' + str(log_path) + ')'} ({time.time() - t0:.1f}s)", flush=True)
    return ok


def sync_spain_logs():
    """Copy fresh Spain logs over the shipped ones; say so, since this overwrites them."""
    for src_rel, dst_rel in SPAIN_LOG_SYNC:
        src, dst = ROOT / src_rel, ROOT / dst_rel
        if not src.is_dir():
            continue
        logs = list(src.glob("*.log"))
        for log in logs:
            shutil.copy2(log, dst / log.name)
        print(f"    Replaced {len(logs)} shipped log(s) in {dst_rel}/ with fresh Stata output.")


def run_stata_stages():
    """Run every Stata stage whose prerequisites are present; return (failed, skipped) names."""
    failed, skipped = [], []
    stata_exe = find_stata()
    for name, folder, master, data_marker, env_flag in STATA_STAGES:
        reasons = []
        if stata_exe is None:
            reasons.append("no Stata executable on PATH (set TEMPCYCLE_STATA to override)")
        if data_marker is not None and not data_marker.is_dir():
            reasons.append(f"restricted microdata not found at {data_marker.relative_to(ROOT)}")
        if env_flag is not None and not os.environ.get(env_flag):
            reasons.append(f"environment variable {env_flag} not set (FDZ-only stage)")
        if reasons:
            print(f"\n--- SKIPPED Stata stage: {name}")
            for reason in reasons:
                print(f"    - {reason}")
            print("    Shipped output in data/intermediate/ is used instead.", flush=True)
            skipped.append(name)
            continue
        if run_stata_stage(name, folder, master, stata_exe):
            if name.startswith("Spain"):
                sync_spain_logs()
        else:
            failed.append(name)
    return failed, skipped

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
    print("TempCycle - replication (Stata stage if possible, then Python stage)")
    failed, skipped = [], []

    stata_failed, stata_skipped = run_stata_stages()
    failed.extend(stata_failed)

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

    for name in stata_skipped:
        print(f"  [{'skipped (no Stata/data)':>22}]  Stata stage: {name}")

    if failed:
        print(f"\n{len(failed)} step(s) failed: {', '.join(failed)}")
        sys.exit(1)
    if skipped:
        print(f"\nCompleted. {len(skipped)} Python step(s) skipped for lack of restricted "
              f"microdata; all paper tables were still produced.")
    else:
        print("\nAll steps completed successfully.")


if __name__ == "__main__":
    main()
