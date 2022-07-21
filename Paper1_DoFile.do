clear

************************Dataset Building************************

**Load UCDP Data**
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\ucdp-prio-acd-211.dta" 

**Destring Relevant Variables**
destring year, replace
destring type_of_conflict, replace

**Drop Non-Civil War Cases**
keep if type_of_conflict == 3

**Create a Civil War Variable**
gen civil_war = 1

**Rename State Identifier to ccode to Merge With COW States Data**
rename gwno_a ccode
destring ccode, replace

**Collapse UCDP Data So That Each Country Has One Observation Per Year**
sort ccode year
collapse (max) civil_war, by(ccode year)

**Merge UCDP Data With COW States Data to Include Peace Years**
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Data\COWCountries.dta" 

**Create a Prior Civil War Variable to Identify Cases That Have Experienced a Civil War in the Past**
gen prior_civil_war = civil_war

**Use the Carryfoward Command to Identify All Cases That Have Experienced Civil War Beyond The Country-Year Observations Experiencing Civil War**
sort ccode year
by ccode: carryforward prior_civil_war, replace

**Merge On-and-Off Conflicts Into a Single Conflict Spell**
replace civil_war = 0 if civil_war == .
replace civil_war = 1 if civil_war[_n-1] == 1 & civil_war[_n+1] == 1

**Recode Coups as non-Civil War Observations (Thyne 2017)**
replace civil_war = 0 if ccode == 145 & year == 1952
replace civil_war = 0 if ccode == 150 & year == 1954
replace civil_war = 0 if ccode == 150 & year == 1989
replace civil_war = 0 if ccode == 90 & year == 1954
replace civil_war = 0 if ccode == 800 & year == 1951
replace civil_war = 0 if ccode == 530 & year == 1960
replace civil_war = 0 if ccode == 481 & year == 1964
replace civil_war = 0 if ccode == 516 & year == 1965
replace civil_war = 0 if ccode == 452 & year == 1966
replace civil_war = 0 if ccode == 452 & year == 1981
replace civil_war = 0 if ccode == 452 & year == 1983
replace civil_war = 0 if ccode == 652 & year == 1966
replace civil_war = 0 if ccode == 625 & year == 1971
replace civil_war = 0 if ccode == 625 & year == 1976
replace civil_war = 0 if ccode == 600 & year == 1971
replace civil_war = 0 if ccode == 500 & year == 1974
replace civil_war = 0 if ccode == 155 & year == 1973
replace civil_war = 0 if ccode == 450 & year == 1980
replace civil_war = 0 if ccode == 420 & year == 1981
replace civil_war = 0 if ccode == 501 & year == 1982
replace civil_war = 0 if ccode == 471 & year == 1984
replace civil_war = 0 if ccode == 680 & year == 1986
replace civil_war = 0 if ccode == 439 & year == 1987
replace civil_war = 0 if ccode == 581 & year == 1989
replace civil_war = 0 if ccode == 95 & year == 1989
replace civil_war = 0 if ccode == 41 & year == 1989
replace civil_war = 0 if ccode == 41 & year == 1991
replace civil_war = 0 if ccode == 373 & year == 1995

**Generate Civil War Recurrence (Failure) Variable**
by ccode: gen failure = 1 if civil_war[_n-1] == 0 & civil_war[_n] == 1
replace failure = 0 if failure == .

**Replace Civil War = 0 if the Hazard Variable = 1 so That These Observations Will Not Be Dropped Later**
replace civil_war = 0 if failure == 1

**Drop Unecessary Data**
drop if prior_civil_war == .
drop if civil_war == 1
*7 Observations in Total That Create Artificial Temporal Gaps in the Data*
drop if _merge == 1 

**Create Peace Spells Variable*
sort ccode year
by ccode: gen new_case = 1 if failure == 0 & failure[_n-1] == 1
sort ccode year
by ccode: gen sum_cases = sum(new_case)
gen spell_identifier = (sum_cases*1000) + ccode
gen spell_count = sum_cases
drop new_case
drop sum_cases

**Drop Unecessary Variables**
drop civil_war version _merge prior_civil_war

**Drop First Observations for Each Country Given That Each Country Enters the Dataset With the First Peace Failure**
sort ccode year
by ccode: drop if _n == 1

******* Base Dataset Completed *******
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\1-BaseConflictRecurrenceData.dta", replace

