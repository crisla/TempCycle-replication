// Sample Selection II / / / / / / / / / / / / / / / / / / / / / / / / 

// Recent spells - WARNING: then the "first" spell won't be the actual first anymore

// Generate future state variable
sort id jobcount dtin dtout
by id: gen state_next = state[_n+1]
by id: gen cause_next = cause[_n+1]
gen type_next = 0
by id: replace type_next = 1 if tyco[_n+1]>=300|cause[_n+1]==94
by id: replace type_next = 2 if tyrel[_n+1]==902
by id: replace type_next = 3 if tyrel==930
by id: gen days_next = days[_n+1]

* Throwing away unfinished spells *
drop if unfin==1
* Time window: no spells originating before $current_year
drop if year_out< $current_year
* Time window: no spells after certain year
drop if year_in> $end_year

// Outliers
drop if days>365*10&state_c=="TU"&$no_outliers==1
drop if njobs>12&state_c=="TU"&$no_outliers==1

// Type of worker restrictions
drop if ever_disc==1&$strict_cleaning>0
drop if ever_fun==1&$strict_cleaning>0
drop if ever_se==1&$strict_cleaning==2
drop if share_total_a>0.5&$strict_cleaning==1

// Drop if next spell was a glitch (or retirement)
drop if cause_next==60
drop if cause==58

* Creating variables for the merge
gen quarter_in = dtin
format quarter_in %td
replace quarter_in = qofd(quarter_in)
format quarter_in %tq

// Business Cycle controls
// capture drop _merge
merge m:1 year_in using "cycle_controls.dta"
// drop if _merge !=3 | unemp_change==.
drop _merge

// * Merging GDP growth
// capture drop _merge
// merge m:1 year_in using "cycle_controls_gdp.dta"
// // drop if _merge !=3 | gdp_growth==.
// drop _merge

* Creating dummies
quietly tab quarter_in, gen(qin_)
quietly tab year_in, gen(yin_)

drop qin_1 yin_1 // multicollinearity safeguard

// Counting number of cycles left
sort id state_c dtin dtout
by id state_c: gen n_TC = _n if state_c=="TU"
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .

// Keep only the first 2 spells
sort id dtin dtout
keep if n_TC<3&max_TC>1&state_c=="TU"

