* If you use the Remote Desktop Access, please note that you can delete files in the additional remote subfolders separately and only during Remote Desktop Access. 

capture log close                                                               // Use this command immediately before opening a new log file
log using "$log/06_cleanup.log", replace                                      // Give the log-file the same name as the do-file   

* Cleaning up the data folder
* Delete temporary data files that are no longer needed

* Delete files:
capture erase "$data/01_prep.dta"
capture erase "$data/02_Unstable_TempC_2011.dta"
capture erase "$data/031_decomp1_2011.dta"
capture erase "$data/031_decomp1_2014.dta"
capture erase "$data/031_decomp1_2016.dta"
capture erase "$data/031_decomp2.dta"
capture erase "$data/03_female.dta"
capture erase "$data/03_male.dta"
capture erase "$data/03_inter.dta"
capture erase "$data/03_MargEmp_TC_2011.dta"
capture erase "$data/03_ME_TC_2011.dta" 
capture erase "$data/03_monthly.dta"
capture erase "$data/03_monthly_collapsed.dta" 
capture erase "$data/03_monthly_collapsed_female.dta"  
capture erase "$data/03_monthly_collapsed_male.dta" 
capture erase "$data/03_NE_2011.dta"
capture erase "$data/03_NE_TC_2011.dta"
capture erase "$data/03_NonEmp_2011.dta"
capture erase "$data/03_NonEmp_TC_2011.dta"
capture erase "$data/03_PermEmp_2011.dta"
capture erase "$data/03_PermEmp_TC_2011.dta"
capture erase "$data/03_PE_2011.dta"
capture erase "$data/03_PE_TC_2011.dta"
capture erase "$data/03_temporary_2011.dta"
capture erase "$data/03_temp_2011.dta"
capture erase "$data/03_Unstable_1_Spell_2011.dta"
capture erase "$data/03_Unstable_TC_2011.dta"
capture erase "$data/060_decomp.dta"
capture erase "$data/061_decomp.dta"
capture erase "$data/071_decomp.dta"
capture erase "$data/072_decomp.dta"
capture erase "$data/072_decomp_m.dta"
capture erase "$data/072_decomp_w.dta"
capture erase "$data/073_decomp.dta"
capture erase "$data/073_decomp_m.dta"
capture erase "$data/073_decomp_w.dta"
capture erase "$data/074_decomp.dta"
capture erase "$data/082_decomp_men.dta"
capture erase "$data/082_decomp_women.dta"

log close

