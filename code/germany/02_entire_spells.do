cap log close                                                 				
log using "$log/02_entire_spells.log", replace        

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Unstable Employment Cycles
	SIAB Preparation
	
	Do-File for Preparation of SIAB Data

	This do-file uses the cleaned data from 01_clean.do to process employment 
	spells, merging overlapping spells, filling gaps between spells, 
	and cleaning up the resulting dataset. It ensures that there are 
	no overlapping spells and creates new spells where necessary to 
	account for gaps. Finally, it drops unnecessary records and 
	variables, leaving a clean dataset with non-overlapping employment spells.
	
	Jenny Peters

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
    

use "$data/01_dataprep.dta", clear  

g persnr_orig=id
keep if yr_begepi>=1991
qui egen long id2=group(id)
drop id
rename id2 id
sort id state dtin dtout
bysort id state: gen obs=_n

* * * * * * * * * * * * * * * Correcting Spells * * * * * * * * * * * * * * * *

drop if _merge == 2 //drop unmatched merges from industry dataset
drop _merge 
* create entire spells
bysort id state: g byte espell_l=(dtin<dtout[_n-1]+2) //spell starts immediately after previous ends
bysort id state: g byte espell_u=(dtout>dtin[_n+1]-2) //spell ends around the same time other starts
sort id state dtin dtout
bysort id state: replace obs=obs[_n-1] if espell_l==1 & espell_u[_n-1]==1 //unify the spell
bysort id state obs: egen int max_endepi=max(dtout)
bysort id state obs: egen int min_begepi=min(dtin)
format max_endepi min_begepi %d
bysort id state obs: keep if _n==1

egen uniqueid = group(id state obs)
* generate non-identified for time in between spells
sort id min_begepi max_endepi state uniqueid
expand 2 if max_endepi<min_begepi[_n+1]-2 & id==id[_n+1] & min_begepi[_n+1]!=., generate(duplicate)
egen id2 = group(uniqueid duplicate)
drop uniqueid
rename id2 uniqueid

* * * * * *  *
sort id min_begepi max_endepi state uniqueid
replace state=4 if duplicate==1
replace state_c="TU" if duplicate==1


bysort id (uniqueid): replace max_endepi=min_begepi[_n+1]-1 if duplicate==1 //replace end date of new spell
bysort id (uniqueid): replace min_begepi=max_endepi[_n-1]+1 if duplicate==1 //replace start date of new spell

g int days=max_endepi-min_begepi

//drop missing start dates resulting from unifying spells
drop if min_begepi ==.

//overlaps by state
sort id state min_begepi max_endepi days duplicate uniqueid
bysort id state (min_begepi max_endepi uniqueid): g byte overlap=((max_endepi>min_begepi[_n+1] & min_begepi[_n+1]!=.) | (min_begepi<max_endepi[_n-1] & max_endepi[_n-1]!=.)) //identifies overlapping spells forward and backward
bysort id state (min_begepi max_endepi uniqueid): g idx_overlap=1 if overlap[_n-1]==0 & overlap==1
bysort id state: g sum_overlap=sum(idx_overlap)
bysort id state sum_overlap: egen tmax_endepi=max(max_endepi) if sum_overlap>0 & (idx_overlap==1)
bysort id state sum_overlap: egen tmin_begepi=min(min_begepi) if sum_overlap>0 & (idx_overlap==1)
replace min_begepi=tmin_begepi  if sum_overlap>0 & (idx_overlap==1)
replace max_endepi=tmax_endepi  if sum_overlap>0 & (idx_overlap==1)
g ctr=.
bysort id state sum_overlap: replace  ctr=_n if overlap==1
drop if ctr>1 & overlap==1 & ctr!=.
sort id min_begepi max_endepi state days duplicate firmID source employment_status part_time fixed_term midi_jobs dtin dtout uniqueid
replace days=max_endepi-min_begepi
drop idx_overlap sum_overlap tmin* tmax* ctr
drop if max_endepi-min_begepi<1


* * * * * * * * * * * * * Prevalence by Hierarchy * * * * * * * * * * * * * * *

// Removing employment spells based on a hierarchy of states: permanent > marginal employment > unemployment > non-employment.

//drop anything within a permanent (state==2)
bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n-1] & min_begepi<=max_endepi[_n-1] & max_endepi<=max_endepi[_n-1] & state[_n-1]==2 & state!=2 & min_begepi[_n-1]!=. & max_endepi[_n-1]!=. & min_begepi!=. & max_endepi!=.

bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n+1] & max_endepi<=max_endepi[_n+1] & state[_n+1]==2 & state!=2 & min_begepi[_n+1]!=. & max_endepi[_n+1]!=. & min_begepi!=. & max_endepi!=.

