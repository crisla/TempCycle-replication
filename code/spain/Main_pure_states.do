* 
* Main file for decompostion - Spain
*
* * * * * * * * * *  * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Set workign forlder name
*global working_dir = "C:\Users\lafuentemart\Documents\TempCycle\spain"
*cd ${working_dir}

* Options
* No outliers? change to 1
global no_outliers = 0
* No self-employed, civil servants or discontinous workers? change to 2 
*                                             (1 for >50% self employed)
global strict_cleaning = 1

* End year: spells after this year do not count. Set to last sample year for no censoring.
global end_year = 2020

* Decomposition time (only T) * * * * * * * * * * * * * * * * * * * * * * * * 

global onlyT = 1
global onlyU = 0
global someT = 0
global onlyMixed = 0
global nopureT = 0

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prapre file
	use "baseline_SE_21.dta", clear
	run "prep_file_onlyT.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_onlyT_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
}

* Decomposition time (only U) * * * * * * * * * * * * * * * * * * * * * * * * 

global onlyT = 0
global onlyU = 1
global someT = 0
global onlyMixed = 0
global nopureT = 0

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prapre file
	use "baseline_SE_21.dta", clear
	run "prep_file_onlyT.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_onlyU_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
}

* Decomposition time (some T) * * * * * * * * * * * * * * * * * * * * * * * * 

global onlyT = 0
global onlyU = 0
global someT = 1
global nopureT = 0

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prapre file
	use "baseline_SE_21.dta", clear
	quietly run "prep_file_onlyT.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_someT_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
}

global onlyT = 0
global onlyU = 0
global someT = 2
global nopureT = 0

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prapre file
	use "baseline_SE_21.dta", clear
	quietly run "prep_file_onlyT.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_mostlyT_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
}


* Decomposition time (no pure T) * * * * * * * * * * * * * * * * * * * * * * * * 

global onlyT = 0
global onlyU = 0
global someT = 0
global nopureT = 1

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prapre file
	use "baseline_SE_21.dta", clear
	quietly run "prep_file_onlyT.do"
	di "Done with prep for year "`"$current_year"'
	
	* Then run decomposition:
	quietly run "decomposition.do"
	quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
	
	* Print results
	log using "./results/results`yi'_nopureT_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
}

* By Sex * * * * * * * * * * * * * * * * * * * * * * * * * * * 

global onlyT = 1
global onlyU = 0
global onlyMixed = 0
global nopureT = 0

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	local sex_dummy = 1
	foreach sex in fem mal{
		* Prepare file
		use "baseline_SE_21.dta", clear
		run "prep_file_onlyT.do"
		di "Done with prep for `sex' , year "`"$current_year"'
		
		* Select observations
		keep if sex_d== `sex_dummy'
		
		* Then run decomposition:
		quietly run "decomposition.do"
		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
		* Print results
		log using "./results/results`yi'_`sex'_onlyT_harm.log", replace
		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		log close
		
		* Change variable
		local sex_dummy = `sex_dummy' - 1
	}
	
}

* Only U

global onlyT = 0
global onlyU = 1
global onlyMixed = 0
global nopureT = 0

foreach yi in 2011 2005 1996 1999 1992{
	* Select year
	global current_year = `yi'
	local sex_dummy = 1
	foreach sex in fem mal{
		* Prepare file
		use "baseline_SE_21.dta", clear
		run "prep_file_onlyT.do"
		di "Done with prep for `sex' , year "`"$current_year"'
		
		* Select observations
		keep if sex_d== `sex_dummy'
		
		* Then run decomposition:
		quietly run "decomposition.do"
		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
		
		* Print results
		log using "./results/results`yi'_`sex'_onlyU_harm.log", replace
		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		log close
		
		* Change variable
		local sex_dummy = `sex_dummy' - 1
	}
	
}

* By education * * * * * * * * * * * * * * * * * * * * * * * * * * * 

global onlyT = 1
global onlyU = 0
global onlyMixed = 0
global nopureT = 0

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
		log using "./results/results`yi'_`educ'_onlyT_harm.log", replace
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
	log using "./results/results`yi'_nocoll_onlyT_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
	}

* Only U

global onlyT = 0
global onlyU = 1
global onlyMixed = 0
global nopureT = 0

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
		log using "./results/results`yi'_`educ'_onlyU_harm.log", replace
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
	log using "./results/results`yi'_nocoll_onlyU_harm.log", replace
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
	log close
	}

// * Business cycle controls * * * * * * * * * * * * * * * * * * * * * * * * * * * 
//
// global onlyT = 1
// global onlyU = 0
//
// local filenames unemp yearD qtD
// 
// foreach yi in 2011 2005 1996 1999 1992{
// 	* Select year
// 	global current_year = `yi'
//	
// 	* Prapre file
// 	use "baseline_SE_21.dta", clear
// 	run "prep_file_BC_onlyT.do"
// 	di "Done with prep for year "`"$current_year"'
// 	local i = 1
// 	foreach BC_var in unemp_change yin_* qin_* {
// 		global BC_Var = "`BC_var'"
// 		* Then run decomposition:
// 		run "decomposition_BC.do"
// 		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
//		
// 		* Print results
// 		local filename : word `i' of `filenames'
// 		log using "./results/results`yi'_`filename'_onlyT_harm.log", replace
// 		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
// 		log close
//		
// 		* Clean up
// 		drop mu_i-lpsig_c
// 		local i = `i' + 1
// 	}
//	
// }
//
// global onlyT = 0
// global onlyU = 1
//
// local filenames unemp yearD qtD
// 
// foreach yi in 2011 2005 1996 1999 1992{
// 	* Select year
// 	global current_year = `yi'
//	
// 	* Prapre file
// 	use "baseline_SE_21.dta", clear
// 	run "prep_file_BC_onlyT.do"
// 	di "Done with prep for year "`"$current_year"'
// 	local i = 1
// 	foreach BC_var in unemp_change yin_* qin_* {
// 		global BC_Var = "`BC_var'"
// 		* Then run decomposition:
// 		run "decomposition_BC.do"
// 		quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b
//		
// 		* Print results
// 		local filename : word `i' of `filenames'
// 		log using "./results/results`yi'_`filename'_onlyU_harm.log", replace
// 		sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
// 		log close
//		
// 		* Clean up
// 		drop mu_i-lpsig_c
// 		local i = `i' + 1
// 	}
//	
// }
//