**Set Up and Merge UCDP Battle Deaths Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\ucdp-prio-acd-211.dta" 
destring year, replace
destring type_of_conflict, replace
keep if type_of_conflict == 3
rename gwno_a ccode
destring ccode, replace
destring cumulative_intensity, replace
sort ccode year
collapse (max) cumulative_intensity, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\1-BaseConflictRecurrenceData.dta"
sort ccode year
by ccode: carryforward cumulative_intensity, replace
drop if _merge == 1 
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\2-BaseConflictRecurrenceData.dta", replace

**Set Up and Merge UCDP War Duration Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\ucdp-prio-acd-211.dta" 
destring year, replace
destring type_of_conflict, replace
keep if type_of_conflict == 3
rename gwno_a ccode
destring ccode, replace
sort ccode year
by ccode: gen war_duration = _n
collapse (max) war_duration, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\2-BaseConflictRecurrenceData.dta"
sort ccode year
by ccode: carryforward war_duration, replace
by ccode: replace war_duration = war_duration[_n-1] if failure == 1
drop if _merge == 1 
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\3-BaseConflictRecurrenceData.dta", replace

**Set Up and Merge UCDP War Outcome Data**
clear 
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\ucdp-prio-conflict-termination.dta"
destring year, replace
destring type_of_conflict, replace
keep if type_of_conflict == 3
rename gwno_loc ccode
destring ccode, replace
gen peace_agg = 1 if outcome == 1
replace peace_agg = 0 if peace_agg == .
sort ccode year
collapse (max) peace_agg, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\3-BaseConflictRecurrenceData.dta"
sort ccode year
by ccode: carryforward peace_agg, replace
drop if _merge == 1
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\4-BaseConflictRecurrenceData.dta", replace

**Set Up and Merge UCDP Conflict Type Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\ucdp-prio-conflict-termination.dta"
destring year, replace
destring type_of_conflict, replace
keep if type_of_conflict == 3
rename gwno_loc ccode
destring ccode, replace
gen territory = 1 if incompatibility != 2
replace territory = 0 if territory == .
sort ccode year
collapse (max) territory, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\4-BaseConflictRecurrenceData.dta"
sort ccode year
by ccode: carryforward territory, replace
drop if _merge == 1
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\5-BaseConflictRecurrenceData.dta", replace

**Set Up and Merge UCDP PKO Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\MullenbachPKOData.dta"
keep if TPTYPE == 1
rename CCODE1 ccode
gen case=_n
gen duration = ENDYR - STARTYR + 1
expand duration
sort case
by case: gen time = _n
gen year = STARTYR + time - 1
sort ccode year
gen PKO = 1 
collapse (max) PKO, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\5-BaseConflictRecurrenceData.dta"
sort ccode year
by ccode: carryforward PKO, replace
drop if _merge == 1
drop _merge
replace PKO = 0 if PKO == .
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\6-BaseConflictRecurrenceData.dta", replace

**Set Up and Merge UCDP Number of Warring Parties Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\ucdp-prio-conflict-termination.dta"
destring year, replace
destring type_of_conflict, replace
keep if type_of_conflict == 3
rename gwno_loc ccode
destring ccode, replace
gen civil_war = 1
replace civil_war = 0 if civil_war == .
replace civil_war = 1 if civil_war[_n-1] == 1 & civil_war[_n+1] == 1
replace civil_war = 0 if ccode == 145 & year == 1952
replace civil_war = 0 if ccode == 150 & year == 1954
replace civil_war = 0 if ccode == 150 & year == 1989
replace civil_war = 0 if ccode == 90 & year == 1954
replace civil_war = 0 if ccode == 800 & year == 1951
replace civil_war = 0 if ccode == 530 & year == 1960
replace civil_war = 0 if ccode == 481 & year == 1964
replace civil_war = 0 if ccode == 516 & year == 1965
replace civil_war = 0 if ccode == 452 & year == 1966
replace civil_war = 0 if ccode == 452 & year == 1981
replace civil_war = 0 if ccode == 452 & year == 1983
replace civil_war = 0 if ccode == 652 & year == 1966
replace civil_war = 0 if ccode == 625 & year == 1971
replace civil_war = 0 if ccode == 625 & year == 1976
replace civil_war = 0 if ccode == 600 & year == 1971
replace civil_war = 0 if ccode == 500 & year == 1974
replace civil_war = 0 if ccode == 155 & year == 1973
replace civil_war = 0 if ccode == 450 & year == 1980
replace civil_war = 0 if ccode == 420 & year == 1981
replace civil_war = 0 if ccode == 501 & year == 1982
replace civil_war = 0 if ccode == 471 & year == 1984
replace civil_war = 0 if ccode == 680 & year == 1986
replace civil_war = 0 if ccode == 439 & year == 1987
replace civil_war = 0 if ccode == 581 & year == 1989
replace civil_war = 0 if ccode == 95 & year == 1989
replace civil_war = 0 if ccode == 41 & year == 1989
replace civil_war = 0 if ccode == 41 & year == 1991
replace civil_war = 0 if ccode == 373 & year == 1995
gen parties = 1
collapse (sum) parties, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Data\COWCountries.dta"
drop if _merge == 1
sort ccode year
gen last_con_year = 1 if parties[_n] != . & parties[_n+1] == .
replace last_con_year = 0 if last_con_year == .
gen con_complex = parties if last_con_year == 1
sort ccode year
by ccode: carryforward con_complex, replace
drop _merge
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\6-BaseConflictRecurrenceData.dta"
drop if _merge != 3
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\7-BaseConflictRecurrenceData.dta", replace

