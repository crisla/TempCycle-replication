*aggregate
*https://ec.europa.eu/eurostat/web/lfs/data/database
cls
set more off
cd "C:\Users\manuz\Desktop\Projects\ABS_HMCM"
clear
*
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\une_rt_a.tsv", varnames(1) clear 
foreach v of varlist _all {
local x : variable label `v'
rename `v' lab`x'
}
*
g age=substr(labage,1,6)
g sex=substr(labage,15,1)
g country=substr(labage,17,2)
*
drop labage
order age sex country
*
foreach v of varlist lab* {
local x : variable label `v'
*ereplace `v' = sieve(`v'), keep(numeric)
replace `v' = subinstr(`v',"b","",.)
replace `v' = subinstr(`v',"e","",.)
destring `v', gen(real_`v') force
*g real_`v'=real(`v')
}
*
keep if age=="Y25-54"
drop if country!="DE" & country!="ES"
keep if sex=="T"
*
drop lab*
rename real_lab* unemp_* 

preserve
keep if country=="DE"
drop age sex country
*
xpose, clear
g unemp_rate_DE=(v1+v2)/2
drop v1 v2
g year=2020-_n
sort year

save unemp_DE.dta, replace
restore

preserve
keep if country=="ES"
drop age sex country
*
xpose, clear
g unemp_rate_ES=(v1+v2)/2
drop v1 v2
g year=2020-_n
sort year

save unemp_ES.dta, replace
restore

use unemp_ES.dta, clear
merge 1:1 year using unemp_DE.dta, nogen
save unemp_both.dta, replace

*https://www.imf.org/external/datamapper/NGDP_RPCH@WEO/EU/DEU/ESP
cls
set more off
clear
*
import excel "C:\Users\manuz\Desktop\Projects\ABS_HMCM\imf-dm-export-20201114 (1).xls", sheet("NGDP_RPCH") firstrow clear
*
foreach v of varlist B-AU {
local x : variable label `v'
rename `v' y`x'
}
rename RealGDPgrowthAnnualpercent country
*
preserve
keep if country=="Germany"
drop country
*
xpose, clear
rename v1 real_gdp_growth_DE
g year=1979+_n

save real_gdp_growth_DE.dta, replace
restore
*
preserve
keep if country=="Spain"
drop country
*
xpose, clear
rename v1 real_gdp_growth_ES
g year=1979+_n

save real_gdp_growth_ES.dta, replace
restore

use real_gdp_growth_ES.dta, clear
merge 1:1 year using real_gdp_growth_DE.dta, nogen
save real_gdp_growth_both.dta, replace

