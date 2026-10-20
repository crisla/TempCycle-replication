* 
* Main file for decompostion - Spain, harmonized  with SIAB file
*
* * * * * * * * * *  * * * * * * * * * * * * * * * * * * * * * * * * * * * 

// * Set workign forlder name
// global working_dir = "C:\Users\clm96\Documents\Research\TempCycle\spain\"
// cd ${working_dir}

* Options
* No outliers? change to 1
global no_outliers = 0
* No self-employed, civil servants or discontinous workers? change to 2 
*                                             (1 for >50% self employed)
global strict_cleaning = 1

* End year: spells after this year do not count. Set to 2013 for no censoring.
global end_year = 2021


global current_year = 2011

* Decomposition time * * * * * * * * * * * * * * * * * * * * * * * * * * * 

* Note: the last observation used to be from 1970 onwards
foreach yi in 2011 2005 1999  1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "baseline_SE_21.dta", clear
	run "prep_file_T.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_T_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
	
	* Export Results for plot
	export delimited id n_TC days year_in sex_d age educ2 share_u share_t state_next cause_next type_next days_next using "./rawfiles/duration/dur_`yi'_T_v21.csv", replace
	
}

* Decomposition wihtout outliers * * * * * * * * * * * * * * * * * * * * * * * 

global no_outliers = 2

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "baseline_SE_21.dta", clear
	run "prep_file_T.do"
	di "Done with prep for year ${current_year}, no outliers"
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_noout_T_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close

}

* Revert to default settings
global no_outliers = 0

* By Sex * * * * * * * * * * * * * * * * * * * * * * * * * * * 

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	local sex_dummy = 1
	foreach sex in fem mal{
		use "baseline_SE_21.dta", clear
		run "prep_file_T.do"	
		di "Done with prep for `sex' , year "`"$current_year"'
		
		* Select observations
		keep if sex_d== `sex_dummy'
		
		* Then run decomposition:
		quietly run "decomposition.do"
		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
		* Print results
		log using "./results/results`yi'_`sex'_T_harm.log", replace
		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		log close
		
		* Change variable
		local sex_dummy = `sex_dummy' - 1
	}
	
}

* By Age group * * * * * * * * * * * * * * * * * * * * * * * * * * * 

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	* a) Limit at 40 * * * * * * 
	local bottom_age = 25
	foreach top_age in 40 55{
		* Prepare file
		use "baseline_SE_21.dta", clear
		run "prep_file_T.do"
		di "Done with prep for `top_age' , year "`"$current_year"'
		
		* Select observations
		di "Age bracket: `bottom_age' `top_age' "
		keep if age>=`bottom_age'&age<`top_age'
		
		* Clean up cases with 1 spell left
		egen count_TC = count(id), by(id)
		keep if count_TC==2
		
		* Then run decomposition:
		quietly run "decomposition.do"
		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
		* Print results
		log using "./results/results`yi'_`bottom_age'`top_age'_T_harm.log", replace
		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		log close
		
		* Change variable
		local bottom_age = `top_age'
	}
	* b) Limit at 35 * * * * * * 
	local bottom_age = 25
	foreach top_age in 35 55{
		* Prepare file
		use "baseline_SE_21.dta", clear
		run "prep_file_T.do"
		di "Done with prep for `top_age' , year "`"$current_year"'
		
		* Select observations
		di "Age bracket: `bottom_age' `top_age' "
		keep if age>=`bottom_age'&age<`top_age'
		
		* Clean up cases with 1 spell left
		egen count_TC = count(id), by(id)
		keep if count_TC==2
		
		* Then run decomposition:
		quietly run "decomposition.do"
		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
		* Print results
		log using "./results/results`yi'_`bottom_age'`top_age'_T_harm.log", replace
		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		log close
		
		* Change variable
		local bottom_age = `top_age'
	}
}

* With Age controls * * * * * * * * * * * * * * * * * * * * * * * * * * * 

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "baseline_SE_21.dta", clear
	run "prep_file_T.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition_age.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_age_T_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
}

* By education * * * * * * * * * * * * * * * * * * * * * * * * * * * 

foreach yi in 2011 2005 1996 1999 1992 {
	* Select year
	global current_year = `yi'
	local ed_dummy = 4
	foreach educ in college higher secondary primary{
		* Prepare file
		use "baseline_SE_21.dta", clear
		run "prep_file_T.do"
		di "Done with prep for `educ' , year "`"$current_year"'
		
		* Select observations
		keep if educ2== `ed_dummy'
		
		* Then run decomposition:
		quietly run "decomposition.do"
		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
		* Print results
		log using "./results/results`yi'_`educ'_T_harm.log", replace
		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		log close
		
		* Change variable
		local ed_dummy = `ed_dummy' - 1
	}
	
}

* Non-college together

foreach yi in 2011 2005 1996 1999 1992 {
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "baseline_SE_21.dta", clear
	run "prep_file_T.do"
	di "Done with prep for non-college , year "`"$current_year"'
		
	* Select observations
	keep if educ2 < 4 & educ2!=.
		
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
	* Print results
	log using "./results/results`yi'_nocoll_T_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
	}
	


* Business cycle controls * * * * * * * * * * * * * * * * * * * * * * * * * * * 

quietly do create_cycle_controls.do

local filenames unemp dY yearD qtD
 
foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "baseline_SE_21.dta", clear
	run "prep_file_BC_T.do"
	di "Done with prep for BC, year "`"$current_year"'
	local i = 1
	foreach BC_var in unemp_change gdp_growth yin_* qin_* {
		global BC_Var = "`BC_var'"
		* Then run decomposition:
		run "decomposition_BC.do"
		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
		* Print results
		local filename : word `i' of `filenames'
		log using "./results/results`yi'_`filename'_T_harm.log", replace
		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		log close
		
		* Clean up
		drop mu_i-lpsig_c
		local i = `i' + 1
	}
	
}

* Quits only (both) * * * * * * * * * * * * * * * * * * * * * * * * * * * 


* Note: the last observation used to be from 1970 onwards
foreach yi in 2011 2005 1999  1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "baseline_SE_21.dta", clear
	
	* Generate previous quit variable
	sort id dtin dtout
	by id: gen cause_prev = cause[_n-1]
	* Refresh quit variable
	drop quit
	gen quit = (cause_prev ==51)
	
	* Select observations
	run "prep_file_T.do"
	
	* Select observations with double quits
	egen all_quits = total(quit), by(id)
	keep if all_quits == 2
	
	di "Done with (quit) prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_T_harm_quits.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
	
	
}

* Only with the guys that are NOT in 2011 * * * * * * * * * * * * * * * * * * * * 
*
* Note: the last observation used to be from 1970 onwards

* Select main sample year
global current_year = 2011
	
* Prepare file
use "baseline_SE_21.dta", clear
run "prep_file_T_robust.do"
	
* Then run decomposition:
quietly run "decomposition.do"
quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
* Print results
log using "./results/Over9years1992_T_harm.log", replace
sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
log close

* With time controls (same restricted sample) 

* Prepare file
use "baseline_SE_21.dta", clear
run "prep_file_T_robust.do"
	
* Then run decomposition:

global BC_Var = "yin_*"
* Then run decomposition:
run "decomposition_BC.do"

quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
* Print results
// local filename : word `i' of `filenames'
// log using "./results/results`yi'_`filename'_T_harm.log", replace
sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	

* Shorter time window * * * * * * * * * * * * * * * * * * * * * * * * * * * 

* Note: the last observation used to be from 1970 onwards
foreach yi in 2014 2016{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "baseline_SE_21.dta", clear
	run "prep_file_T.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_T_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
	
	
}