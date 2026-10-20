cap log close
log using "$log/034_decomp_prep.log", replace


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation
	
	Do-File for Variance Decomposition with Business
	Cycle Controls.
	
	This do-file processes the dataset of employment spell, generating the
	datasets to be used for the variance decomposition, and merging unemployment,
	real GDP growth and labour market tightness aggregate data.
	
	
	Jenny Peters

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


use "$data/031_decomp_2011.dta", clear


//Outliers
drop if days>365*10&state_c=="TU"&$no_outliers>=1 //spells lasting longer than 10 years
drop if njobs>12&state_c=="TU"&$no_outliers>1

// Business Cycle controls
gen quarter_in = dtin
format quarter_in %td
replace quarter_in = qofd(quarter_in)
format quarter_in %tq


// Creating dummies
quietly tab quarter_in, gen(qin_)
quietly tab yr_begepi, gen(yin_)

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



//do "$prog/071_unemp.do" //creates unemployment rate datasets
//do "$prog/071_gdp_growth.do" //creates gdp growth dataset


// merging with aggregate datasets (BC controls) 
merge m:1 year using "$orig/071_unemp.dta" 
drop if _merge<3 
drop _merge
merge m:1 year using "$orig/071_gdp_growth.dta" //1991-2023
drop if _merge<3 
drop _merge
merge m:1 year using "$orig/071_tightness.dta" //available 2010-2022
drop if _merge<3
drop _merge

sort id dtin dtout

compress
save "$data/034_decomp.dta", replace


clear


log close

