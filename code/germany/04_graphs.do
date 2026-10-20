cap log close                                                 					
log using "$log/04_graphs.log", replace         

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	SIAB Preparation
	
	Unstable Employment Cycles
	Do-File for Descriptive Statistics of SIAB Data

	Structure of file:
	The file creates graphs used for descriptive statistics of spells:
	Histograms of pure spells (durations) for all unstable spells, only 
	unemployed and non-employed, only marginal employment, and temporary 
	employment. It also creates a survival plot (2 spells per person) 
	of unstable spells.
	
	User: Jenny Peters
	


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
* No spells longer than 10 years & less than 12 jobs each (unstable) spell? change to 2.
global no_outliers = 0
global post_2011 = 1


// Same individuals as in decomposition, but all of their spells
use "$data/05_descriptives.dta", clear
drop if min_year<2011 //use only data from 2011 onwards

g max_months = days/30

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Graph 1: plotting a histogram of months spent in unstable spell: either 
unemployed, non-employed, or in marginal employment, 2+ spells per person,
sample includes unfinished spells

NOTE: adjustment so frequencies in each bin are > 20: Right-censoring the data, 
bunching spell durations longer than 135 months into one.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


// right-censoring:
g months_adj = max_months
replace months_adj = 135 if months_adj > 135


// Graph 1
hist months_adj, graphregion(color(white)) xtitle(" " "Months") ///
ytitle("Density" " ") title("Histogram of Unstable Spells") 
* save frequencies to variable _freq -> number of obs in each bin (same spec as histogram)
twoway__histogram_gen months_adj, gen(_freq x, replace) display freq      
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Table 1: Documenting the total number of observations this is based on, 
following the guide. Here, _freq is the number of obs in each bin.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
sum _freq
graph export "$log/04_graphs_01_hist_mixed_all.png", replace


cap log close