//drop anything except permanent within a ME (state==3)
bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n-1] & min_begepi<=max_endepi[_n-1] & max_endepi<=max_endepi[_n-1] & state[_n-1]==3 & state!=2 & state!=3 & min_begepi[_n-1]!=. & max_endepi[_n-1]!=. & min_begepi!=. & max_endepi!=.

bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n+1] & max_endepi<=max_endepi[_n+1] & state[_n+1]==3 & state!=2 & state!=3 & min_begepi[_n+1]!=. & max_endepi[_n+1]!=. & min_begepi!=. & max_endepi!=.


//drop anything except permanent and ME within a UE (state==1)
bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n-1] & min_begepi<=max_endepi[_n-1] & max_endepi<=max_endepi[_n-1] & state[_n-1]==1 & state!=2 & state!=3 & state!=1 & min_begepi[_n-1]!=. & max_endepi[_n-1]!=. & min_begepi!=. & max_endepi!=.

bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n+1] & max_endepi<=max_endepi[_n+1] & state[_n+1]==1 & state!=2 & state!=3 & state!=1 & min_begepi[_n+1]!=. & max_endepi[_n+1]!=. & min_begepi!=. & max_endepi!=.


//drop anything except permanent and ME within a NE (state=4)
bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n-1] & min_begepi<=max_endepi[_n-1] & max_endepi<=max_endepi[_n-1] & state[_n-1]==4 & state!=2 & state!=3 & state!=4 & min_begepi[_n-1]!=. & max_endepi[_n-1]!=. & min_begepi!=. & max_endepi!=.

bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n+1] & max_endepi<=max_endepi[_n+1] & state[_n+1]==4 & state!=2 & state!=3 & state!=4 & min_begepi[_n+1]!=. & max_endepi[_n+1]!=. & min_begepi!=. & max_endepi!=.


//drop anything within a permanent
forval i=1/120 {
bysort id (min_begepi max_endepi state uniqueid) : drop if min_begepi>=min_begepi[_n-1] & min_begepi<=max_endepi[_n-1] & max_endepi<=max_endepi[_n-1] & state[_n-1]==2 & state!=2 & min_begepi[_n-1]!=. & max_endepi[_n-1]!=. & min_begepi!=. & max_endepi!=.
}

forval i=1/3 {
bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n+1] & max_endepi<=max_endepi[_n+1] & state[_n+1]==2 & state!=2 & min_begepi[_n+1]!=. & max_endepi[_n+1]!=. & min_begepi!=. & max_endepi!=.

}

//drop anything within a ME
forval i=1/110 { 
bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n-1] & min_begepi<=max_endepi[_n-1] & max_endepi<=max_endepi[_n-1] & state[_n-1]==3 & state!=2 & state!=3 & min_begepi[_n-1]!=. & max_endepi[_n-1]!=. & min_begepi!=. & max_endepi!=.
}

forval i=1/3 {
bysort id (min_begepi max_endepi state uniqueid): drop if min_begepi>=min_begepi[_n+1] & max_endepi<=max_endepi[_n+1] & state[_n+1]==3 & state!=2 & state!=3 & min_begepi[_n+1]!=. & max_endepi[_n+1]!=. & min_begepi!=. & max_endepi!=.
}


bysort id (min_begepi max_endepi state uniqueid): replace min_begepi=max_endepi[_n-1]+1 if min_begepi<max_endepi[_n-1] & state[_n-1]==2 & state!=2 & max_endepi[_n-1]!=.
bysort id (min_begepi max_endepi state uniqueid): replace max_endepi=min_begepi[_n+1]-1 if max_endepi>min_begepi[_n+1] & state[_n+1]==2 & state!=2 & min_begepi[_n-1]!=.

bysort id (min_begepi max_endepi state uniqueid): replace min_begepi=max_endepi[_n-1]+1 if min_begepi<max_endepi[_n-1] & state[_n-1]==3 & state!=2 & state!=3 & max_endepi[_n-1]!=.
bysort id (min_begepi max_endepi state uniqueid): replace max_endepi=min_begepi[_n+1]-1 if max_endepi>min_begepi[_n+1] & state[_n+1]==3 & state!=2 & state!=3 & min_begepi[_n-1]!=.

bysort id (min_begepi max_endepi state uniqueid): replace min_begepi=max_endepi[_n-1]+1 if min_begepi<max_endepi[_n-1] & state[_n-1]==1 & state!=2 & state!=3 & state!=1 & max_endepi[_n-1]!=.
bysort id (min_begepi max_endepi state uniqueid): replace max_endepi=min_begepi[_n+1]-1 if max_endepi>min_begepi[_n+1] & state[_n+1]==1 & state!=2 & state!=3 & state!=1 & min_begepi[_n-1]!=.

