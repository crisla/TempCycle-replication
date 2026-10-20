*
* Unstable Employment Cycles - Descriptive Statistics, Spain (replication package)
*
* Generates the two descriptive statistics tables in the paper:
*
*   Table tab:desstats_2+spell  "Descriptive Statistics"
*     Individual-level characteristics for the sample with 2+ completed unstable spells
*     Output logs:
*       descriptive_stats/desstats_sple_id_basic2011.log  (age, sex, foreign, N_S, N_U)
*       descriptive_stats/desstats_sple_id_educ2011.log   (education breakdown)
*
*   Table tab:desstats_dur  "Descriptive Statistics: Duration unstable spells"
*     Spell-level duration statistics for unstable spells
*     Output log:
*       descriptive_stats/desstats_sple_spells_states2011.log
*
* Sample: individuals with 2+ completed unstable spells, Spain, year_out >= 2011
* Data:   baseline_SE_21.dta
*
* For additional descriptive statistics (not in the paper), see Descriptive_stats_other.do
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
global end_year = 2021

clear
use "baseline_SE_21.dta"

sort id jobcount dtin

// Age groups
drop age_d_*
gen age_d_young  = (age < 35)
gen age_d_middle = (age >= 35 & age < 50)
gen age_d_old    = (age >= 50)

// Foreign born
gen foreign = (nationality != "N00")

// Samesame: flag last record per individual (for individual-level stats)
gen samesame = (id != id[_n+1])

// Replace NoU for descriptive stats
sort id jobcount dtin dtout
replace NoU = NoU[_n-1] if id == id[_n-1] & NoU[_n-1] > 0

// Spell-level duration variables
gen days_if_P  = days if state_c == "P"
gen days_if_TU = days if state_c == "TU"

// Cumulative TU days per individual
by id: gen days_tu = sum(days_if_TU)

// Sequence number of TU and PC cycles per individual (used for N_S, N_U)
sort id state_c dtin dtout
by id state_c: gen n_TC = _n if state_c == "TU"
by id state_c: gen n_PC = _n if state_c == "P"

sort id jobcount dtin dtout
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .
egen max_PC = max(n_PC), by(id)
replace max_PC = 0 if max_PC == .

by id: replace n_PC = n_PC[_n-1] if n_PC == .
by id: replace n_TC = n_TC[_n-1] if n_TC == .
replace n_PC = 0 if n_PC == .
replace n_TC = 0 if n_TC == .

// Variables for sample selection (harmonised with Germany)
sort id jobcount dtin dtout
by id: gen last_year   = year(dtout[_N])
by id: gen state_next  = state[_n+1]
by id: gen cause_next  = cause[_n+1]
gen type_next = 0
by id: replace type_next = 1 if tyco[_n+1] >= 300 | cause[_n+1] == 94
by id: replace type_next = 2 if tyrel[_n+1] == 902
by id: replace type_next = 3 if tyrel == 930

// drop share_total_a
// egen share_total_a = max(days_a / work_exp), by(id)

// Drop unfinished spells and spells starting after 2020
drop if unfin == 1 & samesame == 0
drop if year_in > $end_year

global strict_cleaning = 1

// --------------------------------------------------------------------------
// Sample: Spain 2011 onwards (matching Germany's 2011-2021 window)
// --------------------------------------------------------------------------

preserve

* Time window: keep only spells finishing in or after 2011
drop if year_out < 2011

* Worker type restrictions
drop if ever_disc == 1 & $strict_cleaning > 0   // no discontinuous workers
drop if ever_fun  == 1 & $strict_cleaning > 0   // no civil servants
drop if ever_se   == 1 & $strict_cleaning == 2  // no self-employed (strict mode only)
drop if share_total_a > 0.5 & $strict_cleaning == 1  // drop if mostly self-employed

* Drop spells where the next transition was a data glitch
drop if cause_next == 60
drop if cause == 58

* Count completed unstable (TU) spells per individual
sort id state_c dtin dtout
by id state_c: gen n_TC_sample = _n if state_c == "TU"

