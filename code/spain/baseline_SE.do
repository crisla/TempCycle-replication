*
* Unstable Employment Cycles - baseline generating file
*
// Preliminaries
// global path = "C:\Users\clm96\Documents\Research\TempCycle\spain\"
// cd $path
// clear

// Select the file - please refer to the README file in the rawfiles folder.
use "rawfiles/MCVL_2021_retro.dta", clear
// gen age_in = year(dtin)-year(dtbirth)

// Fix a couple of things first (to be added to baseline 2020 format file)
sort id dtin dtout
gen samesame =(id!=id[_n+1])
by id: gen samejob=(jobcount==jobcount[_n+1])
* First: zombie workers (81 cases)
gen muerto_vivo=(cause==56&samesame==0&samejob==0)
replace unfin = 0 if muerto_vivo
* Next: people out of retirement (28,000 cases)
by id: gen next_retire=(state[_n+1]=="R")
gen out_of_retirement=(cause==58&samesame==0&next_retire==0)
replace unfin = 0 if out_of_retirement
* Clean-up
drop samesame samejob muerto_vivo next_retire out_of_retirement

// First year in the labour market
sort id dtin dtout
by id: gen age_first = age_in[1]
drop age_i

gen state_c = state

sort id dtin dtout

* Defining the cycle
* Option 2: All temp gaps are U gaps
// gaps in between tcs
by id: replace state_c = "TU" if state=="U"&(state[_n+1]!="T"|state[_n+1]!="U"|state[_n+1]!="R") 
// gaps until next cotnract (P or R)
by id: replace state_c = "TU" if state=="T"&(state[_n+1]!="T"|state[_n+1]!="U"|state[_n+1]!="R")
// self-employment is also unstable (less than 2 years)
by id: replace state_c ="TU" if state=="A"&days<365*2 
// stable employment
// by id: replace state_c ="PP" if state=="P"|state=="A"

// Counting spells inside the spell
gen spell_c = 1
by id: replace spell_c = 0 if state_c[_n-1]=="TU"&state_c=="TU"
by id: replace spell_c = 0 if state_c[_n-1]=="P"&state_c=="P"
gen n_spell_c = 0
by id: replace n_spell_c=sum(spell_c)

// counting the number of firms by spell
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

// Spell overlap correction (20k cases) for better share measures
sort id n_spell_c dtin dtout
by id: replace dtin=dtout[_n-1] if dtin<dtout[_n-1]&dtout>dtout[_n-1]&_n>1&state_c=="TU"
replace days = dtout-dtin

// counting the number of Unemployment/temp days by (unstable) spell
gen days_u = days if state=="U"
replace days_u = 0 if days_u == .
gen days_t = days if state=="T"
replace days_t = 0 if days_t == .
gen days_a = days if state=="A"
replace days_a = 0 if days_a == .
by id n_spell_c: replace days_u = sum(days_u)
by id n_spell_c: replace days_t = sum(days_t)
by id n_spell_c: replace days_a = sum(days_a)

// average duration by spell
egen av_dur = mean(days), by(id n_spell_c)

// New entrants
by id n_spell_c: gen new_entrant = (jobcount[1]==1)

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

gen share_t = days_t/days
replace share_t = 0 if share_t == .

// Percentage of time in self-employment
gen share_a = days_a/days
replace share_a = 0 if share_a == .

// Sample Selection I / / / / / / / / / / / / / / / / / / / / / / / / 

capture drop year_in year_out
gen year_in = year(dtin)
gen year_out = year(dtout)

// Non-retired (or about to)
drop if state_c=="TU"&nextS=="R"
drop if state=="R"

// Sample Selection II / / / / / / / / / / / / / / / / / / / / / / / / 
// Between 25 and 55s
replace age = year_in - year(dtbirth)
drop if age<25|age>=55

// Format variables / / / / / / / / / / / / / / / / / / / / / / / / 

// Make sex dummy more traditional
capture drop sex_d
* Dummy for sex (1 is female)
gen sex_d = 0 if sex==1
replace sex_d = 1 if sex_d==.

// Age dummy variables
gen age_d_young = 0
gen age_d_old = 0

replace age_d_young = 1 if age<30
replace age_d_old = 1 if age>=45

// Part-time dummy
gen part_time = 0
replace part_time = 1 if part == 2 // by type of contract, it is part-time
replace part_time = 1 if part == . & cop<1 & state!="U" // by number of hours

// Work experience
by id: gen work_exp = sum(days)
by id: replace work_exp = work_exp[_N]

// Public servant dummy
gen pub_serv =  (tyrel>=900&tyrel<911)

// Discontinous worker dummy
gen fijo_disc = (tyco>=300&tyco<400)

// No civil servants (not even a day)
sort id dtin dtout
gen days_fun = 0
replace days_fun = days if pub_serv==1
by id: replace days_fun = sum(days_fun)
by id: gen ever_fun = (days_fun[_N]>0)

// Share of working life in each contract
by id: gen days_t_all = sum(days_t)
by id: gen days_a_all = sum(days_a)
by id: gen days_u_all = sum(days_u)

gen days_p_all = 0
replace days_p_all = days if state=="P"
by id: replace days_p_all = sum(days_p_all)


// No discontinuous workers (not even a day)
gen days_disc = 0
replace days_disc = days if fijo_disc==1
by id: replace days_disc = sum(days_disc)
by id: gen ever_disc = (days_disc[_N]>0)

// No self employed (not even a day)
by id: gen ever_se = (days_a_all[_N]>0)

// Counting
egen share_total_a = max(days_a_all/work_exp), by(id)
egen share_total_fun = max(days_fun/work_exp), by(id)
gen share_total_t = days_t_all/work_exp
gen share_total_p = days_p_all/work_exp
gen share_total_u = days_u_all/work_exp

// Formating  education
replace education = "0" if education=="C0"
destring(education), replace
gen educ2 = .
* 1: less than primary studies
replace educ2 = 1 if education <30
* 2: less than secondary studies/primary studiues and some more 
* (graduado escolar + FP basic)
replace educ2 = 2 if education >=30 & education <40
* 2: Secondary studies
* (FP Superior + Bachiller + BUP)
replace educ2 = 3 if education >=40 & education <44
* 4: College and beyond
replace educ2 = 4 if education >=44 & education <50

// Dummy for post 2008
gen post08 = 1 if dtin>=td(01jan2008)
replace post08 = 0 if post08 ==.
gen pre08 = 1 if dtin<td(01jan2008)&dtin>=td(01jan2004)
replace pre08 = 0 if post08 ==.

// Make sure alst spells are counted as unfinished (right-censored)
replace unfin=1 if last_spell==1&nextS==""

* Drop ambiguous duplicate job-spell records (administrative noise: 9 pairs,
* 18 obs total, no consistent distinguishing feature found between the two
* records in each pair — see devlog 2026-07-22). Both records in each
* ambiguous pair are dropped, not just the extras, since there is no
* principled basis for choosing which one to keep.
duplicates tag id jobcount dtin dtout, gen(_dup_admin)
drop if _dup_admin > 0
drop _dup_admin

// Saving
saveold "baseline_SE_21.dta", replace
