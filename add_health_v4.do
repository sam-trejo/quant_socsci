clear all
set more off
set scheme burd
capture set trace off
*set trace on

global gen_nurt "/ifs/sec/cpc/addhealth/users/samtrejo/gen_nurt"

***make stata date in numeric year_month_day format
quietly {
	global date=c(current_date)

	***day
	if substr("$date",1,1)==" " {
		local val=substr("$date",2,1)
		global day=string(`val',"%02.0f")
	}
	else {
		global day=substr("$date",1,2)
	}

	***month
	if substr("$date",4,3)=="Jan" {
		global month="01"
	}
	if substr("$date",4,3)=="Feb" {
		global month="02"
	}
	if substr("$date",4,3)=="Mar" {
		global month="03"
	}
	if substr("$date",4,3)=="Apr" {
		global month="04"
	}
	if substr("$date",4,3)=="May" {
		global month="05"
	}
	if substr("$date",4,3)=="Jun" {
		global month="06"
	}
	if substr("$date",4,3)=="Jul" {
		global month="07"
	}
	if substr("$date",4,3)=="Aug" {
		global month="08"
	}
	if substr("$date",4,3)=="Sep" {
		global month="09"
	}
	if substr("$date",4,3)=="Oct" {
		global month="10"
	}
	if substr("$date",4,3)=="Nov" {
		global month="11"
	}
	if substr("$date",4,3)=="Dec" {
		global month="12"
	}

	***year
	global year=substr("$date",8,4)

	global date="$year"+"_"+"$month"+"_"+"$day"
}
dis "$date"

***********************************************************************************
******************************* Grab Data *****************************************
***********************************************************************************

*set working directory
cd "$gen_nurt"

/*
***load ben's data file
use "data_for_sam_from_ben.dta", clear
keep aid pedigree
gen long iid=aid

***load and merge on polygenic scores (for european ancestry)
foreach dta in "bmi" "hgt" "cbw" {
	merge 1:1 iid using "`dta'_2019_06_08.dta"
	rename score pgs_`dta'
	keep if _merge==3
	keep aid pedigree iid pgs*
}

merge 1:1 iid using "swb_dep_neur_2018_12_11.dta"
gen pgs_dep=pgs_dep_mtag
keep if _merge==3
drop pgs_dep_gwas-pgs_swb_mtag
keep aid pedigree iid pgs*

merge 1:1 iid using "ea3_2018_12_11.dta"
gen pgs_ea3=pgs_ea3_mtag
gen pgs_cp=pgs_cp_mtag
keep if _merge==3
drop pgs_ea3_gwas-pgs_ma_mtag
keep aid pedigree pgs* pc*

***order and center relevant variables
order aid pedigree pgs* pc*
center pgs*, standardize inplace

***merge ah covariates
tempfile hold
save `hold', replace
fdause /ifs/sec/cpc/addhealth/addhealthdata/wave1/allwave1.xpt, clear
keep aid scid h1gi1m h1gi4 h1gi8 h1gi6a h1gi6b h1gi6c h1gi6d h1gi6e s8 bio_sex ah_pvt h1su1 h1hs3  /// 
	 iyear imonth s12 s18 h1gh60 h1gh59a h1gh59b pc49a_2 pc49a_3 h1gi1y h1gi1m h1gi11 ///
	 h1ir1 h1fs11 h1fs1 h1fs9 h1fs12 h1fs5 h1fs4 h1fs7 h1fs3 h1fs17 h1fs16 h1fs13 h1fs19  ///
	 h1fs10 h1fs15 h1fs2 h1fs14 h1fs18 h1fs6 h1gh21 h1gh20 h1fs5 h1fs17 h1fs8 pa12 pb8 pa1 pc19a_p pc19b_o
rename scid schid 
destring aid, replace force 
tempfile covs1
save `covs1', replace
use `hold', clear
merge 1:1 aid using `covs1'
keep if _merge!=2
drop _merge

save `hold', replace
fdause /ifs/sec/cpc/addhealth/addhealthdata/wave2/wave2.xpt, clear
keep aid h2fs17 h2hs5 h2ir1 h2fs11 h2fs1 h2fs9 h2fs12 h2fs5 h2fs4 h2fs7 h2fs3 h2fs5 h2fs17 ///
	 h2su1 iyear2 imonth2 h2gh53 h2gh52f h2gh52i h2ws16hf h2ws16hi h2ws16w ///
	 h2fs16 h2fs13 h2fs19 h2fs8 h2fs10 h2fs15 h2fs2 h2fs14 h2fs18 h2fs6 h2gh26 h2gh25 
destring aid, replace force 
tempfile covs2
save `covs2', replace
use `hold', clear
merge 1:1 aid using `covs2'
keep if _merge!=2
drop _merge

save `hold', replace
fdause /ifs/sec/cpc/addhealth/addhealthdata/wave3/wave3.xpt, clear
keep aid h3hs22 h3ir1 h3ir1 h3sp5 h3sp8 h3sp7 h3sp10 h3sp6 h3sp13 h3sp12 h3sp11 h3sp9 h3sp2 /// 
	 h3sp8 h3to130 iyear3 imonth3 h3da44 h3da43f h3da43i h3wgt h3hgt_f h3hgt_i h3hgt_pi
tempfile covs3
destring aid, replace force 
save `covs3', replace
use `hold', clear
merge 1:1 aid using `covs3'
keep if _merge!=2
drop _merge

save `hold', replace
fdause /ifs/sec/cpc/addhealth/addhealthdata/wave4/wave4.xpt, clear
keep aid h4ed2 h4hs9 c4numscr h4mh24 h4mh18 h4mh21 h4mh20 h4mh19 h4mh27 h4mh23 h4mh26 h4mh25 ///
	 h4mh22 h4mh2 h4pe28 h4ir1 h4mh19 h4se1 iyear4 imonth4 h4gh6 h4gh5f h4gh5i h4wgt h4hgt
destring aid, replace force 
tempfile covs4
save `covs4', replace
use `hold', clear
merge 1:1 aid using `covs4'
keep if _merge!=2
drop _merge

save "data_grab_$date", replace

***********************************************************************************
******************************* Clean Data *****************************************
***********************************************************************************

use "data_grab_$date", replace

***gender
generate fem=0
replace fem=1 if bio_sex==2

***age
rename iyear iyear1
rename imonth imonth1
replace iyear3=iyear3-1900
replace iyear4=iyear4-1900

forvalues w=1/4 {
	gen year`w' = iyear`w'-h1gi1y
	gen month`w' = imonth`w'-h1gi1m
	replace year`w'=. if year`w'<0
	replace month`w'=. if month`w'<-11
	gen age`w'=year`w'+(month`w'/12)
	replace age`w'=year`w' if age`w'==. 
}

***depression
gen num_miss1=0
foreach var in h1fs1 h1fs3 h1fs5 h1fs6 h1fs7 h1fs16 h1fs17 h1fs4 h1fs15 {
	replace `var'=. if `var'>3
	replace num_miss1=num_miss1+1 if `var'==.
}
gen num_miss2=0
foreach var in h2fs1 h2fs3 h2fs5 h2fs6 h2fs7 h2fs16 h2fs17 h2fs4 h2fs15 {
	replace `var'=. if `var'>3
	replace num_miss2=num_miss2+1 if `var'==.
}
gen num_miss3=0
foreach var in h3sp5 h3sp6 h3sp8 h3sp9 h3sp10 h3sp12 h3sp13 h3sp7 h3sp11 {
	replace `var'=. if `var'>3
	replace num_miss3=num_miss3+1 if `var'==.
}
gen num_miss4=0
foreach var in h4mh18 h4mh19 h4mh21 h4mh22 h4mh23 h4mh26 h4mh27 h4mh20 h4mh25 {
	replace `var'=. if `var'>3
	replace num_miss4=num_miss4+1 if `var'==.
}

foreach var in h1fs4 h2fs4 h3sp7 h4mh20 h1fs15 h2fs15 h3sp11 h4mh25 {
	replace `var'=3-`var'
}

gen cesd1=h1fs1+h1fs3+h1fs5+h1fs6+h1fs7+h1fs16+h1fs17+h2fs4+h1fs15
gen cesd2=h2fs1+h2fs3+h2fs5+h2fs6+h2fs7+h2fs16+h2fs17+h2fs4+h2fs15
gen cesd3=h3sp5+h3sp6+h3sp8+h3sp9+h3sp10+h3sp12+h3sp13+h3sp7+h3sp11
gen cesd4=h4mh18+h4mh19+h4mh21+h4mh22+h4mh23+h4mh26+h4mh27+h4mh20+h4mh2
forval i=1/4 {
	replace cesd`i'=0 if num_miss`i'>0
}
center cesd1 cesd2 cesd3 cesd4, standardize inplace
rename cesd* dep*

***iq picture vocabular
rename ah_pvt cp1

***respondent education
gen edu4=.
replace edu4=9 if h4ed2==1
replace edu4=11 if h4ed2==2
replace edu4=13 if h4ed2==3
replace edu4=14 if h4ed2==4
replace edu4=15 if h4ed2==5
replace edu4=15 if h4ed2==6
replace edu4=17 if h4ed2==7
replace edu4=18 if h4ed2==8
replace edu4=19 if h4ed2==9
replace edu4=20 if h4ed2==10
replace edu4=22 if h4ed2==11
replace edu4=19 if h4ed2==12
replace edu4=20 if h4ed2==13

***bmi
gen bmi4=h4wgt/(h4hgt/100)^2
replace bmi4=. if h4wgt>500 | h4hgt>500

***height
gen hgt4=h4hgt
replace hgt4=. if h4hgt>500

***birth weight
replace pc19b_o=0 if pc19a_p==3 | pc19a_p==12
gen cbw1=16*pc19a_p+pc19b_o if (inrange(pc19a_p, 3, 12) & inrange(pc19b_o, 0, 15))

***keep
keep aid pedigree pgs* age1 age4 fem cbw1 cp1 hgt4 bmi4 dep4 edu4 pc1-pc10
order aid pedigree pgs* age1 age4 fem cbw1 cp1 hgt4 bmi4 dep4 edu4 pc1-pc10

save "data_clean_$date.dta", replace
*/
use "data_clean_2019_06_09.dta"

drop age1
rename pgs_ea3 pgs_edu

foreach var in cp dep edu {
	replace pgs_`var'=pgs_`var'*-1
}

foreach var in age cbw cp hgt bmi dep edu {
		capture rename `var'1 `var'
		capture rename `var'4 `var'
}


label var pgs_edu "Educational Attainment PGS"
label var pgs_cp "Cognitive Ability PGS"
label var pgs_dep "Depression PGS"
label var pgs_cbw "Child Birth Weight PGS"
label var pgs_bmi "Body Mass Index PGS"
label var pgs_hgt "Height PGS"
label var edu "Years of Schooling"
label var cp "Cognitive Ability"
label var dep "CESD Depression Index"
label var cbw "Birth Weight"
label var bmi "Body Mass Index"
label var hgt "Height"

egen count=count(pedigree), by(pedigree)
gen within=pedigree!="" & count==2
gen rand=runiform() if within
egen ped_rand=max(rand), by(pedigree)	
gen between=rand==ped_rand | within==0
	
quietly {
	foreach var in edu cp dep cbw bmi hgt {
		eststo m_`var'_1: reg `var' pgs_`var' age fem pc* if between, vce(robust) // vce(bootstrap, reps(100) seed(12345))
		estadd local fixed "   ", replace
		eststo m_`var'_2: areg `var' pgs_`var' age fem pc* if within, absorb(pedigree) vce(robust) // vce(bootstrap, reps(100) seed(12345))
		estadd local fixed " X ", replace

	}
}

esttab m_edu* m_cp* m_dep* m_cbw* m_bmi* m_hgt* ///
	   using "results_$date.csv", se r2 label replace ///
	   keep(pgs*) ///
	   star(+ .10 * .05 ** .01) ///
	   stat(fixed r2 N, label("Family Fixed Effects" "R^2" "N")) ///
	   nonotes addnotes("+ p<.10        * p<.05        ** p<.01" " " " " )

**************************************************************************************** 

tempfile boot
save `boot', replace

capture program drop myboot
program define myboot, rclass
	preserve 
		keep if between
		bsample
		regress out pgs age fem pc*
		local ols=_b[pgs]
	restore
		preserve
		keep if within
		bsample, cluster(pedigree)  
		areg out pgs age fem pc*, absorb(pedigree)
		local fe=_b[pgs]
	restore
	return scalar diff = `fe'-`ols'
end

quietly {
	foreach var in edu cp dep cbw bmi hgt {
		regress `var' pgs_`var' age fem pc* if between
		local ols=_b[pgs_`var']
		areg `var' pgs_`var' age fem pc* if within, absorb(pedigree)
		local fe=_b[pgs_`var']
		matrix observe = `fe'-`ols'
		
		capture drop out pgs
		gen out = `var'
		gen pgs = pgs_`var'
		simulate diff=r(diff), reps(1000) seed(78703): myboot
		bstat, stat(observe)

		matrix define B=e(b)
		matrix define SE=e(se)
		local pval = (2 * ttail(1000000, abs(B[1,1]/SE[1,1])))
		
		use `boot', clear
		regress `var' pgs_`var' age fem pc* if between
		local ols=_b[pgs_`var']
		areg `var' pgs_`var' age fem pc* if within, absorb(pedigree)
		local fe=_b[pgs_`var']
		local pi_psi = `fe'/`ols'
		
		matrix mat=nullmat(mat) \ `ols',  `fe', `pi_psi', `pval'
	}
}

***name rows
matrix rownames mat = "Years of Schooling" "Cognitive Ability" "CESD Depression Index" "Birth Weight" "Body Mass Index" "Height"

***output to latex
frmttable, /// using "results$date.tex"
		  statmat(mat) ///
		  title("Table 1. The association between polygenic score and observed trait" ///
				"for six phenotypes within-families and between-families") ///
		  ctitles(" " "Psi" "Pi" "Psi/Pi" "P(Psi=Pi)") 

