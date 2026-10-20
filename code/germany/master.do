
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	YOU NEED THE MICRODATA TO RUN THIS FILE

	The SIAB is confidential and is NOT distributed with this replication
	package. It is also never delivered to a researcher's own machine: these
	do-files are written to run INSIDE the FDZ environment. The approved,
	disclosure-cleared .log output they produce ships in
	data/intermediate/germany/, so the paper's tables can be rebuilt with
	`python run_all.py` WITHOUT running this file.

	WHAT TO REQUEST
	  Sample of Integrated Labour Market Biographies, SIAB 7521 version 1
	  (1975-2021). DOI 10.5164/IAB.SIAB7521.de.en.v1

	WHERE TO REQUEST IT
	  Forschungsdatenzentrum (FDZ) of the Bundesagentur fuer Arbeit at the
	  IAB. Send a data application to iab.fdz@iab.de. Access needs
	  project-specific approval, is limited to non-commercial empirical
	  research at scientific institutions, and can take around four weeks.
	  Access is on-site in Nuremberg or via an FDZ remote-access point, with
	  remote execution through JoSuA. Current instructions: fdz.iab.de
	  See data/raw/README.md in this package for the full details.

	WHERE TO SAVE IT
	  Not applicable locally -- the data stay in the FDZ environment. Place
	  these do-files in that environment's prog/ folder and set the working
	  directory below.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	SIAB Preparation

	Master Do-File for the Project Unstable Employment Cycles

	
	User: Jenny Peters

	// set up environment so it mimics the FDZ/JoSuA setting
	note: do not uncomment when uploading files to JoSuA, only for at-home
	use in test environment. 
	
	cd "/Volumes/My Passport for Mac/Temp_Cycles JJ/Do-Files"

	//create subfolders in wd
	shell mkdir prog
	shell mkdir log
	shell mkdir data
	shell mkdir orig
	
	global prog = "prog" // folder for do-files
	global log  = "log"  // folder for log-files and graphs
	global orig = "orig" // folder for original datasets
	global data = "data" // folder for generated datasets
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

version 17 
clear
set more off     

set linesize 120   // maximum linesize Internal Use
*set linesize 255    // maximum linesize Presentation/Publication

* Outliers: No spells longer than 10 years? change to 1.
* No spells longer than 10 years and less than 12 jobs each (unstable) spell? change to 2. 
global no_outliers = 0


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Cleaning Data and creating entire spells
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


* do "$prog/01_clean.do"

* do "$prog/02_entire_spells.do"


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Analysis - variance decomposition
	** Note: 03_decomp.do runs the following auxilary do files **
	1. 031_decomp_prep.do to prepare the dataset for decomposition
	2. 032_decomp_prep.dta to prepare the dataset for decomposition w/o outliers
	3. 033_decomp_prep.dta to prepare the dataset for decomposition by sex 
	4. 034_decomp_prep.dta to prepare the dataset for decomposition with
	business cycle controls
	5. 035_decomp_prep.do to prepare the dataset for decomposition with only
	mini jobs
	6. 036_decomp_prep to prepare the dataset for decomposition with only temp	
	contracts
	7. 031_decomp.do to run the baseline decomposition (diff time windows)
	8. 032_decomp.do to run the baseline decomposition w/o outliers
	9. 033_decomp.do decomposition by sex
	10. 034_decomp.do to run the decomposition by age 
	11. 035_decomp.do with age controls
	12. 036_decomp.do with education controls
	13. 037_decomp.do - 039_decomp.do business cycle controls
	14. 040_decomp.do decomposition with mini jobs only
	15. 041_decomp.do decomposition with temp contracts only
	16. 042_decomp.do decomposition with majority mini
	17. 043_decomp.do decomposition with majority temp
	18. 044_decomp.do decomposition with majority unemp
	
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

* do "$prog/03_decomp.do"

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Descriptive Statistics
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

* do "$prog/04_graphs.do"

do "$prog/05_descriptives.do"

* do "$prog/06_cleanup.do"


capture log close
log using "$log/filelist.log", replace

dir "$orig/"
dir "$data/"
dir "$prog/"								
dir "$log/"								
log close

