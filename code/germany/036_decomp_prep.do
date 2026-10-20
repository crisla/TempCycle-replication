cap log close
log using "$log/036_decomp_prep.log", replace


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation
	
	Do-File for Preparation of SIAB Data for Decomposition - only temp contracts.
	
	Jenny Peters

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


use "$data/031_decomp_2011.dta", clear

keep if fixed_term==1

//Outliers
drop if days>365*10&state_c=="TU"&$no_outliers>=1 //spells lasting longer than 10 years
drop if njobs>12&state_c=="TU"&$no_outliers>1

// Counting number of cycles left
drop n_TC max_TC
bysort id: g byte n_TC=_n
order id n_TC days

drop if id==.
sort id n_TC 
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .

// Keep only the first 2 spells
sort id dtin dtout
keep if n_TC<3&max_TC>1&state_c=="TU"


compress
save "$data/036_decomp.dta", replace


clear
log close

