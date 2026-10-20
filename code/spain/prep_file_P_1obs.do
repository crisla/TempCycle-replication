// Sample Selection II / / / / / / / / / / / / / / / / / / / / / / / / 

// Before dropping: Generate future state variable
sort id jobcount dtin dtout
by id: gen state_next = state_c[_n+1]
by id: gen state_old_next = state[_n+1]
by id: gen year_first = year_in[1]

// Recent spells - WARNING: then the "first" spell won't be the actual first anymore

* Time window: no spells originating before $current_year
drop if year_out< $current_year
* Time window: no spells after certain year
drop if year_in> $end_year

// Outliers
drop if days>365*10&state_c=="TU"&$no_outliers==1
drop if njobs>12&state_c=="TU"&$no_outliers==1

// Strict cleaning
* No funky admin business
drop if cause==60
* No discontinuous workers
drop if $strict_cleaning > 0 & tyco>=300
drop if $strict_cleaning > 0 & cause==94
* No interinos
drop if $strict_cleaning > 1 & tyrel==902
* No coop workers
drop if $strict_cleaning > 1 & tyrel==930

// Type of worker restrictions
drop if ever_disc==1&$strict_cleaning>0
drop if ever_fun==1&$strict_cleaning>0
drop if ever_se==1&$strict_cleaning==2
drop if share_total_a>0.5&$strict_cleaning==1

// Counting number of cycles left
sort id state_c dtin dtout
by id state_c: gen n_PC = _n if state_c=="P"
by id state_c: gen n_TU = _n if state_c=="TU"
egen max_PC = max(n_PC), by(id)
egen max_TU = max(n_TU), by(id)
replace max_PC = 0 if max_PC == .
replace max_TU = 0 if max_TU == .

// For now we keep the first spell
sort id dtin dtout
if $unfinished_in==1 {
keep if n_PC==1&state_c=="P"&(state_next!=""|unfin==1)
}
else {
keep if n_PC==1&state_c=="P"&state_next!=""
// Take out people that never have had an unstable job
drop if max_TU<1
}

// saveold "/share/home/clafuent/TempCycle/two_spell_file"`"$current_year"'"_P.dta", v(12) replace
