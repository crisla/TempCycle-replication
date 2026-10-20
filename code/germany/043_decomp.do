cap log close
log using "$log/043_decomp.log", replace


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation 
	
	Do-File for Variance Decomposition where majority of spells is temp 
	(i.e. share of total spell spent in a temp job >= 0.25).

	This do-file performs the baseline variance decomposition following the 
	non-parametric decomposition developed by Alvarez, Borovickova 
	and Shimer (2014).
	
	Table 13 gives the variance decomposition without outliers with the following
	parameters:
	lsig_y2 - the total variance
	sig_x - spell number
	lsig_c - the constant macro component
	lsig_e2 - duration dependence (excess variance estimator)
	lsig_b2 - heterogeneity (between variance)
	lpsig_c - share constant
	lpsig_x - share spell number
	lpsig_e - share duration dependence
	lpsig_b - share heterogeneity
	mu_y - average duration (individual mean days)
	sig_y - variance of level days
	
	Jenny Peters


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

use "$data/037_decomp.dta", clear

* only those with spells made up of a quarter of temp employment
keep if state_c=="TU"&max_TC_sample==2&n_TC_sample<2&spell_ch[_n+1]==1&share_t>=0.25
bysort id: g num=_N
bysort id: g count = _n
keep if num == 2 //some of them only have one of the spells in majority temp



*individual mean days
//by id: g mu_i = (days[1]+days[2])/2 if n_TC==2
by id: egen mu_i = mean(days)
by id: replace mu_i = . if count==1
*-*-*-* mu hat bar y *-*-*-*

egen N = count(mu_i)
*sample mean days
egen mu_y = mean(mu_i)

*-*-*-* sigma i hat *-*-*-*
*indiv variance
by id : gen sig_i = ((days[1]-days[2])^2)/2 if count==2

*-*-*-* sigma y bar hat *-*-*-*
*average variance
by id : gen sigyi = days[1]^2 + days[2]^2 - 2*mu_y^2 if mu_i!=.

gen sig_y = sum(sigyi)/(2*N-1)
replace sig_y = sig_y[_N]

*-*-*-* sigma w bar hat *-*-*-*
*within variance
egen sig_w = mean(sig_i)

*-*-*-* sigma b bar hat *-*-*-*
*between variance
by id : gen sigbi = mu_i^2 - 0.5*sig_i - mu_y^2 + (1/(2*N))*sig_y
egen sig_b = mean(sigbi)

*-*-*-* sigma c bar hat *-*-*-*
*constant macro component
by id : gen sigci = mu_i^2 - 0.5*sig_i
egen sig_c = mean(sigci)

*-*-*-* sigma e bar hat *-*-*-*
*excess variance estimator
by id : gen sigei = (3/2)*sig_i - mu_i^2
egen sig_e = mean(sigei)

*-*-*-*-*-*-*-*-*-*-*-* 4.2 LOGS DECOMPOSITION *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

gen ldays = log(days)

*-*-*-* mu hat i *-*-*-*

by id : gen lmu_i = (ldays[1]+ldays[2])/2 if count==2
by id : replace lmu_i = . if count==1

*-*-*-* mu hat bar y *-*-*-*

egen lmu_y = mean(lmu_i)

*-*-*-* sigma i hat *-*-*-*

by id : gen lsig_i = ((ldays[1]-ldays[2])^2)/2 if count==2
replace lsig_i=. if count==1

*-*-*-* sigma y bar hat *-*-*-*

by id: gen lsigyi = ldays[1]^2 + ldays[2]^2 - 2*lmu_y^2 if lmu_i!=.

gen lsig_y = sum(lsigyi)/((2*N)-1)
replace lsig_y = lsig_y[_N]

*-*-*-* sigma w bar hat *-*-*-*

gen lsig_w = sum(lsig_i)/N
replace lsig_w = lsig_w[_N]

*-*-*-* sigma b bar hat *-*-*-*

by id : gen lsigbi = lmu_i^2 - 0.5*lsig_i - lmu_y^2 + (1/(2*N))*lsig_y
gen lsig_b = sum(lsigbi)/N
replace lsig_b = lsig_b[_N]

*-*-*-* sigma e bar hat *-*-*-*

gen lsig_e = lsig_w - (c(pi)^2)/6

gen lsig_c = (c(pi)^2)/6

*-*-*-* Saving results *-*-*-*

gen psig_c = sig_c/sig_y
gen psig_e = sig_e/sig_y 
gen psig_b = sig_b/sig_y

gen plsig_c = lsig_c/lsig_y
gen plsig_e = lsig_e/lsig_y
gen plsig_b = lsig_b/lsig_y

// sum sig_y sig_c sig_e sig_b
//
// sum psig_c psig_e psig_b
//
// sum lsig_y lsig_c lsig_e lsig_b
//
// sum plsig_c plsig_e plsig_b

*-*-*-*-*-*-*-*-*-*-*-* SPELLS CONTROL DECOMPOSITION *-*-*-*-*-*-*-*-*-*-*-*-*-*

gen spell_d1=1 if count==2
replace spell_d = 0 if count ==1

qui reg ldays spell_d

predict res, r

replace res = 0 if res==.

*-*-*-* mu hat bar eps *-*-*-*

sort id count
by id: gen resi = (res[1]^2+res[2]^2)/2 if _n==2
by id: replace resi = . if [_n]!=2
gen sigma_eps = sum(resi)/(N-1)
replace sigma_eps = sigma_eps[_N]

*-*-*-* sigma hat y *-*-*-*

by id : gen lmu_i2 = (ldays[1]+ldays[2])/2 
by id: replace lmu_i2 = . if [_n]!=2
egen mu_y2 = mean(lmu_i)

by id : gen lsy = ((ldays[1]-mu_y2)^2 + (ldays[2]-mu_y2)^2)/(2*N-1)
by id: replace lsy = . if [_n]!=2

gen lsig_y2 = sum(lsy)
replace lsig_y2 = lsig_y2[_N]

gen sig_x = lsig_y2-sigma_eps


*-*-*-* sigma w bar hat *-*-*-*

by id: gen lsigi2 = (N*(res[1]-res[2])^2)/(2*(N-1))
egen lsig_w2 = mean(lsigi2)

*-*-*-* sigma b bar hat *-*-*-*

gen lsig_b2 = sigma_eps - lsig_w2

*-*-*-* sigma e bar hat *-*-*-*

gen lsig_e2 = lsig_w2 - (c(pi)^2)/6

gen lpsig_x= sig_x/lsig_y2
gen lpsig_e = lsig_e2/lsig_y2
gen lpsig_b = lsig_b2/lsig_y2

// sum lpsig_x lpsig_e lpsig_b


quietly gen lpsig_c = 1 - lpsig_x - abs(lpsig_e) - lpsig_b

// Print results: 
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Table 4 gives the variance decomposition with the following
parameters:
	lsig_y2 - the total variance
	sig_x - spell number
	lsig_c - the constant macro component
	lsig_e2 - duration dependence (excess variance estimator)
	lsig_b2 - heterogeneity (between variance)
	lpsig_c - share constant
	lpsig_x - share spell number
	lpsig_e - share duration dependence
	lpsig_b - share heterogeneity
	mu_y - average duration (individual mean days)
	sig_y - variance of level days
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
di "Table 4: Variance Decomposition Majority Temp"
sum lsig_y2 sig_x lsig_c lsig_e2 lsig_b2 lpsig_c lpsig_x lpsig_e lpsig_b mu_y sig_y



clear
log close
