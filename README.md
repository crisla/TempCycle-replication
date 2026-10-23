# Replication package

### So alike, yet so different: A non-parametric variance decomposition of unstable employment cycles

Maia Güell (CUNEF Universidad, University of Edinburgh, CEPR, FEDEA, IZA) ·
Cristina Lafuente (University of Bath) ·
Jenny Peters (University of Edinburgh) ·
Hélène Turon (University of Bristol, IZA)

---

## What this package contains

Code and intermediate output to reproduce every table and figure in the paper.

The analysis has two stages. The **Stata stage** turns restricted administrative
microdata into aggregated decomposition and descriptive-statistics output. The
**Python stage** turns that output into the paper's LaTeX tables and figures.

Because the microdata cannot be redistributed, this package ships the
*intermediate* output of the Stata stage. That means **the entire Python stage
runs out of the box, and all paper tables can be rebuilt with no data access
whatsoever.** The Stata code is included for inspection and for anyone who
obtains the microdata themselves; see [`data/raw/README.md`](data/raw/README.md)
for how to request it.

One step is an exception: the Spanish sample-selection estimation reads
individual-level duration extracts and so cannot be re-run without the MCVL. Its
fitted estimates ship pre-computed, and `run_all.py` handles the gap
automatically.

## Quick start

```bash
pip install -r requirements.txt
python run_all.py
```

`run_all.py` is the single entry point. It first tries the **Stata stage**
(Spain, Germany) and then runs the **Python stage**. A Stata stage runs only
if a Stata executable is on `PATH` (or named in `$TEMPCYCLE_STATA`) *and* the
restricted microdata are in place; otherwise it is skipped with a message and
the shipped intermediate output is used. The Germany stage is further opt-in
(`TEMPCYCLE_FDZ=1`), because the SIAB exists only inside the FDZ.

The script exits 0 whenever everything that could run did run. It exits 1 only
if a step that was attempted fails. The skipped Stata stages and the skipped
Spanish sample-selection step are expected without microdata, not failures.

It writes LaTeX tables to `output/tables/` and figures to `output/figures/`
and `output/sample_selection/`.

## Software, runtime and seeds

| | |
|---|---|
| Python | 3.12.9 (run end-to-end on macOS, Darwin 23.4.0) |
| Python packages | pinned in `requirements.txt` |
| Stata | release 17 (`version 17` is set in both master do-files; see note below) |
| Stata user-written packages | none identified in `code/` (a text search for common ssc commands found none) |
| Runtime | about 11 s for the Python stage on a laptop; no special hardware |
| Seeds | `42` in both sample-selection scripts (`np.random.seed(42)` and `seed=42` in the GMM optimiser); the figure scripts use no random draws |

The Stata release for the Spanish pipeline is not recorded in the original
files; `version 17` in `code/spain/master.do` is set to match Germany.

## Repository layout

```
├── run_all.py                  Single entry point: Stata stage (if possible), then Python stage
├── requirements.txt
├── code/
│   ├── germany/                Stata: SIAB pipeline (run inside the FDZ environment)
│   ├── spain/                  Stata: MCVL pipeline
│   │   ├── format_files/       Contract/industry/occupation cleaning
│   │   └── rawfiles/           Raw-file formatting helpers
│   ├── python/                 The seven scripts run_all.py calls (+ plot_atypical.py, see below)
│   └── matlab/                 Early sample-selection simulations (not on the paper path)
├── notebooks/                  Working notebooks mirroring code/python/
├── data/
│   ├── raw/                    EMPTY — restricted microdata goes here; see its README
│   ├── intermediate/           Aggregated Stata output (ships with the package)
│   │   ├── germany/            19 disclosure-cleared .log files
│   │   └── spain/              Decomposition and descriptive-statistics logs
│   └── aggregate/              Public Eurostat / OECD / INE / IMF series
├── output/
│   ├── tables/                 Generated .tex
│   ├── figures/                Generated figures
│   ├── sample_selection/       GMM estimates (.json) and selection figures
│   └── intermediate/           Parsed CSVs written en route to the tables
└── paper/                      Manuscript — added before submission; see its README
```

## Running the Stata stage

Only needed if you have obtained the microdata.

