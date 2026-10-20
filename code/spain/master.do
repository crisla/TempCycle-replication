*
* TempCycle - Spain master do-file
* "So alike, yet so different: A non-parametric variance decomposition of
*  unstable employment cycles" - Güell, Lafuente, Peters, Sánchez, Turon
*
* Runs the full Spain pipeline from formatting the MCVL panel to the
* Stata .log files that the root-level Python scripts parse into the paper
* tables (results_tables.py and descriptive_stats_tables.py).
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* YOU NEED THE MICRODATA TO RUN THIS FILE
* ---------------------------------------
* The MCVL is confidential and is NOT distributed with this replication
* package. Everything downstream of it -- the aggregated .log output this
* pipeline produces -- ships in data/intermediate/spain/, so the paper's
* tables can be rebuilt with `python run_all.py` WITHOUT running this file.
* Run this file only if you have obtained the microdata yourself.
*
* WHAT TO REQUEST
*   Muestra Continua de Vidas Laborales (MCVL) con datos fiscales,
*   2021 edition. Three components are needed:
*       MCVL2021PERSONAL_CDF.txt            (personal records)
*       MCVL2021PRESTAC_CDF.txt             (benefits / pensions)
*       MCVL2021AFILIAD1_CDF.txt .. 4       (affiliation records)
*   Older editions name these PERSANON.trs, PREANON.trs and AFILANON<i>.trs;
*   format_all.do detects and handles both conventions.
*
* WHERE TO REQUEST IT
*   Ministerio de Inclusion, Seguridad Social y Migraciones, through the
*   Seguridad Social "Portal del Dato" (its data platform for academic
*   institutions and researchers). Eligibility is limited to non-commercial
*   scientific research on social protection. Accredited on-site research
*   rooms also exist in Madrid, Barcelona and Albacete. Confirm the current
*   application form and turnaround on the portal before applying.
*   See data/raw/README.md in this package for the full details.
*
* WHERE TO SAVE IT
*   Put the three components in a year-named folder under rawfiles/:
*       <spain_dir>/rawfiles/2021/MCVL2021PERSONAL_CDF.txt
*       <spain_dir>/rawfiles/2021/MCVL2021PRESTAC_CDF.txt
*       <spain_dir>/rawfiles/2021/MCVL2021AFILIAD1_CDF.txt   (through 4)
*   This pipeline then writes, and you must NOT redistribute:
*       <spain_dir>/rawfiles/MCVL_2021_retro.dta   (formatted panel)
*       <spain_dir>/baseline_SE_21.dta             (estimation sample)
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

* Stata release. Set to 17 to match code/germany/master.do; the release the
* Spanish results were originally produced with is not recorded in the
* original files -- confirm before submission.
version 17
clear all
set more off

* ---------------------------------------------------------------------------
* 0. Settings - EDIT THESE
* ---------------------------------------------------------------------------

* Path to this spain/ folder. Must be set: the do-files use relative paths
* (e.g. rawfiles/..., ../../data/aggregate/...) so Stata's working dir has to
* be here. EDIT THIS to the code/spain/ folder of your checkout.
* 2026-10-20: hard-coded placeholder commented out, not deleted. run_all.py
* launches this file from code/spain/, so default to the working directory;
* set the global yourself beforehand to override.
* global spain_dir = "/path/to/TempCycle-replication/code/spain"
if "${spain_dir}" == "" global spain_dir = "`c(pwd)'"
cd "${spain_dir}"

* ---------------------------------------------------------------------------
* 0. Clean dataset
* ---------------------------------------------------------------------------
* clean dataset
run "main_retro.do"

* ---------------------------------------------------------------------------
* 1. Baseline sample
* ---------------------------------------------------------------------------

run "baseline_SE.do"

* ---------------------------------------------------------------------------
* 2. Variance decomposition  ->  results/v21/results*_T_harm.log
* ---------------------------------------------------------------------------
* Main_harmonized.do loops over years and sample splits (no-outliers, by sex,
* by age, by education, business-cycle controls, quits) and writes one log per
* specification. Make sure the output folder exists.

capture mkdir "results"
capture mkdir "results/v21"
run "Main_harmonized.do"
di as txt "Stage 2 done: see results/v21/."

* ---------------------------------------------------------------------------
* 3. Descriptive statistics  ->  descriptive_stats/desstats_*2011.log
* ---------------------------------------------------------------------------
* Descriptive_stats_main.do produces the three logs used by the main paper
* descriptive tables. For the extended/appendix descriptives, additionally run
* Descriptive_stats_other.do (uncomment below).

capture mkdir "descriptive_stats"
run "Descriptive_stats_main.do"
di as txt "Stage 3 done: see descriptive_stats/."


di as txt ""
di as txt "All requested Spain stages complete."
di as txt "Now, from the REPO ROOT, run:"
di as txt "    python run_all.py"