* Correction for unfinished spells (don't count them as completed)
gen unfinTC = (state_c == "TU" & unfin == 1)
replace n_TC_sample = n_TC_sample - 1 if unfinTC == 1

* Classify individuals: 0, 1, or 2+ completed unstable spells
* (0.5 and 1.5 capture those with only unfinished spells in a given category)
egen max_TC_sample = max(n_TC_sample), by(id)
replace max_TC_sample = 0 if max_TC_sample == .
replace max_TC_sample = 2 if max_TC_sample > 2

egen OnlyOneUnfinTC  = max(unfinTC), by(id)
gen  OneAndOneUnfinTC = OnlyOneUnfinTC
replace OnlyOneUnfinTC   = 0 if max_TC_sample > 0
replace OneAndOneUnfinTC = 0 if max_TC_sample != 1
replace max_TC_sample = 0.5 if OnlyOneUnfinTC   == 1
replace max_TC_sample = 1.5 if OneAndOneUnfinTC == 1

* Refresh samesame after dropping rows
sort id dtin dtout
drop samesame
gen samesame = (id != id[_n+1])

// --------------------------------------------------------------------------
// Table tab:desstats_2+spell — "Descriptive Statistics"
// --------------------------------------------------------------------------

* Individual demographics and spell counts
* Columns: age, sex (female=1), foreign born, N_S (stable spells), N_U (unstable spells)
* Focus on max_TC_sample == 2 group (individuals with 2+ completed unstable spells)
log using "./descriptive_stats/desstats_sple_id_basic2011.log", replace
tabstat age sex_d foreign n_PC n_TC_sample days_p_all days_tu if samesame == 1, ///
    by(max_TC_sample) statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

* Education breakdown (educ2: 1=Primary, 2=Lower Secondary, 3=Upper Secondary, 4=College)
log using "./descriptive_stats/desstats_sple_id_educ2011.log", replace
tab educ2 max_TC_sample if samesame == 1, column
log close

// --------------------------------------------------------------------------
// Table 2b (tab:desstats_all): 3-bin "classic" collapse for the whole-sample
// breakdown by number of completed cycles (0/1/2, incl. never-unstable).
// Non-destructive relabelling only (no rows dropped): 0.5 -> 0, 1.5 -> 1.
// Bin 2 is untouched, so Tables 1/2 (which only use max_TC_sample==2) are
// unaffected by this collapse either way.
// --------------------------------------------------------------------------
gen max_TC_sample_classic = max_TC_sample
replace max_TC_sample_classic = 0 if max_TC_sample_classic == 0.5
replace max_TC_sample_classic = 1 if max_TC_sample_classic == 1.5

log using "./descriptive_stats/desstats_sple_id_basic2011_classic.log", replace
tabstat age sex_d foreign n_PC n_TC_sample days_p_all days_tu if samesame == 1, ///
    by(max_TC_sample_classic) statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

log using "./descriptive_stats/desstats_sple_id_educ2011_classic.log", replace
tab educ2 max_TC_sample_classic if samesame == 1, column
log close

// --------------------------------------------------------------------------
// Table tab:desstats_dur — "Descriptive Statistics: Duration unstable spells"
// --------------------------------------------------------------------------

* Spell-level duration of permanent (P) and unstable (TU) spells
* For the paper: use max_TC_sample == 2 group, TU column
log using "./descriptive_stats/desstats_sple_spells_states2011.log", replace
tabstat days_if_P days_if_TU, by(max_TC_sample) ///
    statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

// --------------------------------------------------------------------------
// Table: Industry of last employment (appendix)
// --------------------------------------------------------------------------
* 3-bin "short" collapse: exclude never-unstable, fold unfinished-only into 0
gen max_TC_sample_short = max_TC_sample
drop if max_TC_sample_short == 0
replace max_TC_sample_short = 0 if max_TC_sample_short == 0.5
replace max_TC_sample_short = 1 if max_TC_sample_short < 2 & max_TC_sample_short > 0

log using "./descriptive_stats/desstats_sple_id_ind2011_short.log", replace
tab ind_short max_TC_sample_short if samesame == 1, column
log close

restore
