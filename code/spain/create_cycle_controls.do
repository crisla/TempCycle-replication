**** **** **** **** **** **** **** **** **** **** **** **** **** **** **** **** 
* Generates cstataset to be merged with main file for ecnomic cycle controls
* Cristina Lafuente 25/02/2026
**** **** **** **** **** **** **** **** **** **** **** **** **** **** **** ****

import delimited "../agg_data/bc_controls_ext.csv", clear
// import delimited "../agg_data/estat_une_rt_a_h_filtered_en.csv", clear
rename year year_in
rename unemp_rate_es unemp
rename real_gdp_growth_es gdp_growth

* Create growth variable
gen unemp_change = unemp - unemp[_n-1]

keep year_in unemp gdp_growth unemp_change
save "cycle_controls.dta", replace


