cap log close
log using "$log/037_decomp_prep.log", replace


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation
	
	Do-File for Preparation of SIAB Data for Decomposition - majority temp 
	or majority mini contracts.
	
	Jenny Peters

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


use "$data/05_descriptives.dta", clear

drop if min_year<2011 //use only data from 2011 onwards

* percentage of days spent in unemployment, temp jobs, or mini jobs
g mini = 0
replace mini = 1 if employment_status == 109 | employment_status == 209


* * * * * * * * * 
g state_breakdown = "NA"
replace state_breakdown = "U" if state ==4
replace state_breakdown = "U" if state ==1
replace state_breakdown = "mini" if mini == 1
replace state_breakdown= "midi" if midi_job == 1 
replace state_breakdown = "T" if fixed_term == 1 & mini != 1
replace state_breakdown = "P" if state == 2


* note: days is total days in the unstable spell, days_spell is days per unstable "contract" within the whole spell
g days_spell = dtout-dtin

* mini
gen days_mini = 0
replace days_mini = days_spell if state_breakdown == "mini"
bysort id sum_spells: replace days_mini=sum(days_mini) //only the last one is the total days per spell

* mini share
gen share_mini1 = days_mini/days
replace share_mini1 = 0 if share_mini1 == .
* total share, not cumulative share
bysort id sum_spells: egen share_mini = max(share_mini1) if state_c=="TU"


* unemployed
gen days_u = 0
replace days_u = days_spell if state_breakdown=="U"
bysort id sum_spells: replace days_u = sum(days_u)
order days_u, after(days_mini)

* unemployment share
gen share_u1 = days_u/days
replace share_u1 = 0 if share_u1 == .
* total share, not cumulative share
bysort id sum_spells: egen share_u = max(share_u1) if state_c=="TU"

* temporary
gen days_t = 0
replace days_t = days_spell if state_breakdown =="T"
bysort id sum_spells: replace days_t = sum(days_t)
* share temporary jobs
gen share_t1 = days_t/days
replace share_t1 = 0 if share_t == .
* total share, not cumulative share
bysort id sum_spells: egen share_t = max(share_t1) if state_c=="TU"

* midi-jobs
gen days_midi = 0
replace days_midi = days_spell if state_breakdown=="midi"
bysort id sum_spells: replace days_midi = sum(days_midi)
* share midi-jobs
gen share_midi1 = days_midi/days 
replace share_midi1 = 0 if share_midi1 == .
* total share, not cumulative share
bysort id sum_spells: egen share_midi = max(share_midi1) if state_c=="TU"

sort id dtin dtout

compress
save "$data/037_decomp.dta", replace


clear
log close


