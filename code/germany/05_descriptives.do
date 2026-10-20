cap log close                                                 					
log using "$log/05_descriptives.log", replace         

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation
	
	Unstable Employment Cycles
	Do-File for Descriptive Statistics of SIAB Data

	Structure of file:
	
	The first part uses the whole unified spells.
	
	The second part uses the "baseline" file for different timne windows. It 
	restricts age to 25 to 50 years old, and partitions the sample into 2+ 
	completed spells, just one or none, but uses all spells of individuals.
	
	The third part uses the actual file used for the decomposition: same as
	above but only the first two spells of individuals. 

	The descriptive stats are key demographics: age, sex, education
	Then also industry of last employment, number and length of spells of
	each labour state. 
	
	User: Jenny Peters
	
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

* incidence of atypical employment: turn spells into a stock measure, compute the monthly share, then average those 12 monthly shares within each year
use "$data/02_entirespells", clear

g atypical = 0
replace atypical = 1 if employment_status == 109 | employment_status == 209 | fixed_term == 1
qui gen int yrin=year(min_begepi)
qui gen int monthin=month(min_begepi)
qui gen int yrout=year(max_endepi)
qui gen int monthout=month(max_endepi)


* keep only employed
keep if state == 2 | state == 3

* Monthly index for start/end
gen int m_in  = mofd(min_begepi)
gen int m_out = mofd(max_endepi)

* only 2011+ is reported -> drop earlier spells and clip the rest before expanding
drop if m_out < ym(2011,1)              // spell ends before 2011: irrelevant
replace m_in = ym(2011,1) if m_in < ym(2011,1)   // clip start to Jan 2011

* Expand each spell into one row per active month
gen int nmonths = m_out - m_in + 1
expand nmonths

bysort id min_begepi max_endepi: gen int m = m_in + _n - 1
format m %tm

collapse (max) atypical, by(id m)

* Check both unique persons AND person-months by year and atypical status
gen int year = yofd(dofm(m))

* means are shares because atypical are 0/1 and denominator is all employed in month m
* yearly averages + number of months used per year

collapse (mean) atypical (count) N = atypical, by(year)
keep if year >= 2011


************************************************
* Table 1: share of atypical in all of employment
* variables: year, share of atypical contracts of all employment contracts
************************************************
list year atypical N

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
use "$data/05_descriptives.dta", clear
replace days_p_pre2011 = 0 if missing(days_p_pre2011)
gen double days_p_total = days_p + days_p_pre2011
preserve
drop if min_year < 2011

************************************************
* Table 2: Descriptives for baseline sample including never unstable
* Variables: age, gender, nationality, number of permanent and temp contracts,
* days permanent, days temp/unemp (lifetime)
************************************************
tabstat age sex_d foreign n_PC n_TC_sample days_p_total days_tu if samesame==1, by(max_TC_sample) statistics(mean sd min p10 p25 p50 p75 p90 max n)

************************************************
* Table 3: Descriptives for baseline sample
* Variables: days permanent, days temp/unemp (only in sample window)
************************************************
tabstat days_if_P days_if_TU, by(max_TC_sample) statistics(mean sd min p10 p25 p50 p75 p90 max n)

************************************************
* Table 4: Descriptives for baseline sample excluding never unstable
* Variables: age, gender, nationality, number of permanent and temp contracts,
* days permanent, days temp/unemp (lifetime)
************************************************
tabstat age sex_d foreign n_PC n_TC_sample days_p_total days_tu if samesame==1 & attached==0, by(max_TC_sample) statistics(mean sd min p10 p25 p50 p75 p90 max n)

************************************************
* Table 5: Descriptives for baseline sample
* Variables: education and number of temp contracts
************************************************
tab educ2 max_TC_sample if samesame==1, column


************************************************
* Table 6: Descriptives for baseline sample
* Variables: industry and number of temp contracts
************************************************
tab ind_short max_TC_sample if samesame==1, column
restore 

************************************************
* Spell-bin distribution by time window for Sample Selection 
************************************************

drop if year(dtout) < 2011 // 2011 on

* --- build windowed bins + samesame FIRST ---
drop max_TC_sample samesame
bysort id (obs_no): g ends_TU         = (state_c[_N]=="TU")
bysort id (obs_no): g starts_TU       = (state_c[1]=="TU")
bysort id (obs_no): g byte spell_ch_w = (state_c=="P" & state_c[_n-1]=="TU")
bysort id (obs_no): egen spells_w     = sum(spell_ch_w)
gen max_TC_sample = spells_w + 0.5*ends_TU
replace max_TC_sample = 2 if max_TC_sample > 2
bysort id (obs_no): g byte samesame   = (_n==_N)

bysort id (obs_no): egen byte everU_w = max(state_c=="TU")   // 1 if any TU spell in the window

************************************************
* Table 7 (2011 onwards)
* Variables: indicator if spell starts in unstable 
************************************************
tab starts_TU if samesame==1

************************************************
* Table 8 (2011 onwards) temp contracts per spell bin
* Variables: max number of unstable contracts per person
************************************************
tab max_TC_sample if samesame==1