use unemp_both.dta, clear
merge 1:1 year using real_gdp_growth_both.dta, nogen
label variable unemp_rate_DE "Germany"
label variable unemp_rate_ES "Spain"
label variable year "Year"
line unemp_rate_DE unemp_rate_ES year if year>=1999 & year<=2019, lwidth(medthick medthick) legend(col(1) ring(0) pos(11)) ytitle("") title("Unemployment Rate (%)") ylabel(, format(%3.1f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\unemp_rate.png", replace

use real_gdp_growth_both.dta, clear
merge 1:1 year using real_gdp_growth_both.dta, nogen
label variable real_gdp_growth_DE "Germany"
label variable real_gdp_growth_ES "Spain"
label variable year "Year"
line real_gdp_growth_DE real_gdp_growth_ES year if year>=1999 & year<=2019, lwidth(medthick medthick) legend(col(1) ring(0) pos(8)) ytitle("") title("Real GDP Growth (%)") ylabel(-4 (2) 4, format(%3.1f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\real_gdp_growth.png", replace

*
// oecd temporary employment data
// https://data.oecd.org/emp/temporary-employment.htm
// https://stats.oecd.org/Index.aspx?DataSetCode=TEMP_I
// https://stats.oecd.org/Index.aspx?DataSetCode=EPL_OV
// http://www.oecd.org/els/emp/LFS%20Definitions%20-%20Tables.pdf

*Temporary
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\TEMP_I_01022021203411954.csv", encoding(UTF-8) clear
keep if v4=="All persons"
keep if age==2554
keep if v10=="Share of temporary employment"
rename v14 year
preserve
keep year value v2
keep if v2=="Germany"
rename value temp_DE
save temp_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value temp_ES
save temp_ES.dta, replace
restore

*Marginally attached
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\MA_I_01022021205413205.csv", encoding(UTF-8) clear
keep if v4=="All persons"
keep if age==2554
rename v16 year
keep if v14=="Share of labour force"
preserve
keep year value v2
keep if v2=="Germany"
rename value MA_DE
save MA_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value MA_ES
save MA_ES.dta, replace
restore

*PT
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\FTPTC_I_01022021205201641.csv", encoding(UTF-8) clear
keep if series=="PT"
keep if v4=="All persons"
keep if age==2554
rename v14 year
keep if employmentstatus=="Dependent employment"
preserve
keep year value v2
keep if v2=="Germany"
rename value part_DE
save part_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value part_ES
save part_ES.dta, replace
restore

*FT
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\FTPTC_I_01022021205201641.csv", encoding(UTF-8) clear
keep if series=="FT"
keep if v4=="All persons"
keep if age==2554
rename v14 year
keep if employmentstatus=="Dependent employment"
preserve
keep year value v2
keep if v2=="Germany"
rename value full_DE
save full_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value full_ES
save full_ES.dta, replace
restore

use temp_DE.dta, clear
merge 1:1 year using temp_ES.dta, nogen
merge 1:1 year using MA_DE.dta, nogen
merge 1:1 year using MA_ES.dta, nogen
merge 1:1 year using part_DE.dta, nogen
merge 1:1 year using part_ES.dta, nogen
merge 1:1 year using full_DE.dta, nogen
merge 1:1 year using full_ES.dta, nogen
merge 1:1 year using ME.dta, nogen
label variable temp_DE "Temp - DE"
label variable temp_ES "Temp - ES"
label variable MA_DE "Marginal - DE"
label variable MA_ES "Marginal - ES"
label variable part_DE "PT - DE"
label variable part_ES "PT - ES"
label variable full_DE "FT - DE"
label variable full_ES "FT - ES"
label variable ave_tstock_ME_share "Marginal - DE"
label variable year "Year"
replace ave_tstock_ME_share=ave_tstock_ME_share*100
// line temp_DE temp_ES MA_DE MA_ES full_DE full_ES year if year>=1999 & year<=2019, lcolor(black black red red green green) lpattern(solid dash solid dash solid dash ) legend(pos(3))  legend(col(1)) ytitle("") title("Indidences (%)") ylabel(0 (10) 100, format(%3.0f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle({bf:Months}, size(vlarge) height(7)) graphregion(color(white))
// graph export emp_stock.png, replace
line temp_DE temp_ES ave_tstock_ME_share full_DE full_ES year if year>1999 & year<=2019, lcolor(black black red blue blue) lpattern(solid dash solid dash solid dash ) legend(pos(3))  legend(col(1)) ytitle("") title("Incidence (%)") ylabel(0 (10) 100, format(%3.0f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\emp_stock.png", replace

/*
Marginally attached are persons aged 15 and over, neither employed, nor actively looking for work, 
but are willing/desire to work and are available for taking a job during the survey reference week. Additionally, when this applies, they have looked for work during the past 12 months.
*/

*Unemployment Duration:
// cls
// set more off
// clear all
// import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\AVD_DUR_05022021130105069.csv", encoding(UTF-8) 
// keep if v4=="All persons"
// keep if age==2554
// rename v10 year
// preserve
// keep year value v2
// keep if v2=="Germany"
// rename value udur_DE
// save udur_DE.dta, replace
// restore
// preserve
// keep year value v2
// keep if v2=="Spain"
// rename value udur_ES
// save udur_ES.dta, replace
// restore
//
// use udur_DE.dta, clear
// merge 1:1 year using udur_ES.dta, nogen
// label variable udur_DE "Germany"
// label variable udur_ES "Spain"
// line udur_DE udur_ES year if year>1999 & year<=2019, lcolor(brown orange) lpattern(solid dash) legend(pos(3))  legend(col(1)) ytitle("") title("Unemployment duration") ylabel(, format(%3.0f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
// graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\emp_stock.png", replace

*Indicence of Unemployment by Duration:
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\DUR_I_05022021131937757.csv", encoding(UTF-8) clear 
keep if v4=="All persons"
keep if age==2554
rename v12 year
keep if v8=="< 1 month"
preserve
keep year value v2
keep if v2=="Germany"
rename value be1m_DE
save be1m_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value be1m_ES
save be1m_ES.dta, replace
restore
*
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\DUR_I_05022021131937757.csv", encoding(UTF-8) clear 
keep if v4=="All persons"
keep if age==2554
rename v12 year
keep if v8=="> 1 month and < 3 months"
preserve
keep year value v2
keep if v2=="Germany"
rename value one_three_DE
save one_three_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value one_three_ES
save one_three_ES.dta, replace
restore
*
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\DUR_I_05022021131937757.csv", encoding(UTF-8) clear 
keep if v4=="All persons"
keep if age==2554
rename v12 year
keep if v8=="> 6 month and < 1 year"
preserve
keep year value v2
keep if v2=="Germany"
rename value six_oney_DE
save six_oney_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value six_oney_ES
save six_oney_ES.dta, replace
restore
*
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\DUR_I_05022021131937757.csv", encoding(UTF-8) clear 
keep if v4=="All persons"
keep if age==2554
rename v12 year
keep if v8=="1 year and over"
preserve
keep year value v2
keep if v2=="Germany"
rename value ab1y_DE
save ab1y_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value ab1y_ES
save ab1y_ES.dta, replace
restore

use be1m_DE.dta, clear
merge 1:1 year using be1m_ES.dta, nogen
merge 1:1 year using one_three_DE.dta, nogen
merge 1:1 year using one_three_ES.dta, nogen
merge 1:1 year using six_oney_DE.dta, nogen
merge 1:1 year using six_oney_ES.dta, nogen
merge 1:1 year using ab1y_DE.dta, nogen
merge 1:1 year using ab1y_ES.dta, nogen
label variable be1m_DE "< 1 month"
label variable be1m_ES "< 1 month"
label variable one_three_DE "1 - 3 months"
label variable one_three_ES "1 - 3 months"
label variable six_oney_DE "6 - 12 months"
label variable six_oney_ES "6 - 12 months"
label variable ab1y_DE "> 1 year"
label variable ab1y_ES "> 1 year"
label variable year "Year"
line be1m_DE one_three_DE six_oney_DE ab1y_DE year if year>1999 & year<=2019, lcolor(black blue red orange) lpattern(solid solid solid solid solid solid) legend(pos(3))  legend(col(1)) ytitle("") title("Germany") ylabel(0(10)60, format(%3.0f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\inc_unemp_duration_GER.png", replace

line be1m_ES one_three_ES six_oney_ES ab1y_ES year if year>1999 & year<=2019, lcolor(black blue red orange ) lpattern(dash dash dash dash dash dash ) legend(pos(3))  legend(col(1)) ytitle("") title("Spain") ylabel(0(10)60, format(%3.0f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\inc_unemp_duration_ES.png", replace

*Benefits in unemployment, share of previous income
*6m
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\OECD_EPL_6m.csv", encoding(UTF-8) clear 
rename time year
rename location v2
preserve
keep year value v2
keep if v2=="DEU"
rename value sixm_DE
save sixm_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="ESP"
rename value sixm_ES
save sixm_ES.dta, replace
restore
*1y
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\OECD_EPL_1y.csv", encoding(UTF-8) clear 
rename time year
rename location v2
preserve
keep year value v2
keep if v2=="DEU"
rename value oney_DE
save oney_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="ESP"
rename value oney_ES
save oney_ES.dta, replace
restore
*2y
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\OECD_EPL_2y.csv", encoding(UTF-8) clear 
rename time year
rename location v2
preserve
keep year value v2
keep if v2=="DEU"
rename value twoy_DE
save twoy_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="ESP"
rename value twoy_ES
save twoy_ES.dta, replace
restore
*5y
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\OECD_EPL_5y.csv", encoding(UTF-8) clear 
rename time year
rename location v2
preserve
keep year value v2
keep if v2=="DEU"
rename value fivey_DE
save fivey_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="ESP"
rename value fivey_ES
save fivey_ES.dta, replace
restore

use sixm_DE.dta, clear
merge 1:1 year using sixm_ES.dta, nogen
merge 1:1 year using oney_DE.dta, nogen
merge 1:1 year using oney_ES.dta, nogen
merge 1:1 year using twoy_DE.dta, nogen
merge 1:1 year using twoy_ES.dta, nogen
merge 1:1 year using fivey_DE.dta, nogen
merge 1:1 year using fivey_ES.dta, nogen
label variable sixm_DE "6 months"
label variable sixm_ES "6 months"
label variable oney_DE "1 year"
label variable oney_ES "1 year"
label variable twoy_DE "2 years"
label variable twoy_ES "2 years"
label variable fivey_DE "5 years"
label variable fivey_ES "5 years"
label variable year "Year"
line sixm_DE oney_DE twoy_DE fivey_DE year if year>1999 & year<=2019, lwidth(vthick thin vthick thin) lcolor(black blue red orange) lpattern(". ."  dash dot dash_dot solid solid) legend(pos(3))  legend(col(1)) ytitle("") title("Germany") ylabel(20(10)80, format(%3.0f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\benef_unemp_share_GER.png", replace

line sixm_ES oney_ES twoy_ES fivey_ES year if year>1999 & year<=2019, lwidth(vthick thin vthick thin) lcolor(black blue red orange) lpattern(". ."  dash dot dash_dot solid solid) legend(pos(3))  legend(col(1)) ytitle("") title("Spain") ylabel(20(10)80, format(%3.0f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\benef_unemp_share_ES.png", replace


***EPL:
*Strictness of employment protection – individual and collective dismissals (regular contracts)
cls
set more off
clear all
import delimited "C:\Users\manuz\Desktop\Projects\ABS_HMCM\EPL_OV_09022021005947711.csv", encoding(UTF-8) clear 
keep if v4=="Version 2 (1998-2019)"
// keep if age==2554
rename v6 year
// keep if v8=="< 1 month"
preserve
keep year value v2
keep if v2=="Germany"
rename value EPL_DE
drop v2
save EPL_DE.dta, replace
restore
preserve
keep year value v2
keep if v2=="Spain"
rename value EPL_ES
drop v2
save EPL_ES.dta, replace
restore
preserve
keep year value v2
// keep if v2=="Spain"
bysort year: egen OECD=mean(value)
// rename value EPL_ES
drop v2
collapse OECD, by(year)
save OECD.dta, replace
restore
*

use EPL_DE.dta, clear
merge 1:1 year using EPL_ES.dta, nogen
merge 1:1 year using OECD.dta, nogen
label variable EPL_DE "Germany"
label variable EPL_ES "Spain"
label variable OECD "OECD"
label variable year "Year"
line EPL_DE EPL_ES OECD year if year>1999 & year<=2019, lcolor(black blue red orange) lpattern(solid solid solid solid solid solid) legend(pos(3))  legend(col(1)) ytitle("") title("Germany") ylabel(, format(%3.1f) labsize(vlarge) angle(horizontal)) xlabel(1999 (4) 2019, labsize(large) grid)  xtitle(, size(vlarge) height(7)) graphregion(color(white))
graph export "C:\Users\manuz\Documents\GitHub\TempCycle\AggregateBoth\EPL.png", replace
