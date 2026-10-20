* 
* Main file for exporting data, 1 observation being enough - Spain
*

* Options * * * * * * * * * * * * * * * * * * * * * * * * * * * 

* No outliers? change to 1
global no_outliers = 0
* No self-employed, civil servants or discontinous workers? change to 2 
*                                             (1 for >50% self employed)
global strict_cleaning = 1

* End year: spells after this year do not count. Set to 2013 for no censoring.
global end_year = 2021


* Data formating and export, TC, finished * * * * * * * * * * * * * * * * * * * * * * * * * * * 

global unfinished_in = 0

* Note: the last observation used to be from 1992 onwards
foreach yi in 2011 2005 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "./baseline_SE_21.dta", clear
	run "./prep_file_T_1obs.do"
	di "Done with prep for year "`"$current_year"'	
	
	* Export Results for plot
	export delimited id jobcount n_TC days sex_d age educ2 share_u state_next using "./rawfiles/duration/dur_`yi'_T_1obs_v21.csv", replace
	
}

* Data formating and export, PC, finished * * * * * * * * * * * * * * * * * * * * * * * * * * * 

* Options
* No outliers? change to 1
global no_outliers = 0
global unfinished_in = 0

* Strict cleaning:
* 0 : Only drop changes due to admin
* 1 : No discontinuous workers
* 2 : No discontinuous workers, or interinos, or coop workers
* 3 : No discontinuous workers, or interinos, or coop workers
*	  or ever civil servant or discontinuous
global strict_cleaning = 1

* Note: the last observation used to be from 1992 onwards
foreach yi in 2011 2005 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "./baseline_SE_21.dta", clear
	run "./prep_file_P_1obs.do"
	di "Done with prep for year "`"$current_year"'		
	
	* Export Results for plot
	export delimited id jobcount n_PC days sex_d age educ2 cause state_next using "./rawfiles/duration/dur_`yi'_P_1obs_v21_strict.csv", replace
	
}

* Data formating and export, TC, unfinished * * * * * * * * * * * * * * * * * * * * * * * * * * * 

global unfinished_in = 1

* Note: the last observation used to be from 1992 onwards
foreach yi in 2011 2005 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "./baseline_SE_21.dta", clear
	run "./prep_file_T_1obs.do"
	di "Done with prep for year "`"$current_year"'	
	
	gen months = days/30
	gen fin = 1-unfin
	stset months, failure(fin)
	
	log using "./descriptive_stats/hazard_T${current_year}.log", replace
	stsum
	tabstat months fin, s(mean var sum)
	log close
	
	* Export Results for plot
	export delimited id jobcount n_TC days sex_d age educ2 share_u state_next unfin year_first using "./rawfiles/duration/dur_`yi'_T_1obs_unfin_v21.csv", replace
	
}

* Data formating and export, PC, unfinished * * * * * * * * * * * * * * * * * * * * * * * * * * * 

global unfinished_in = 1

* Options
* No outliers? change to 1
global no_outliers = 0

* Strict cleaning:
* 0 : Only drop changes due to admin
* 1 : No discontinuous workers
* 2 : No discontinuous workers, or interinos, or coop workers
* 2 : No discontinuous workers, or interinos, or coop workers
*	  or ever civil servant or discontinuous
global strict_cleaning = 1

* Note: the last observation used to be from 1992 onwards
foreach yi in 2011 2005 1999 1992{
	* Select year
	global current_year = `yi'
	
	* Prepare file
	use "./baseline_SE_21.dta", clear
	run "./prep_file_P_1obs.do"
	di "Done with prep for year "`"$current_year"'	
	
	gen months = days/30
	gen fin = 1-unfin
	stset months, failure(fin)
	
	log using "./descriptive_stats/hazard_P${current_year}.log", replace
	stsum
	tabstat months fin, s(mean var sum)
	log close
	
	* Export Results for plot
	export delimited id jobcount n_PC days sex_d age educ2 cause state_next unfin year_first using "./rawfiles/duration/dur_`yi'_P_1obs_unfin_v21_strict.csv", replace
	
}

