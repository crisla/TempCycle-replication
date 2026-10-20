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
drop if year_in > 2021

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

log using "./descriptive_stats/Obs_keytab`yy'_`table_type'_f.log", replace
tab max_TC_sample if samesame==1&sex_d==1
log close

log using "./descriptive_stats/Obs_keytab`yy'_`table_type'_m.log", replace
tab max_TC_sample if samesame==1&sex_d==0
log close

restore
}
}

