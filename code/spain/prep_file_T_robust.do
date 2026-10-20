// Sample Selection II / / / / / / / / / / / / / / / / / / / / / / / / 

// Selecting only those who are not in the 2011 sample

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
* Time window: no spells finishing before 1992
drop if year_out< 1992
* Time window: no spells after certain year
drop if year_in> $end_year

// Outliers
drop if days>365*10&state_c=="TU"&$no_outliers==1
drop if njobs>12&state_c=="TU"&$no_outliers>1

// Type of worker restrictions
drop if ever_disc==1&$strict_cleaning>0
drop if ever_fun==1&$strict_cleaning>0
drop if ever_se==1&$strict_cleaning==2
drop if share_total_a>0.5&$strict_cleaning==1

// Drop if next spell was a glitch (or retirement)
drop if cause_next==60
drop if cause==58

sort id state_c dtin dtout

// * * Old Robustness case 
// * Mark cases for $current_year
// gen sample_marker = (year_out>=$current_year)
// * Counting number of cycles left - after $current_year
// gen n_TC = (state_c=="TU"&sample_marker)
// by id: replace n_TC = sum(n_TC)
// egen in_last_sample = max(n_TC), by(id)
// * 2 spells in last sample, you are there
// drop if in_last_sample>=2
// drop n_TC

* Generate cycle length variable
by id state_c : gen cycle_length = (dtout - dtout[_n-1])/365 if state_c=="TU"


* Creating time dummies
quietly tab year_in, gen(yin_)
drop yin_1 // multicollinearity safeguard

// Do as normal
by id state_c: gen n_TC = _n if state_c=="TU"
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .

// Keep only the first 2 spells
sort id dtin dtout
keep if n_TC<3&max_TC>1&state_c=="TU"

* Signal all id's that take moore than 9 years to complete 2 spells
replace cycle_length = cycle_length[_n+1] if n_TC==1
keep if cycle_length>9




