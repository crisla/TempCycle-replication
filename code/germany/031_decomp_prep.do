cap log close
log using "$log/031_decomp_prep.log", replace


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation
	
	Do-File for Preparation of SIAB Data for Decomposition

	This do-file processes the dataset of entire employment spells, identifying 
	periods of unstable employment and it generating the dataset to be used for 
	the variance decomposition (two unstable spells with stable employment in 
	between).
	
	Jenny Peters

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


use "$data/02_entirespells", clear

sort id min_begepi max_endepi state days cycle_days duplicate firmID source employment_status part_time fixed_term midi_jobs

gen long obs_no = _n

order id obs_no age

drop if age<25 | age >=55

sort id min_begepi max_endepi state days cycle_days duplicate firmID source employment_status part_time fixed_term midi_jobs obs_no

order id min_begepi max_endepi state days cycle_days duplicate firmID source employment_status part_time fixed_term midi_jobs obs_no

drop Unstable sum_Unstable spell spell_ch sum_spells spells max_sum_Unstable cmin_begepi cmax_endepi cycle_days



bysort id (obs_no): g Unstable=1 if state==4 | state==1 | state==3
bysort id (obs_no): egen sum_Unstable=sum(Unstable)
bysort id (obs_no): egen max_sum_Unstable=max(sum_Unstable)

g byte spell=.
replace spell=1 if state==2
replace spell=2 if state==4 & spell==.
replace spell=3 if state==1 & spell==.
replace spell=4 if state==3 & spell==.

bysort id (obs_no): g spell_ch1=1 if spell[_n-1]>1 & spell[_n-1]<5 & spell==1 & sum_Unstable>0



order id obs_no state_c spell_ch min_begepi max_endepi

bysort id (obs_no): gen sum_spells=sum(spell_ch)
bysort id sum_spells (obs_no): egen int cmin_begepi=min(min_begepi) 
bysort id sum_spells (obs_no): egen int cmax_endepi=max(max_endepi)  
g int cycle_days=cmax_endepi-cmin_begepi  

sort id min_begepi max_endepi state days cycle_days sum_spells duplicate firmID source employment_status part_time fixed_term midi_jobs obs_no  

order id obs_no state_c spell_ch sum_spells max_sum_Unstable min_begepi max_endepi

* drop if less than 2 unstable spells
drop if max_sum_Unstable<2  

bysort id (obs_no): g sum_perman=sum(state==2) if sum_Unstable>0  
bysort id (obs_no): egen max_sum_perman=max(sum_perman)  

order id obs_no state_c spell_ch min_begepi max_endepi sum_perman max_sum_perman

drop if max_sum_perman<1 //less than 1 permanent spell

//total spells  
bysort id (obs_no): egen spells=sum(spell_ch)  
order spells, after(spell_ch)
drop if spells<2 //less than two changes in spells
order sum_spells, after(spell_ch)
*spell ordering
drop if sum_spells>1 //only the first two spells
*split person spells 


replace id=-id if sum_spells>0 & sum_Unstable>1 & sum_perman[_n-1]>0  
g persnr_abs=abs(id)  
*
order id, after(persnr_abs)
sort persnr_abs id sum_spells min_begepi max_endepi obs_no  
*days per person-spell
bysort id (obs_no): keep if state!=2 //remove permanent employment
sort persnr_abs id min_begepi max_endepi obs_no
bysort id (obs_no): g int sum_days=sum(days) if state!=2 //all days in marg/temp employment
order days, after(state_c)
order sum_days, after(days)
bysort id (obs_no): egen max_days=max(sum_days) if state!=2  
order max_days, after(sum_days)

sort persnr_abs


bysort id (obs_no): keep if _n==1  


sort persnr_abs
order id persnr_abs year

//order year, after(id)
//g year=year(min_begepi) 
bysort id: egen min_year=min(year)
//bysort persnr_abs (obs_no): egen min_year=min(year) same if i sort by id or persnr abs and obs no
drop if min_year< $currentyear
drop persnr_abs  




g persnr_abs=abs(id)  
sort persnr_abs min_begepi max_endepi state days cycle_days sum_spells duplicate firmID source employment_status part_time fixed_term midi_jobs dtin dtout obs_no  
*
qui egen long persnr2=group(persnr_abs)  

order id persnr_abs persnr2
drop persnr_abs  
rename persnr2 persnr_abs  
*
rename id id2
rename persnr_abs id  
//rename days days1  
drop days
rename max_days days  
replace days = 1 if days == 0 
//Outliers
drop if days>365*10&state_c=="TU"&$no_outliers==1 //spells lasting longer than 10 years

// Counting number of cycles left
bysort id (obs_no): g byte n_TC=_n  
order id n_TC days  

drop if id==.  
sort id n_TC obs_no  
egen max_TC = max(n_TC), by(id)
replace max_TC = 0 if max_TC == .

// Keep only the first 2 spells
sort id dtin dtout obs_no
// keep if max_TC>1
keep if n_TC<3&max_TC>1&state_c=="TU"


compress
save "$data/031_decomp_$currentyear.dta", replace


clear
log close
