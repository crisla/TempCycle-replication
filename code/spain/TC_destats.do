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

// counting the number of TCs by spell
gen njob = 1
gen njobs = 0
replace njob = 0 if state=="U"|state=="R"
by id n_spell_c: replace njobs = sum(njob)

// average duration by spell
egen av_dur = mean(days), by(id n_spell_c)

// cleaning up
drop nfirms spell_c njob

// collapsing TC cycles
gen dtin2 = dtin
by id n_spell_c: replace dtin2 = dtin2[1]
format dtin2 %td

by id: drop if n_spell_c==n_spell_c[_n+1]

replace dtin = dtin2
replace days = dtout-dtin
drop dtin2

// Sample Selection I
// Non-retired
drop if state=="R"

// Expand one observation per year
drop if year_out<2005

gen year_expansion = year(dtout)-year(dtin) if year(dtin)<year(dtout)&year(dtout)>=2005

expand year_expansion+1 if year_expansion!=., gen(year_split)
sort id jobcount dtin year_split
gen year = year(dtin) if year_split==0
replace year = year[_n-1]+1 if year_split==1
drop if year_split==1&year<2005
drop if year>2013|year<2005

sort year id jobcount dtin dtout

// Sample Selection II
// Between 18 and 64
replace age = year - year(dtbirth)
drop if age<18|age>64

// Make sex dummy more traditional
drop sex_d
* Dummy for sex (1 is female)
gen sex_d = 0 if sex==1
replace sex_d = 1 if sex_d==.
label define sexl 0 "Male" 1 "Female" 
label values sex_d sexl

// Make educational variable a college/non-college
gen college = 0
gen high_school = 0
replace college = 1 if educ2 == 4
replace high_school = 1 if educ2 == 3 | educ2 == 4
label define collegel 0 "No college" 1 "College+" 
label values college collegel

// Make Educational variable consistent with German data
gen edu_ger = 1
replace edu_ger = 2 if educ2 ==3
replace edu_ger = 3 if educ2 ==4

* * * * * * * * * * * * * * * 
* Descriptive stats
* * * * * * * * * * * * * * * 

log using "/share/home/clafuent/MCVL/rawfiles/descriptive_stats.log", replace

// Number of spells
tab year state_c, row

// Age
tabstat age if id!=id[_n+1], by(year) statistics(mean sd min max n)

// Sex
tab year sex_d if id!=id[_n+1], row nofreq

// Education
tab year college if id!=id[_n+1], row nofreq
tabstat edu_ger if id!=id[_n+1], by(year) statistics(mean sd min max)

// Foreign born
tab year foreign_born if id!=id[_n+1], row nofreq

tabstat av_dur if state=="T", by(year) statistics(mean sd min max n)
tabstat av_dur, by(year) statistics(mean sd min max n)
tabstat njobs if state=="T", by(year) statistics(mean sd min max n)

tab year state_c if id!=id[_n+1], row nofreq
log close

// export delimited id year jobcount dtin dtout sex_d age educ2 state_c n_spell_c njobs nfirms days if year>2004&age>17&age<65 using "/share/home/clafuent/TempCycle/dur_hist_7.csv", replace
