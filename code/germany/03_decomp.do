cap log close
log using "$log/03_decomp.log", replace

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Analysis
	
	Main file for decompostion - Germany 

	This do-file is the main file for performing the variance decomposition for
	different specifications, following the non-parametric decomposition 
	developed by Alvarez, Borovickova and Shimer (2014).
	
	Each decomp_prep do file prepares the datasets, the decomp do-files carry
	out the actual decomposition.
	
	Jenny Peters

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/	

* Options:
* Outliers: No spells longer than 10 years? change to 1.
* No spells longer than 10 years and less than 12 jobs each (unstable) spell? change to 2. 
global no_outliers = 0
* only observations after 2011
global post_2011=1


* Decomposition: Baseline and Different Sample Lengths: 
foreach yi in 2011 2014 2016 {
	* Select year
	global currentyear = `yi'
	
	* Prepare file
	run "$prog/031_decomp_prep.do"
	di "Done with prep for year "`"$currentyear"'
	
	* Then run decomposition:
	do "$prog/031_decomp.do"
	
} 

	
* Decomposition: Baseline without outliers * * * * * * * * * * * * * * * * * * */

global no_outliers = 2

	* Prepare file
	* do "$prog/032_decomp_prep.do"
	* di "Done with prep for Baseline Decomposition without Outliers"
	
	* Then run decomposition:
	* do "$prog/032_decomp.do"
	
* revert to default spec		
global no_outliers = 0 

 

* By Sex * * * * * * * * * * * * * * * * * * * * * * * * * * * 

	* Prepare file
	do "$prog/033_decomp_prep.do"
	di "Done with prep for Decomposition by Sex"
	
	* Then run decomposition:
	do "$prog/033_decomp.do"
	


/* By Age group * * * * * * * * * * * * * * * * * * * * * * * * * * * 

	local bottom_age = 25
	foreach top_age in 35 55{
	cap log close
	log using "$log/034_decomp_`bottom_age'_`top_age'.log", replace
	
		* Prepare file
		use "$data/031_decomp_2011.dta", clear
		
		* Select observations
		di "Age bracket: `bottom_age' `top_age' "
		keep if age>=`bottom_age'&age<`top_age'
		
		* Clean up cases with 1 spell left
		egen count_TC = count(id), by(id)
		keep if count_TC==2
		
		* Then run decomposition:
		do "$prog/034_decomp.do"
		
// Print results: 

	di "Table 5: Baseline Variance Decomposition, Age bracket: `bottom_age' - `top_age' "
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y
		cap log close
		* Change variable
		local bottom_age = `top_age'	
	}
	
	

* With Age controls * * * * * * * * * * * * * * * * * * * * * * * * * * *


	* Run decomposition:
	do "$prog/035_decomp.do"


* By education * * * * * * * * * * * * * * * * * * * * * * * * * * *


	
	local ed_dummy = 4
	foreach educ in college higher secondary primary{
	cap log close
	log using "$log/036_decomp_`educ'.log", replace
		* Prepare file
		use "$data/031_decomp_2011.dta", clear
		
		
		* Select observations
		keep if educ2== `ed_dummy'
		
		* Then run decomposition:
		do "$prog/036_decomp.do" 

// Print results: 

	di "Table 7: Baseline Variance Decomposition, Education Level: `educ' "
	sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y

		* Change variable
		local ed_dummy = `ed_dummy' - 1
		log close
	}
	


* Business cycle controls * * * * * * * * * * * * * * * * * * * * * * * * * * *

	* Prepare file
	do "$prog/034_decomp_prep.do"
	di "Done with prep for Decomposition with BC controls"

	cap log close 

foreach BC_var in growth_unemp real_gdp_growth {

    use "$data/034_decomp.dta", clear

    cap log close
    log using "$log/037_decomp_`BC_var'.log", replace name(decomp)

    global BC_Var = "`BC_var'"

    capture noisily do "$prog/037_decomp.do"
    
    di _newline "Table 8: Baseline Variance Decomposition, BC control: `BC_var'"
    sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y

    cap log close decomp
}

cap log close 


* Decompositon controlling for year in and quarter in:
	* do "$prog/038_decomp.do"
	* do "$prog/039_decomp.do"


* Decomposition: Mini jobs only * * * * * * * * * * * * * * * * * * * * * * * *

	* Prepare file
	do "$prog/035_decomp_prep.do"
	di "Done with prep for Mini Only Decomposition"
	
	* Then run decomposition:
	* do "$prog/040_decomp.do"
	
* Decomposition: Temp contracts only * * * * * * * * * * * * * * * * * * * * * * * * * * * 

	* Prepare file
	do "$prog/036_decomp_prep.do"
	di "Done with prep for Temp Only Decomposition"
	
	* Then run decomposition:
	* do "$prog/041_decomp.do"



* Decomposition: Majority Mini jobs * * * * * * * * * * * * * * * * * * * * * * * * * * */ 

* Prepare file
	do "$prog/037_decomp_prep.do"
	
* Then run decomposition:
	* do "$prog/042_decomp.do"

* Decomposition: Majority Temp jobs * * * * * * * * * * * * * * * * * * * * * * * * * * * 

	* do "$prog/043_decomp.do"

* Decomposition: Majority Unemployment * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* do "$prog/044_decomp.do"
	
*/	





	
cap log close