**Merge V-Dem Civil Society Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\VDEM-Paper1-Data.dta"
sort ccode year
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\7-BaseConflictRecurrenceData.dta"
drop if _merge != 3
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\8-BaseConflictRecurrenceData.dta", replace

**Merge SCAD Africa Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\SCADAfricaData.dta"
drop if ndeath < 0
drop if escalation == 10
rename styr year
sort ccode year
collapse (sum) ndeath, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\8-BaseConflictRecurrenceData.dta"
drop if _merge == 1
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\9-BaseConflictRecurrenceData.dta", replace

**Merge SCAD Latin America Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\SCADLatAmData.dta"
drop if ndeath < 0
drop if escalation == 10
rename styr year
sort ccode year
collapse (sum) ndeath, by(ccode year)
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\9-BaseConflictRecurrenceData.dta"
drop if _merge == 1
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\10-BaseConflictRecurrenceData.dta", replace

**Merge Historical Index of Ethnic Fractionalization Data**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Data\HIEF-Data.dta"
drop country
merge m:m ccode year using "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\10-BaseConflictRecurrenceData.dta"
drop if _merge == 1
drop _merge
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\11-BaseConflictRecurrenceData.dta", replace

*Generate Time and Lagged Variables*
rename v2csprtcpt_ord CSO_prtcpt
sort ccode year
by ccode: gen CSO_lag1 = CSO_prtcpt[_n-1]
by ccode: gen CSO_lag3 = CSO_prtcpt[_n-3]
by ccode: gen CSO_lag5 = CSO_prtcpt[_n-5]
sort spell_identifier year
by spell_identifier: gen time = [_n]

*Inspect Peace Spell Variation for CSO Values*
by spell_identifier (CSO_prtcpt), sort: gen changed = (CSO_prtcpt[1] != CSO_prtcpt[_N])
sum changed
drop changed

**Final Data Cleaning**
gen democracy = 1 if v2x_regime < 1
replace democracy = 0 if democracy == .
drop v2x_regime
drop parties
drop last_con_year
drop version
rename efindex ethnic_frac
gen ethnic_frac_new = ethnic_frac * 100
rename ndeath low_lvl_deaths
rename CSO_prtcpt CSO
gen lGDPpc = ln(e_gdppc + 1)
drop e_gdppc
label variable failure "Civil War Recurrence"
label variable low_lvl_deaths "Low-Level Deaths"
label variable CSO "Civil Society Participation"
label variable ethnic_frac "Ethnic Diversity"
label variable democracy "Democracy"
label variable cumulative_intensity "Prior Conflict Intensity"
label variable PKO "Peacekeeping Operation"
label variable war_duration "Prior War Duration"
label variable territory "Prior Territorial Conflict"
label variable peace_agg "Prior Peace Agreement"
label variable spell_count "Prior Peace Spells"
label variable con_complex "Prior Conflict Complexity"
label variable lGDPpc "Log(GDP per Capita)"
duplicates list
duplicates drop
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\12-BaseConflictRecurrenceData.dta", replace

**Order and Sort the Final Data Set**
sort ccode year
order country_name stateabb ccode year failure low_lvl_deaths CSO CSO_lag1 CSO_lag3 CSO_lag5 ///
	ethnic_frac ethnic_frac_new democracy failure cumulative_intensity PKO war_duration territory peace_agg ///
	spell_count spell_identifier time
save "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta", replace

************************Survival Analysis************************
**Full Sample (Excluding UK/France/Spain)**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if ccode == 200
drop if ccode == 220
drop if ccode == 230

stset time, id(spell_identifier) failure(failure)

streg CSO lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex cumulative_intensity, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M1
stcurve, hazard at1(CSO = 0) at2(CSO = 1) at3(CSO = 2) at4(CSO = 3) ///
	(xtitle(Years)) ytitle(Probability of Conflict Recurrence) title(Full Sample - CSO at Time t) scheme(plottig)

