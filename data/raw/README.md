# Restricted microdata — how to obtain it and where to put it

**No microdata is distributed with this package.** Both countries' analyses rest
on confidential administrative records that the data providers do not permit us
to redistribute. This file explains what to request, from whom, and exactly
where to place the files so that the code in `code/` runs unmodified.

What *is* distributed is everything downstream of the microdata: the aggregated
Stata output in `data/intermediate/`. That is enough to rebuild every table in
the paper (`python run_all.py`) without any data access at all. You only need
the microdata if you want to re-run the Stata stage from the beginning.

---

## Spain — Muestra Continua de Vidas Laborales (MCVL)

**Provider.** Ministerio de Inclusión, Seguridad Social y Migraciones.

**What to request.** The MCVL *con datos fiscales*, **2021 edition** (`MCVL2021`).
The paper uses the single-edition retrospective history, not a splice of
successive yearly editions — see "Why 'retro' and not 'patchwork'" in the root
`README.md`. You need three component files from that edition:

| Component | Filename in the MCVL delivery |
|---|---|
| Personal records | `MCVL2021PERSONAL_CDF.txt` |
| Benefits / pensions | `MCVL2021PRESTAC_CDF.txt` |
| Affiliation records | `MCVL2021AFILIAD1_CDF.txt` … `MCVL2021AFILIAD4_CDF.txt` |

(Older MCVL editions ship the same content as `PERSANON.trs`, `PREANON.trs` and
`AFILANON<i>.trs`; `code/spain/format_all.do` detects and handles both naming
conventions.)

**How to request it.** Applications go through the Seguridad Social's *Portal del
Dato*, its data platform for academic institutions and researchers
([announcement](https://www.inclusion.gob.es/w/la-seguridad-social-lanza-el-portal-del-dato-dirigido-a-instituciones-e-investigadores)).
Public and private institutions carrying out non-commercial scientific research
on social protection are eligible; the stated purpose may not be commercial.
There are also accredited on-site research rooms in Madrid, Barcelona and
Albacete. **Check the portal for the current form and turnaround before
applying** — the process has changed more than once.

**Where to put the files.**

```
data/raw/spain/rawfiles/2021/MCVL2021PERSONAL_CDF.txt
data/raw/spain/rawfiles/2021/MCVL2021PRESTAC_CDF.txt
data/raw/spain/rawfiles/2021/MCVL2021AFILIAD1_CDF.txt   (… through 4)
```

The Spain do-files use paths relative to their own folder, so before running
them set `spain_dir` at the top of `code/spain/master.do` and make
`rawfiles/` resolve to `data/raw/spain/rawfiles/`. The simplest arrangement on
a machine that has the data is a directory symlink:

```bash
# from the repository root
ln -s ../../../data/raw/spain/rawfiles code/spain/rawfiles
```

**What the pipeline then produces.** `code/spain/main_retro.do` writes the
formatted panel to `rawfiles/MCVL_2021_retro.dta`, and `baseline_SE.do` writes
the estimation sample to `baseline_SE_21.dta` (N = 69,406 for the 2011–2021
window). Neither file may be redistributed.

---

## Germany — Sample of Integrated Labour Market Biographies (SIAB)

**Provider.** Forschungsdatenzentrum (FDZ) of the Bundesagentur für Arbeit at
the Institut für Arbeitsmarkt- und Berufsforschung (IAB).

**What to request.** **SIAB 7521, version 1** (1975–2021).
DOI: [10.5164/IAB.SIAB7521.de.en.v1](https://doi.org/10.5164/IAB.SIAB7521.de.en.v1)

**How to request it.** Submit a data application to the FDZ at
`iab.fdz@iab.de`; access requires project-specific approval and is limited to
non-commercial empirical research by researchers at scientific institutions.
Approval can take around four weeks. Access is **on-site in Nuremberg or at an
FDZ remote-access point**, with remote execution through the JoSuA job-submission
system. The authoritative and current instructions are at
[fdz.iab.de](https://fdz.iab.de/en/startseite-en/).

Note that the SIAB is never delivered to the researcher's own machine. The
Germany do-files in `code/germany/` are written to run **inside** the FDZ
environment, which is why `code/germany/master.do` builds `prog/`, `log/`,
`orig/` and `data/` subfolders and refers to them through globals. The
`.log` files in `data/intermediate/germany/` are the approved, disclosure-cleared
output that the FDZ released to us; they are what the Python stage consumes.

**Where to put the files.** Not applicable on a local machine — the data stay in
the FDZ environment. Place the do-files in that environment's `prog/` folder and
set the working directory at the top of `master.do`.

---

## Disclosure status of what ships here

| Directory | Contents | Status |
|---|---|---|
| `data/intermediate/germany/` | 19 Stata `.log` files | Disclosure-cleared by the FDZ; approved for publication |
| `data/intermediate/spain/results/` | Decomposition output logs | Aggregated estimates only (variance components, N, moments) |
| `data/intermediate/spain/descriptive_stats/` | Descriptive output logs | Aggregated counts and summary statistics only |
| `data/aggregate/` | Eurostat, OECD, INE, IMF series | Public |
| `data/raw/` | — | Empty by design; see above |

Individual-level files are deliberately **excluded**, including the per-spell
duration extracts the Spanish sample-selection step reads
(`dur_<year>_<type>_1obs_unfin_v21.csv`, which carry `id`, `days` and
`jobcount` columns). Because of this, `code/python/sample_selection_spain.py`
cannot be re-run without MCVL access; `run_all.py` detects this, skips the step,
and uses the pre-computed estimates in
`output/sample_selection/selection_spain.json` so the table still builds.