**Germany** — runs inside the FDZ/IAB environment. Set the working directory at
the top of `code/germany/master.do`, place the do-files in that environment's
`prog/` folder, then run `master.do`. It calls, in order: `01_clean.do`,
`02_entire_spells.do`, `03_decomp.do` (which drives the `031`–`044`
`_prep`/`_decomp` pairs), and `05_descriptives.do`. Output is the `.log` files
that correspond to those in `data/intermediate/germany/`.

**Spain** — set `spain_dir` at the top of `code/spain/master.do`, make
`rawfiles/` resolve to your MCVL directory (see
[`data/raw/README.md`](data/raw/README.md)), then run `master.do`. It calls
`main_retro.do` (→ `format_all.do`), `baseline_SE.do`, `Main_harmonized.do` and
`Descriptive_stats_main.do`.

Once either stage has run, return to the repository root and run
`python run_all.py`.

## From code to paper

| Script | Produces | Feeds |
|---|---|---|
| `code/python/results_tables.py` | `output/tables/results_tables.tex` | All variance-decomposition tables: baseline, mostly-temporary, by sex, by age, by education, business-cycle controls, pure/mixed spells, time windows |
| `code/python/descriptive_stats_tables.py` | `output/tables/descriptive_stats_tables.tex` | Duration descriptives, two-or-more-spell sample, binned descriptives |
| `code/python/sample_selection_germany.py` | `output/sample_selection/selection_germany.json` | Discrete 2×2-type GMM, Germany |
| `code/python/sample_selection_spain.py` | `output/sample_selection/selection_spain.json` | Discrete 2×2-type GMM, Spain *(needs MCVL; estimates ship pre-computed)* |
| `code/python/sample_selection_tables.py` | `output/tables/sample_selection_tables.tex` | Sample-selection moments and type-composition tables |
| `code/python/results_interpretation_figures.py` | `output/figures/exp_dur_base_a.png`, `exp_dur_T_a.png`, `het_DD_base_a.png` | Weibull-mixture expected-remaining-duration figures (analytic; built from the shipped logs) |
| `code/python/sample_selection_figures.py` | `output/sample_selection/type_composition_paper_discrete.png`, `type_composition_paper_simple.png`, `type_grid_2x2.png` | Spain type-composition figures, redrawn from `selection_spain.json` (the Germany counterpart is written by `sample_selection_germany.py`) |
| `code/python/plot_atypical.py` | `atypical_incidence_by_year.png` | Figure 1. **Not called by `run_all.py`**: it reads logs not shipped here and uses paths from an older layout |

The notebooks in `notebooks/` are the working copies; the scripts in
`code/python/` are exports of them for headless running. The simulation cells
of `Results Interpretation Figures.ipynb` (calibration check, large hazard
simulation, data-versus-model survival plot) need the individual-level Spanish
duration extract and save no figure used in the paper; they remain in the
notebook only. They are
kept deliberately parallel — **if you change one, change the other.**

Two figures in the paper, the spell-definition and spell-selection schematics,
are hand-drawn illustrations rather than generated output, and are not
reproduced by any code here.

## Method notes worth knowing

**Why "retro" and not "patchwork".** The Spanish panel is built from the single
latest MCVL edition's built-in retrospective history, not from splicing
successive yearly editions. This matches the SIAB's single-year-representative
design, and avoids the spurious employment gaps that splicing introduces — gaps
that this paper's measure would misread as unstable spells.

**Duplicate administrative records.** About nine duplicate pairs (out of ~4.4m
rows) of irreducible MCVL administrative noise are dropped at the very end of
`baseline_SE.do`, immediately before the save. They are dropped there rather
than earlier because the file's own cleaning steps legitimately resolve records
that an early drop would discard. All rows in each ambiguous group are dropped,
rather than `duplicates drop`, which would keep one arbitrarily via an
undocumented sort order.

**Sample.** Workers aged 25–60, excluding the self-employed, civil servants and
apprentices, with at least two completed unstable spells; the first two spells
are used. Baseline N = 81,768 (Germany) and 69,406 (Spain) for the 2011–2021
window.

## Data availability

Neither the SIAB nor the MCVL may be redistributed, and no microdata appears in
this repository. The German `.log` files included here were disclosure-cleared
by the FDZ and approved for publication. The Spanish files included here are
aggregated estimation and descriptive output only. Full details, including the
request process for both sources, are in
[`data/raw/README.md`](data/raw/README.md).

## Contact

For questions about the code, please contact Cristina Lafuente (clm96@bath.ac.uk) or Jenny Peters (jenny.peters@ed.ac.uk).
