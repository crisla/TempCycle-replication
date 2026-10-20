*
* Unstable Employment Cycles - Additional Descriptive Statistics, Spain (lean)
*
* This file is the full original version of Descriptive_stats_main.do, retained
* for reference and potential future use (e.g. if reviewers request additional
* descriptives). It is NOT part of the replication package.
*
* For the tables that appear in the paper, see Descriptive_stats_main.do.
*
* Changes from Descriptive_stats_other.do:
*   - max_TC_sample uses 3 bins (0, 1, 2) to match Germany's 05_descriptives.do
*     (the 5-bin 0/0.5/1/1.5/2 split is removed)
*   - The two foreach yy loops are merged into one single pass
*   - The inner classic/short loop is removed (replaced by the 3-bin approach)
*   - Bug fixes: stale `s' macro outside foreach s loop, unlogged tabstat,
*     and misnamed desstats_all_spells_states99.log (which logged educ, not states)
*   - Unused variables (post08, pre08) not generated
*
* Changes from Descriptive_stats_other_lean.do:
*   - Added Section at the end: incidence of temporary employment by year,
*     adapted from Germany's 05_descriptives-5.do (lines 289-386).
*     Produces ./descriptive_stats/incidence_atypical_by_year.log
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Structure of file:
* -------------------
* This first part uses the raw spells of all the invididuals.
* Then I load the "baseline" file with unstable spells already formed, no
* retirement spells and age restricted to 25 to 50 years old. Then
* there is a variable that partitions the sample into 2+ completed spells,
* just one or none.
*
* The descriptive stats are key demographics: age, sex, education
* Then also industry of last employment, number and length of spells of
* each labour state. Crossing industry and length of spell results in
* fascinating statistics!
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
global end_year = 2021

clear
use "rawfiles/MCVL_2021.dta"


// Format variables / / / / / / / / / / / / / / / / / / / / / / / /

// Make sex dummy more traditional
capture drop sex_d
* Dummy for sex (1 is female)
gen sex_d = 0 if sex==1
replace sex_d = 1 if sex_d==.

// Age groups
gen age_d_young  = (age<35)
gen age_d_middle = (age>=35&age<50)
gen age_d_old    = (age>=50)

// Foreign born
gen foreign = (nationality!="N00")

// Part-time dummy
gen part_time = 0
replace part_time = 1 if part == 2           // by type of contract, it is part-time
replace part_time = 1 if part == . & cop<1 & state!="U" // by number of hours

// Work experience
by id: gen work_exp = sum(days)
by id: replace work_exp = work_exp[_N]

// Public servant dummy
gen pub_serv = (tyrel>=900&tyrel<911)

// Discontinous worker dummy
gen fijo_disc = (tyco>=300&tyco<400)

// No negative spells
drop if days<0

// No civil servants (not even a day)
sort id dtin dtout
gen days_fun = 0
replace days_fun = days if pub_serv==1
by id: replace days_fun = sum(days_fun)
by id: gen ever_fun = (days_fun[_N]>0)

// Share of working life in each contract
gen days_t = 0
replace days_t = days if state=="T"
by id: replace days_t = sum(days_t)

gen days_p = 0
replace days_p = days if state=="P"
by id: replace days_p = sum(days_p)

// No discontinuous workers (not even a day)
gen days_disc = 0
replace days_disc = days if fijo_disc==1
by id: replace days_disc = sum(days_disc)
by id: gen ever_disc = (days_disc[_N]>0)

// No self employed (not even a day)
gen days_a = 0
replace days_a = days if state=="A"
by id: replace days_a = sum(days_a)
by id: gen ever_se = (days_a[_N]>0)

// Unemployment exposure
gen days_u = 0
replace days_u = days if state=="U"
by id: replace days_u = sum(days_u)
by id: gen ever_u = (days_u[_N]>0)

// Counting days
gen share_total_a   = days_a/work_exp
gen share_total_t   = days_t/work_exp
gen share_total_p   = days_p/work_exp
gen share_total_u   = days_u/work_exp
gen share_total_fun = days_fun/work_exp

// Days if in a certain state
gen days_if_P = days if state=="P"
gen days_if_T = days if state=="T"
gen days_if_U = days if state=="U"

// Replace NoU for descriptive stats
sort id jobcount dtin dtout
replace NoU = NoU[_n-1] if id==id[_n-1]&NoU[_n-1]>0

// Formating  education
replace education = "0" if education=="C0"
destring(education), replace
gen educ2 = .
* 1: less than primary studies
replace educ2 = 1 if education <30
* 2: less than secondary studies/primary studies and some more
* (graduado escolar + FP basic)
replace educ2 = 2 if education >=30 & education <40
* 3: Secondary studies
* (FP Superior + Bachiller + BUP)
replace educ2 = 3 if education >=40 & education <44
* 4: College and beyond
replace educ2 = 4 if education >=44 & education <50

// Sample Selection / / / / / / / / / / / / / / / / / /

gen year_in  = year(dtin)
gen year_out = year(dtout)

// Non-retired (or about to)
drop if state=="R"
// Between 25 and 55s
replace age = year_in - year(dtbirth)
drop if age<16
//drop if age<25|age>=55

// Basic descriptives / / / / / / / / / / / / / /

* Samesame: identify individuals, no spells
gen samesame = (id!=id[_n+1])

sort id jobcount dtin

log using "./descriptive_stats/desstats_all_id_basic.log", replace
tabstat age sex_d foreign NoP NoT NoU days_p days_t days_u if samesame==1, ///
    statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

log using "./descriptive_stats/desstats_all_id_educ.log", replace
tab educ2 if samesame==1
log close

log using "./descriptive_stats/desstats_all_id_agegroups.log", replace
tabstat age_d_* if samesame==1
log close

log using "./descriptive_stats/desstats_all_id_ind.log", replace
tab ind_short if samesame==1
log close

* Spell-based stats

log using "./descriptive_stats/desstats_all_spells_basic.log", replace
tabstat age sex_d if samesame==1, statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

log using "./descriptive_stats/desstats_all_spells_states.log", replace
tabstat days_if_P days_if_T days_if_U, statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

log using "./descriptive_stats/desstats_all_spells_ind.log", replace
tab ind_short
log close

foreach s in "P" "T" "U" {
    log using "./descriptive_stats/desstats_all_spells_ind_dur`s'.log", replace
    tab ind_short, sum(days_if_`s')
    log close
}


* -----------------------------------------------------------------------------
* Second part: selected sample harmonised to be like in Germany
* -----------------------------------------------------------------------------
* Prep: this would correspond to prep_file_T.do
use "baseline_SE_21.dta", clear

sort id jobcount dtin

// Age groups
drop age_d_*
gen age_d_young  = (age<35)
gen age_d_middle = (age>=35&age<50)
gen age_d_old    = (age>=50)

// Foreign born
gen foreign = (nationality!="N00")

* Samesame: identify individuals, no spells
gen samesame = (id!=id[_n+1])

// Replace NoU for descriptive stats
sort id jobcount dtin dtout
replace NoU = NoU[_n-1] if id==id[_n-1]&NoU[_n-1]>0

// Days if in a certain state
gen days_if_P  = days if state_c=="P"
gen days_if_TU = days if state_c=="TU"

by id: gen days_tu = sum(days_if_TU)

// Counting number of cycles left
sort id state_c dtin dtout
by id state_c: gen n_TC = _n if state_c=="TU"
by id state_c: gen n_PC = _n if state_c=="P"

sort id jobcount dtin dtout
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .
egen max_PC = max(n_PC), by(id)
replace max_PC = 0 if max_PC == .

by id: replace n_PC = n_PC[_n-1] if n_PC==.
by id: replace n_TC = n_TC[_n-1] if n_TC==.
replace n_PC = 0 if n_PC==.
replace n_TC = 0 if n_TC==.

// Sample selection to harmonise with Germany data ------------------------
// Generate future state variable
sort id jobcount dtin dtout
by id: gen last_year  = year(dtout[_N])
by id: gen state_next = state[_n+1]
by id: gen cause_next = cause[_n+1]
gen type_next = 0
by id: replace type_next = 1 if tyco[_n+1]>=300|cause[_n+1]==94
by id: replace type_next = 2 if tyrel[_n+1]==902
by id: replace type_next = 3 if tyrel==930

// How many start from TU versus P in the admin data?
// foreach yy in 2011 2005 1999 1992 {
// 	preserve
// 	drop if year_out< `yy'
// 	tab state_c if samesame[_n-1]==1
// 	restore
// }

// drop share_total_a
// egen share_total_a = max(days_a/work_exp), by(id)

// --------------------------------------------------------------------------
// Tables with ALL The spells (for sample selection) ------------------------
// --------------------------------------------------------------------------
* Keeping unfinished spells *
drop if unfin==1&samesame==0

* Time window: no spells after certain year
drop if year_in > $end_year

global strict_cleaning = 1

* Saving data for different years
tempfile base_data
save `base_data'

// We are going to repeat the analysis for each year window 1999 1992 
foreach yy in 2011 2005 1999 1992{
use `base_data', clear

* Time window: no spells finishing before $current_year
drop if year_out < `yy'

// Outliers
// drop if days>365*10&state_c=="TU"
// drop if njobs>12&state_c=="TU"

// Type of worker restrictions
drop if ever_disc==1&$strict_cleaning>0
drop if ever_fun==1&$strict_cleaning>0
drop if ever_se==1&$strict_cleaning==2
drop if share_total_a>0.5&$strict_cleaning==1

// Drop if next spell was a glitch (or retirement)
drop if cause_next==60
drop if cause==58

// Counting number of cycles left
sort id state_c dtin dtout
by id state_c: gen n_TC_sample = _n if state_c=="TU"

* Correction for unfinished spells
gen unfinTC = (state_c=="TU"&unfin==1)
replace n_TC_sample = n_TC_sample-1 if unfinTC==1

* Separating cases with no unstable spells ever
* -------------------------------------------
* This is because for robustness (and sample selection) it might be good to
* keep track of those who never had any unstable spell in the current sample
* window. This is the table_type "classic". The one where they are excluded
* is "short". We generate tables separately for each
*
egen max_TC_sample = max(n_TC_sample), by(id)
replace max_TC_sample = 0 if max_TC_sample ==.
replace max_TC_sample = 2 if max_TC_sample>2

* Separate cases
egen OnlyOneUnfinTC = max(unfinTC), by(id)
gen OneAndOneUnfinTC = OnlyOneUnfinTC
replace OnlyOneUnfinTC = 0 if max_TC_sample>0
replace OneAndOneUnfinTC = 0 if (max_TC_sample!=1)
replace max_TC_sample = 0.5 if  OnlyOneUnfinTC==1 // one unfinished unstable (0)
replace max_TC_sample = 1.5 if  OneAndOneUnfinTC==1 // one finished and one unfinished (1)

* Samesame: identify individuals, no spells
sort id dtin dtout
drop samesame
gen samesame =(id!=id[_n+1])

// Observation Breakdown Table / / / / / / / / / / / / / / / / / / /

log using "./descriptive_stats/Obs_keytab`yy'.log", replace
tab max_TC_sample if samesame==1
log close

// / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /

gen max_TC_sample_d = max_TC_sample

foreach table_type in classic short long{

preserve

if "`table_type'" == "classic"{

		* People with no unstable spells ever included, 3 bins

		replace max_TC_sample = 0 if max_TC_sample_d==0|max_TC_sample_d==0.5
		replace max_TC_sample = 1 if max_TC_sample_d==1|max_TC_sample_d==1.5
		

	}
	else if "`table_type'" == "short" {

		* People with no unstable spells ever excluded, 3 bins

		replace max_TC_sample = max_TC_sample_d
		* Reset to previous case: drop never in usntable
		drop if max_TC_sample == 0
		replace max_TC_sample = 0 if max_TC_sample == 0.5

		* Consider all other cases 1
		replace max_TC_sample = 1 if max_TC_sample<2&max_TC_sample>0

	}

	else {

		* People with no unstable spells ever included, 5 bins

	}


* Reset samesame just in case
sort id dtin dtout
drop samesame
gen samesame =(id!=id[_n+1])

* "Flows"
gen flow = state + state_next

// / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
// Descriptive tables for each time window

// Observation Breakdown Table / / / / / / / / / / / / / / / / / / /

log using "./descriptive_stats/Obs_keytab`yy'_`table_type'.log", replace
tab max_TC_sample if samesame==1
log close

log using "./descriptive_stats/desstats_sple_flow`yy'_`table_type'.log", replace
tab flow if samesame==0&max_TC_sample==2
log close

log using "./descriptive_stats/desstats_sple_keytab`yy'_`table_type'.log", replace
tab max_TC_sample if samesame==1
log close

log using "./descriptive_stats/desstats_sple_keytab`yy'_v20_`table_type'.log", replace
tab max_TC_sample if samesame==1&last_year>=2011
log close

log using "./descriptive_stats/desstats_sple_id_basic`yy'_`table_type'.log", replace
tabstat age sex_d foreign n_PC n_TC_sample days_p days_tu if samesame==1, ///
    by(max_TC_sample) statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

log using "./descriptive_stats/desstats_sple_id_agegroup`yy'_`table_type'.log", replace
tabstat age_d_* if samesame==1, by(max_TC_sample)
log close

log using "./descriptive_stats/desstats_sple_id_educ`yy'_`table_type'.log", replace
tab educ2 max_TC_sample if samesame==1, column
log close

log using "./descriptive_stats/desstats_sple_id_ind`yy'_`table_type'.log", replace
tab ind_short max_TC_sample if samesame==1, column
log close

* Spell-based stats

log using "./descriptive_stats/desstats_spell_shares`yy'_`table_type'.log", replace
tabstat share_u share_t if state_c=="TU"&max_TC_sample==2&n_TC_sample<3, ///
    statistics(mean sd p10 p25 p50 p75 p90 n)
log close

log using "./descriptive_stats/desstats_sple_spells_basic`yy'_`table_type'.log", replace
tabstat age sex_d foreign, by(max_TC_sample) statistics(mean sd)
log close

log using "./descriptive_stats/desstats_sple_spells_states`yy'_`table_type'.log", replace
tabstat days_if_P days_if_TU, by(max_TC_sample) ///
    statistics(mean sd min p10 p25 p50 p75 p90 max n)
log close

log using "./descriptive_stats/desstats_sple_spells_educ`yy'_`table_type'.log", replace
tab educ2 max_TC_sample, column
log close

log using "./descriptive_stats/desstats_sple_spells_ind`yy'_`table_type'.log", replace
tab ind_short max_TC_sample, column
log close

foreach s in "P" "TU" {
    log using "./descriptive_stats/desstats_sple_spells_ind_dur`s'`yy'_`table_type'.log", replace
    tab ind_short, sum(days_if_`s')
    log close
}

log using "./descriptive_stats/desstats_sple_spells_bystate`yy'_`table_type'.log", replace
tabstat age sex_d foreign, by(state_c) statistics(mean sd)
log close

restore
}
}


* =============================================================================
* Incidence of temporary employment by year
* Adapted from Germany's 05_descriptives-5.do (lines 289-386)
*
* Method: turn spells into a stock measure, compute the monthly share of
* temporary employment among all employed (P+T), then average those monthly
* shares within each calendar year.
*
* Germany definition of "atypical": fixed-term or marginal part-time jobs
*   (employment_status==109|209 or fixed_term==1).
* Spain equivalent used here: temporary contracts (state=="T").
* =============================================================================

use "baseline_SE_21.dta", clear

* Define atypical (temporary) employment: state=="T" in the MCVL
gen atypical = (state == "T")

* Keep only employed spells (permanent P or temporary T)
* (equivalent to Germany's keep if state==2|state==3)
keep if state == "P" | state == "T"

* Drop spells with negative or zero duration
drop if days<0

* To match Germany, keep only spells on or after 2011
keep if year_out>=2011

gen cdtin = max(dtin, td(01jan2011))
format cdtin %td

gen cdtout = min(dtout, td(31dec2021))
format cdtout %td


* Monthly index for start/end of each spell
gen int m_in  = mofd(cdtin)
gen int m_out = mofd(cdtout)

* Number of months each spell is active
gen int nmonths = m_out - m_in + 1

* Expand each spell into one row per active month
expand nmonths

* Assign calendar month to each expanded row
bysort id cdtin cdtout: gen int m = m_in + _n - 1
format m %tm

* Collapse to person-month level
* (max: if a person holds any temporary job in month m, they are atypical)
collapse (max) atypical, by(id m)

* Calendar year
gen int year = yofd(dofm(m))

* Yearly averages: share of atypical among all employed person-months + N
* (means are shares because atypical is 0/1 and denominator is all employed
* person-months in that year)
collapse (mean) atypical (count) N = atypical, by(year)

* ---------------------------------------------------------------
* Table: share of temporary employment in all employment by year
* ---------------------------------------------------------------

log using "./descriptive_stats/incidence_atypical_by_year.log", replace
list year atypical N
log close
