*
* The cycle of precariousness - descriptive stats
*
clear
use "/share/home/clafuent/MCVL/rawfiles/SC_histories_cc.dta"

// drop if year_out<2005
gen state_c = state

sort id dtin dtout

* Defining the cycle
* Option 1: 7 days gap
// gaps in between tcs
by id: replace state_c = "T" if state=="U"&state[_n-1]=="T"&state[_n+1]=="T"&days<7 
// gaps until next cotnract (P or R)
by id: replace state_c = "T" if state=="U"&state[_n-1]=="T"&state[_n+1]!="U"&days<7 


gen spell_c = 1
by id: replace spell_c = 0 if state_c[_n-1]=="T"&state_c=="T"
gen n_spell_c = 0
by id: replace n_spell_c=sum(spell_c)

// counting the numebr of firms by spell
sort id n_spell_c dtin dtout
gen nfirms = 1
by id: replace nfirms = 0 if last_firm == ""
by id: replace nfirms = 0 if last_firm == last_firm[_n-1]
gen nfirms_all = 0
gen nfirms_spell = 0
by id n_spell_c: replace nfirms_spell = sum(nfirms)
by id n_spell_c: replace nfirms_spell = nfirms_spell[_N]
by id: replace nfirms_all = sum(nfirms)

// counting the number of TCs by (unstable) spell
gen job_n = 1
replace job_n = 0 if state=="U"|state=="R"
by id n_spell_c: gen njobs = sum(job_n)
drop job_n

// counting the number of Unemployment spells by (unstable) spell
gen nu = 1
replace nu = 0 if state!="U"
by id n_spell_c: gen nus = sum(nu)
drop nu

// counting the number of Unemployment days by (unstable) spell
by id n_spell_c: gen days_u = sum(days) if state=="U"

// average duration by spell
egen av_dur = mean(days), by(id n_spell_c)

// cleaning up
drop nfirms spell_c 

// collapsing TC cycles
gen dtin2 = dtin
by id n_spell_c: replace dtin2 = dtin2[1]
format dtin2 %td

by id: drop if n_spell_c==n_spell_c[_n+1]

replace dtin = dtin2
replace days = dtout-dtin
drop dtin2

// Percentage of time in unemployment
gen share_u = days_u/days
replace share_u = 0 if share_u == .

// Sample Selection I
// Non-retired
drop if state=="R"

// Recent spells
drop if year_out<2005
drop if year_in>2013

// Sample Selection II
// Between 18 and 64
replace age = year_in - year(dtbirth)
drop if age<18|age>64

// Make sex dummy more traditional
drop sex_d
* Dummy for sex (1 is female)
gen sex_d = 0 if sex==1
replace sex_d = 1 if sex_d==.

// Part-time dummy
gen part_time = 0
replace part_time = 1 if part == 2 // by type of contract, it is part-time
replace part_time = 1 if part == . & cop<1 & state!="U" // by number of hours

* * *
* Descriptive stats
*
sort id n_spell_c dtin dtout

// Age
tabstat age if id!=id[_n+1]&year_in>2004, by(year_in) statistics(mean sd min max n)

// Sex
tab year_in sex_d if id!=id[_n+1]&year_in>2004, row nofreq

// Foreign born
tab year_in foreign_born if id!=id[_n+1]&year_in>2004, row nofreq

tabstat av_dur if state=="T"&year_in>2004, by(year_in) statistics(mean sd min max n)
tabstat av_dur if year_in>2004, by(year_in) statistics(mean sd min max n)
tabstat njobs if state=="T"&year_in>2004, by(year_in) statistics(mean sd min max n)

tab year_in state if id!=id[_n+1], row nofreq

export delimited id year_in jobcount dtin dtout sex_d age educ2 state_c n_spell_c njobs share_u nfirms_all nfirms_spell av_dur days part_time foreign_born ExpT ExpP ExpU TotalExp age_in year_out if age>17&age<65 using "/share/home/clafuent/TempCycle/dur_hist_7_spell.csv", replace
