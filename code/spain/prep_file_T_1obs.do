// Sample Selection II / / / / / / / / / / / / / / / / / / / / / / / / 

// Before dropping: Generate future state variable
sort id jobcount dtin dtout
by id: gen state_next = state_c[_n+1]
by id: gen state_old_next = state[_n+1]

// Generate future cause of end of spell
by id: gen cause_next = cause[_n+1]
gen type_next = 0
by id: replace type_next = 1 if tyco[_n+1]>=300|cause[_n+1]==94
by id: replace type_next = 2 if tyrel[_n+1]==902
by id: replace type_next = 3 if tyrel==930
by id: gen days_next = days[_n+1]
by id: gen year_first = year_in[1]

// Recent spells - WARNING: then the "first" spell won't be the actual first anymore

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

// Counting number of cycles left
sort id state_c dtin dtout
by id state_c: gen n_TC = _n if state_c=="TU"
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .

// Keep only the first spell
sort id dtin dtout
if $unfinished_in==1 {
keep if n_TC==1&state_c=="TU"&(state_next!=""|unfin==1)
}
else {
keep if n_TC==1&state_c=="TU"&state_next!=""
}

// saveold "/share/home/clafuent/TempCycle/two_spell_file"`"$current_year"'"_P.dta", v(12) replace