bysort id (min_begepi max_endepi state uniqueid): replace min_begepi=max_endepi[_n-1]+1 if min_begepi<max_endepi[_n-1] & state[_n-1]==4 & state!=2 & state!=3 & state!=4 & max_endepi[_n-1]!=.
bysort id (min_begepi max_endepi state uniqueid): replace max_endepi=min_begepi[_n+1]-1 if max_endepi>min_begepi[_n+1] & state[_n+1]==4 & state!=2 & state!=3 & state!=4 & min_begepi[_n-1]!=.

drop if max_endepi-min_begepi<1
replace days=max_endepi-min_begepi

//error here negative days
bysort id: g counter=1 if state!=state[_n-1]
bysort id: g sum_counter=sum(counter)
bysort id sum_counter: egen int tmin_begepi=min(min_begepi)
bysort id sum_counter: egen int tmax_endepi=max(max_endepi)
replace min_begepi=tmin_begepi
replace max_endepi=tmax_endepi
bysort id sum_counter: keep if _n==1
drop sum_counter
replace days=max_endepi-min_begepi
replace days = max_endepi - min_begepi + 1 if days==0 


qui egen long persnr2=group(id)
drop id
rename persnr2 id
sort id min_begepi max_endepi state days duplicate firmID uniqueid

* * * * * * * * * * * * * * * * Unstable Spells * * * * * * * * * * * * * * * *

// Anything except permanent employment
bysort id: g byte Unstable=1 if state==4 | state==1 | state==3
bysort id: g sum_Unstable=sum(Unstable)
bysort id: egen max_sum_Unstable=max(sum_Unstable)
g byte spell=.
replace spell=1 if state==2 //permanent
replace spell=2 if state==4 & spell==. //NE
replace spell=3 if state==1 & spell==. //UE
replace spell=4 if state==3 & spell==. //ME

// spell changes - Detect Transitions from Unstable to Permanent
bysort id (min_begepi max_endepi state uniqueid): g byte spell_ch=1 if spell[_n-1]>1 & spell[_n-1]<5 & spell==1 & sum_Unstable>0
//spell ordering - Calculate Spell Cycles
bysort id: gen int sum_spells=sum(spell_ch) //order of spells
bysort id sum_spells: egen int cmin_begepi=min(min_begepi)
bysort id sum_spells: egen int cmax_endepi=max(max_endepi)
g int cycle_days=cmax_endepi-cmin_begepi
bysort id: egen spells=sum(spell_ch) //total number of spells

// Counting spells inside the spell - spell changes
sort id dtin dtout uniqueid
gen spell_c = 1
by id: replace spell_c = 0 if state_c[_n-1]=="TU"&state_c=="TU"
by id: replace spell_c = 0 if state_c[_n-1]=="P"&state_c=="P"
gen n_spell_c = 0
bys id: replace n_spell_c=sum(spell_c)

// counting the number of TCs by (unstable) spell
gen job_n = 1
replace job_n = 0 if state==1 | state==4
bysort id n_spell_c: gen njobs = sum(job_n)
drop job_n

g year=year(min_begepi) 

compress

save "$data/02_entirespells.dta", replace   
* * * * * * * * *

* create descriptives dataset (whole sample)

* * * * * * * * */


use "$data/02_entirespells", clear

sort id min_begepi max_endepi state days cycle_days duplicate firmID source employment_status part_time fixed_term midi_jobs

gen long obs_no = _n

order id obs_no age

drop if age<25 | age >=55
drop age_d_y age_d_o

sort id min_begepi max_endepi state days cycle_days duplicate firmID source employment_status part_time fixed_term midi_jobs obs_no

drop Unstable sum_Unstable spell spell_ch sum_spells spells max_sum_Unstable cmin_begepi cmax_endepi cycle_days

bysort id (obs_no): g Unstable=1 if state==4 | state==1 | state==3
bysort id (obs_no): egen sum_Unstable=sum(Unstable)
bysort id (obs_no): egen max_sum_Unstable=max(sum_Unstable)

g byte spell=.
replace spell=1 if state==2
replace spell=2 if state==4 & spell==.
replace spell=3 if state==1 & spell==.
replace spell=4 if state==3 & spell==.

bysort id (obs_no): g spell_ch=1 if spell[_n-1]>1 & spell[_n-1]<5 & spell==1 & sum_Unstable>0

order id obs_no state_c spell_ch min_begepi max_endepi

bysort id (obs_no): gen sum_spells=sum(spell_ch)
bysort id sum_spells (obs_no): egen int cmin_begepi=min(min_begepi) 
bysort id sum_spells (obs_no): egen int cmax_endepi=max(max_endepi) 
g int cycle_days=cmax_endepi-cmin_begepi

sort id min_begepi max_endepi state days cycle_days sum_spells duplicate firmID source employment_status part_time fixed_term midi_jobs obs_no //new