streg CSO_lag1 lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex cumulative_intensity, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M2

streg CSO_lag3 lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex cumulative_intensity, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M3

streg CSO_lag5 lGDPpc ethnic_frac_new democracy PKO territory war_duration con_complex cumulative_intensity, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M4

**Prior War Major Sample (Excluding UK/France/Spain)**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if ccode == 200
drop if ccode == 220
drop if ccode == 230
drop if cumulative_intensity == 0

stset time, id(spell_identifier) failure(failure)

streg CSO lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M5
stcurve, hazard at1(CSO = 0) at2(CSO = 1) at3(CSO = 2) at4(CSO = 3) ///
	(xtitle(Years)) ytitle(Probability of Conflict Recurrence) title(Prior War Major Sample - CSO at Time t) scheme(plottig)

streg CSO_lag1 lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M6

streg CSO_lag3 lGDPpc ethnic_frac_new democracy PKO territory war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M7

streg CSO_lag5 lGDPpc ethnic_frac_new democracy PKO territory war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M8

**Prior War Minor Sample (Excluding UK/France/Spain)**
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if ccode == 200
drop if ccode == 220
drop if ccode == 230
drop if cumulative_intensity == 1

stset time, id(spell_identifier) failure(failure)

streg CSO lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M9

streg CSO_lag1 lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M10

streg CSO_lag3 lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M11

streg CSO_lag5 lGDPpc ethnic_frac_new democracy PKO territory war_duration con_complex, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M12

**Survival Analysis Robustness Checks**
*Full Sample - Including UK/France/Spain*
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"

stset time, id(spell_identifier) failure(failure)

streg CSO lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex cumulative_intensity, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M13
	
*Full Sample - Excluding European Outliers - Stratification*
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if ccode == 200
drop if ccode == 220
drop if ccode == 230

stset time, id(spell_identifier) failure(failure)

streg CSO lGDPpc ethnic_frac_new democracy PKO territory peace_agg war_duration con_complex cumulative_intensity, ///
	dist(weibull) strata(spell_count) vce(cluster ccode)
estimates store surv_M14

*Full Sample - Alternative Peace Agreement Resolution*
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if ccode == 200
drop if ccode == 220
drop if ccode == 230
drop if peace_agg == 1

stset time, id(spell_identifier) failure(failure)

streg CSO lGDPpc ethnic_frac_new democracy PKO territory war_duration con_complex cumulative_intensity, ///
	dist(weibull) vce(cluster ccode)
estimates store surv_M15

************************Event Count Analysis************************
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if failure == 1
drop if low_lvl_deaths == .

*Compare the Variance to the Mean to Look for Overdispersion*
summarize low_lvl_deaths, detail

*Full Sample*
nbreg low_lvl_deaths CSO ethnic_frac_new democracy cumulative_intensity PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M1

nbreg low_lvl_deaths CSO_lag1 ethnic_frac_new democracy cumulative_intensity PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M2

nbreg low_lvl_deaths CSO_lag3 ethnic_frac_new democracy cumulative_intensity PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M3

nbreg low_lvl_deaths CSO_lag5 ethnic_frac_new democracy cumulative_intensity PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M4 

*Prior War Major Sample*
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if failure == 1
drop if low_lvl_deaths == .
drop if cumulative_intensity == 0

nbreg low_lvl_deaths CSO ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M5

nbreg low_lvl_deaths CSO_lag1 ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M6

nbreg low_lvl_deaths CSO_lag3 ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M7

nbreg low_lvl_deaths CSO_lag5 ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M8

*Prior War Minor Sample*
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if failure == 1
drop if low_lvl_deaths == .
drop if cumulative_intensity == 1

nbreg low_lvl_deaths CSO ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M9

nbreg low_lvl_deaths CSO_lag1 ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M10

nbreg low_lvl_deaths CSO_lag3 ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M11

nbreg low_lvl_deaths CSO_lag5 ethnic_frac_new democracy PKO war_duration territory peace_agg lGDPpc, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M12

*Robustness Checks - Fixed Effects*
clear
use "C:\Users\brian\Desktop\Dissertation & Projects\Paper 1\Paper 1 Data Files\FinalChapter1Data.dta"
drop if failure == 1
drop if low_lvl_deaths == .

nbreg low_lvl_deaths CSO ethnic_frac_new democracy cumulative_intensity PKO war_duration territory peace_agg lGDPpc con_complex i.ccode, ///
	dispersion(mean) irr vce(cluster ccode)
*Store Estimates*
estimates store nb_M13

************************End of Do-File*************************