* --- descriptive tables (3-bin, Spain "classic"): windowed count spells_w, lifetime days ---
preserve
replace max_TC_sample = 0 if max_TC_sample == 0.5
replace max_TC_sample = 1 if max_TC_sample == 1.5

replace n_TC_sample = spells_w
************************************************
* Table 9: baseline sample INCLUDING never unstable
* Variables: Age, female dummy, foreign nationality dummy, number of 
* permanent contracts, number of unstable/temporary contracts, days in
* permanent employment, days in unstable employment
************************************************
tabstat age sex_d foreign n_PC n_TC_sample days_p_total days_tu if samesame==1, by(max_TC_sample) statistics(mean sd min p10 p25 p50 p75 p90 max n)

************************************************
* Table 10: baseline sample EXCLUDING never unstable
* Variables: Age, female dummy, foreign nationality dummy, number of 
* permanent contracts, number of unstable/temporary contracts, days in
* permanent employment, days in unstable employment
************************************************
tabstat age sex_d foreign n_PC n_TC_sample days_p_total days_tu if samesame==1 & everU_w==1, by(max_TC_sample) statistics(mean sd min p10 p25 p50 p75 p90 max n)

restore

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* window filter: only 2014 on  (spell-level end-year, matches the 2011 cut)
drop if year(dtout) < 2014 

* refresh sequence bins + samesame on the windowed spells
drop ends_TU starts_TU spell_ch_w spells_w samesame
bysort id (obs_no): g ends_TU         = (state_c[_N]=="TU")
bysort id (obs_no): g starts_TU       = (state_c[1]=="TU")
bysort id (obs_no): g byte spell_ch_w = (state_c=="P" & state_c[_n-1]=="TU")
bysort id (obs_no): egen spells_w     = sum(spell_ch_w)
drop max_TC_sample
gen max_TC_sample = spells_w + 0.5*ends_TU
replace max_TC_sample = 2 if max_TC_sample > 2
bysort id (obs_no): g byte samesame   = (_n==_N)

************************************************
* Table 11: (2014 onwards)
* Variables: indicator if spell starts in unstable 
************************************************
tab starts_TU if samesame==1
	
************************************************
* Table 12: temporary contracts per spell-bin
* Variables: maximum number of temporary contracts of each person (only 2014 on)
************************************************
tab max_TC_sample if samesame==1
 

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* window filter: only 2016 on  (spell-level end-year)
drop if year(dtout) < 2016

* refresh sequence bins + samesame on the windowed spells
drop ends_TU starts_TU spell_ch_w spells_w samesame
bysort id (obs_no): g ends_TU         = (state_c[_N]=="TU")
bysort id (obs_no): g starts_TU       = (state_c[1]=="TU")
bysort id (obs_no): g byte spell_ch_w = (state_c=="P" & state_c[_n-1]=="TU")
bysort id (obs_no): egen spells_w     = sum(spell_ch_w)
drop max_TC_sample
gen max_TC_sample = spells_w + 0.5*ends_TU
replace max_TC_sample = 2 if max_TC_sample > 2
bysort id (obs_no): g byte samesame   = (_n==_N)


************************************************
* Table 13: only 2016 on
* Variables: indicator if spell starts in unstable
************************************************
tab starts_TU if samesame==1
	
************************************************
* Table 14: temporary contracts per spell-bin, only 2016 on
* Variables: maximum number of temporary contracts of each person
************************************************
tab max_TC_sample if samesame==1
 

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

* Sample Selection 2: same individuals as in decomposition, but all of their spells
use "$data/037_decomp.dta", clear

sort id dtin dtout

* indicator of first part of unstable spell being TC
g PCTC = 0
order PCTC, after(state_breakdown)
replace PCTC = 1 if state_breakdown == "T" & state_breakdown[_n-1] == "P"&max_TC_sample==2&n_TC_sample<2
bysort id: egen PCtemp = sum(PCTC) 

* indicator of first part of unstable spell being mini
g PCmin = 0
order PCmin, after(year)
replace PCmin = 1 if state_breakdown == "mini" & state_breakdown[_n-1] == "P"&max_TC_sample==2&n_TC_sample<2
bysort id: egen PCmini = sum(PCmin) 

************************************************
* Table 15: Permanent to Temporary Contract Transitions 
* Variables: Indicator of first day of spell being temporary
* Note: only for decomposition sample
************************************************

tab PCtemp if samesame==1&max_TC_sample==2


************************************************
* Table 16: Permanent to mini job transitions 
* Variables: Indicator of first day of spell being mini job
* Note: only for decomposition sample
************************************************

tab PCmini if samesame==1&max_TC_sample==2 

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

* Sample Selection 3: same sample as in decomposition
use "$data/031_decomp_2011.dta", clear

**********************************************
* Table 17:
* Variables: days in unstable employment
************************************************
tabstat days, statistics(mean sd variance min p10 p25 p50 p75 p90 max n)

*/


clear
log close