order id obs_no state_c spell_ch sum_spells max_sum_Unstable min_begepi max_endepi

bysort id (obs_no): g sum_perman=sum(state==2) if sum_Unstable>0 //new
bysort id (obs_no): egen max_sum_perman=max(sum_perman) //new

order id obs_no state_c spell_ch min_begepi max_endepi sum_perman max_sum_perman
order max_sum_perman, after(max_sum_Unstable)

//total completed unstable spells 
bysort id (obs_no): egen spells=sum(spell_ch) 
order spells, after(spell_ch)

*split person spells 
replace id=-id if sum_spells>0 & sum_Unstable>1 & sum_perman[_n-1]>0 //new
g persnr_abs=abs(id) //new
*

sort persnr_abs id sum_spells min_begepi max_endepi obs_no 

*days per person-spell

sort persnr_abs id min_begepi max_endepi obs_no

bysort id sum_spells state_c (obs_no): g int sum_days=sum(days) 

bysort id sum_spells state_c (obs_no): egen max_days=max(sum_days) 

sort persnr_abs min_begepi max_endepi

gen samesame =(persnr_abs!=persnr_abs[_n+1])
order samesame, after(persnr_abs)



//bysort id: keep if _n==1 
//g year=year(min_begepi) 

// year of first temporary spell
bysort persnr_abs (obs_no) : egen min_year=min(year) if state != 2 //new
//replace missing years
bysort persnr_abs (obs_no) : egen min_year1=min(min_year)
replace min_year1 = year if min_year1 ==. & state == 2
order min_year1, after(year)

drop min_year 
rename min_year1 min_year
order id persnr_abs year obs_no state_c min_begepi max_endepi

//drop if min_year<2011 //use only data from 2011 onwards
drop persnr_abs 

* this is the key variable for the number of completed unstable spells
g max_TC_sample = spells
// 2+ spells = 2 spells
replace max_TC_sample = 2 if max_TC_sample > 2

g persnr_abs=abs(id) 
sort persnr_abs min_begepi max_endepi state days cycle_days sum_spells duplicate firmID source employment_status part_time fixed_term midi_jobs dtin dtout //new
*
qui egen long persnr2=group(persnr_abs) 
drop persnr_abs 
rename persnr2 persnr_abs 
*
rename id id2
rename persnr_abs id 
drop days
rename max_days days 

//Outliers
drop if days>365*10&state_c=="TU"&$no_outliers==1 //spells lasting longer than 10 years

rename dtin begepi
rename dtout endepi
rename min_begepi dtin
rename max_endepi dtout

sort id state_c
g n_TC_sample = sum_spells
sort id dtin dtout

// state string variable for descriptive statistics
qui g str state_str = ""
replace state_str = "P" if state==2
replace state_str = "T" if state==3
replace state_str = "U" if state==1
replace state_str = "U" if state==4


* Distinguish between those with pc always and those with one incomplete unstable spell

* Number of completed stable spells
gen NoP = (state_c=="P") //also ongoing spells
by id: replace NoP= sum(NoP)


* only permanent spells - attached workers
g attached1 = 1 if max_TC_sample == 0 & samesame==1 & state_c == "P" & NoP!= 0
order attached1, after(state_c)
replace attached1 = 0 if attached1 == .
bysort id: egen attached= max(attached1)
drop attached1
order attached, after(state_c)

// only temporary spells - unattached workers
g unattached1 = 1 if max_TC_sample == 0 & samesame==1 & state_c == "TU"  & NoP== 0
order unattached1, after(state_c)

bysort id: egen unattached = max(unattached1)
order unattached, after(state_c)
replace unattached = . if spells!=0
replace unattached = 0 if unattached == .
drop unattached1


sort id state_c dtin dtout
by id state_c: gen n_TC = _n if state_c == "TU"
by id state_c: gen n_PC = _n if state_c == "P"


sort id jobcount dtin dtout
* total number of temp jobs, not necessarily completed spells
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .
egen max_PC = max(n_PC), by(id)
replace max_PC = 0 if max_PC == .

by id: replace n_PC = n_PC[_n-1] if n_PC == .
replace n_PC = 0 if n_PC == .
by id: replace n_TC = n_TC[_n-1] if n_TC == .
replace n_TC = 0 if n_TC == .

bysort id2 sum_spells state_c (obs_no): gen byte _first_seg = (_n==1)
gen _dp  = days if state==2      & _first_seg
gen _dtu = days if state_c=="TU" & _first_seg

*days in permanent
bysort id: egen days_p  = total(_dp)
gen days_if_P = days if state_c=="P" 

* days in temp or unemployed
bysort id: egen days_tu = total(_dtu)
gen days_if_TU = days if state_c=="TU" 


drop _first_seg _dp _dtu

compress
save "$data/05_descriptives.dta", replace

clear
log close

