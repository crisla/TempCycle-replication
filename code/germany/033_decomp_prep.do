cap log close
log using "$log/033_decomp_prep.log", replace

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation
	
	Do-File for Preparation of SIAB Data for Decomposition by Sex

	This do-file processes the dataset of employment spells, identifying 
	periods of unstable employment and calculating summary statistics across 
	different demographic and temporal dimensions. It also generates the
	datasets to be used for the variance decomposition.
	
	Jenny Peters

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

// creating data file for decomposition (men only)

use "$data/031_decomp_2011.dta", clear
keep if sex_d==0

//Outliers
drop if min_year<2011&$post_2011==1 
drop if days>365*10&state_c=="TU"&$no_outliers>=1 //spells lasting longer than 10 years
drop if njobs>12&state_c=="TU"&$no_outliers>1 //more than 12 jobs per spell

drop n_TC max_TC

// Counting number of cycles left
bysort id: g byte n_TC=_n
order id n_TC days

drop if id==.
sort id n_TC 
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .

// Keep only the first 2 spells
sort id dtin dtout
keep if n_TC<3&max_TC>1&state_c=="TU"


save "$data/033_decomp_m.dta", replace


//--------


// creating data file for decomposition (women only)

use "$data/031_decomp_2011.dta", clear
keep if sex_d==1

//Outliers
drop if min_year<2011&$post_2011==1 
drop if days>365*10&state_c=="TU"&$no_outliers>=1 //spells lasting longer than 10 years
drop if njobs>12&state_c=="TU"&$no_outliers>2

drop n_TC max_TC

// Counting number of cycles left
bysort id: g byte n_TC=_n
order id n_TC days

drop if id==.
sort id n_TC 
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .

// Keep only the first 2 spells
sort id dtin dtout
keep if n_TC<3&max_TC>1&state_c=="TU"


save "$data/033_decomp_w.dta", replace



clear
log close
