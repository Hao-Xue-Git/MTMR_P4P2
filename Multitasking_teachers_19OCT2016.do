 * ================================================================= *
 * TEACHER DATASETS - CREATING MULTIPLE TEACHER DATASETS BY SUBJECT
 *
 *
 * Divya Dev
 * Hao Xue
 * Date: October 19, 2016
 * ================================================================ *
 
  clear all
  set more off
*  set mem 200m
  cap log close
/*
* Set Directories
  global main    "S:\Marcos\China\3by2_paper_analysis" 
  global datadir "S:\Marcos\China\3by2_paper_analysis\working data"
 global outdir  "S:\Marcos\China\3by2_paper_analysis\output\multitasking\FDR\maineff\4_arms\Multitasking_June2016"
  global log	 "S:\Marcos\China\3by2_paper_analysis\output\multitasking\FDR\maineff\4_arms"
  global dofile  "S:\Marcos\China\3by2_paper_analysis\do files"
  global temp    "S:\Marcos\China\3by2_paper_analysis\working data\Temp"
*/
  * Set Directories
  global main    "/Users/apple/Dropbox (REAP)/REAP_Project/P4P II/Analysis/3by2_paper_analysis" 
  global datadir "/Users/apple/Dropbox (REAP)/REAP_Project/P4P II/Analysis/3by2_paper_analysis/working data"
  global log	 "/Users/apple/Dropbox (REAP)/REAP Renda/NIH Data for MTMR Analysis/Output/Log/"
  global dofile  "/Users/apple/Dropbox (REAP)/REAP_Project/P4P II/Analysis/NIH Data for MTMR Analysis/Dofile"
  global temp    "/Users/apple/Dropbox (REAP)/REAP Renda/NIH Data for MTMR Analysis/Output/Working data"
  global outdir  "/Users/apple/Dropbox (REAP)/REAP Renda/NIH Data for MTMR Analysis/Output/Result"

* set seed
  set seed 30062015

* Run ado
*  quietly do "$main\do files\ado\fsdrm.ado"
*  quietly do "$main\do files\ado\fdr.ado"
   quietly do "$main/do files/aindex.ado"  
  
* Opening dataset

* use "$datadir\Teacher_endline_clean_deid_4Feb.dta", clear 
  use "$datadir/Teacher_endline_clean.dta", clear
* Log file
 log using "$log/Multitasking_teachers.txt", replace


* Organizing some key variables
 
 ren teachercode teachercode_old 
 gen teachercode_new = regexs( 1 ) if regexm( teachercode_old, "([0-9]+).*" )  /*this line of code removes the letter components from the teachercode. Some observsations had teachercodes that contained the letter 'A' */
 destring teachercode_new, gen(teachercode)  
 format teachercode %14.0g

 tostring teachercode, replace  //added by XH

 destring teacher_e_1_2_corr, gen(teacher_e_age)
 
 * Merging baseline data 
 
 preserve 
* use "$datadir\Teacher_baseline_clean_deid_4Feb.dta", clear
  use "$datadir/Teacher_endline_clean.dta", clear

 duplicates drop teachercode, force //DD: Check what to do about this later. 
 tempfile teach
 save `teach'
 restore
 
 merge m:1 teachercode using `teach', gen(merge_teacaher)
 
 * duplicates tag teachercode, gen(flag) //DD: To flag those teachers that have the same teacher codes. 
 
 * Main subject taught by teacher 
 
 destring teacher_e_2_2_1_corr, gen(teacher_e_subj)
 
* Secondary subject
local end "e b"
foreach j of local end {
forval i = 1/3 {
 g teacher_`j'_secsubj_`i' = (strpos(teacher_`j'_2_16_corr, "`i'")>0)
	replace teacher_`j'_secsubj_`i' = . if missing(teacher_`j'_2_16_corr)
 }

 
 replace teacher_`j'_secsubj_3 = 1 if strpos(teacher_`j'_2_16_corr, "Ʒ")>0
 
 lab var teacher_`j'_secsubj_1 "Science is secondary subject"
 lab var teacher_`j'_secsubj_2 "Social studies is secondary subject"
 lab var teacher_`j'_secsubj_3 "Other is secondary subject" 

 
 }
 
* Number of main subject classes taught 

g teacher_e_mainnumclass = teacher_e_2_2_corr 
g teacher_b_mainnumclass = teacher_b_2_3_corr

lab var teacher_e_mainnumclass "Number of main subject classes"
lab var teacher_b_mainnumclass "Number of main subject classes"

* Number of self study classes 

//DD: NOTE: Outliers have been removed

g teacher_e_ssnumclass = teacher_e_2_10_corr
g teacher_b_ssnumclass = teacher_b_2_11_corr

lab var teacher_e_ssnumclass "Number of self study classes"
lab var teacher_b_ssnumclass "Number of self study classes"
 
replace teacher_e_ssnumclass = . if teacher_e_ssnumclass > 10
replace teacher_b_ssnumclass = . if teacher_b_ssnumclass > 10
 
 
* Maximum points on Chinese exam at end of last semester

 destring teacher_e_1_12_corr, gen(teacher_e_chin_maxpts)
 destring teacher_e_1_13_corr, gen(teacher_e_maths_maxpts)
 destring teacher_e_1_14_corr, gen(teacher_e_sci_maxpts)
 destring teacher_e_1_15_corr, gen(teacher_e_eng_maxpts)
 
 lab var teacher_e_chin_maxpts "Maximum points on Chinese Exam"
 lab var teacher_e_maths_maxpts "Maximum points on Maths exam"
 lab var teacher_e_sci_maxpts "Maximum points on Science exam"
 lab var teacher_e_eng_maxpts "Maximum points on English exam" 
 
* Teacher reported absences 

destring teacher_e_5_3_1_corr, gen(teacher_e_abs)
gen teacher_b_abs = teacher_b_5_3_corr

lab var teacher_e_abs "Teacher reported absences"
lab var teacher_b_abs "Teacher reported absences"

* Number of test prep classes and tests

//DD: CAREFUL: There are some outliers - check what to do!!!

replace teacher_e_2_14_1_corr = "7" if teacher_e_2_14_1_corr == "7-8"
destring teacher_e_2_14_1_corr, gen(teacher_e_testprep)
*replace teacher_e_2_14_3_corr = " " if teacher_e_2_14_3_corr == "����ת��������ѧ������
destring teacher_e_2_14_3_corr, gen(teacher_e_testlast) force //DD: This is to deal with an entry of symbols

g teacher_e_test = teacher_e_2_14_2_corr

* Correcting outliers 
replace teacher_e_testprep = . if teacher_e_testprep > 100
replace teacher_e_test = . if teacher_e_test > 20 
replace teacher_e_testlast = . if teacher_e_testlast > 20

lab var teacher_e_testprep "Number of test prep classes"
lab var teacher_e_test "Number of tests this semester"
lab var teacher_e_testlast "Number of tests last semester"

  
 
* Other variables

//DD: There are some observations that are inputted at 1090 which I will recode to missing for now

 destring teacher_e_2_3_corr, gen(teacher_e_time_newmat) 
 destring teacher_e_2_4_corr, gen(teacher_e_time_askqs)
 
 //DD: For now those responses that have been given in ranges I am taking the midpoint
 replace teacher_e_2_5_corr = "12" if teacher_e_2_5_corr == "4-20"
 destring teacher_e_2_5_corr, gen(teacher_e_time_review)
 
 replace teacher_e_2_6_corr = "12" if teacher_e_2_6_corr == "10-15"
 destring teacher_e_2_6_corr, gen(teacher_e_time_selfstudy) 
 
 replace teacher_e_2_11_corr = "25" if teacher_e_2_11_corr == "20-30"
 destring teacher_e_2_11_corr, gen(teacher_e_time_tlss)
 
 * Correcting reponses that report a percentage over 100 
 replace teacher_e_time_askqs = . if teacher_e_time_askqs > 100
 replace teacher_e_time_review = . if teacher_e_time_review > 100
 
 lab var teacher_e_time_newmat "Percent time spent on new material"
 lab var teacher_e_time_askqs "Percent time spent on asking questions"
 lab var teacher_e_time_review "Percent time spent on review"
 lab var teacher_e_time_selfstudy "Percent time spent on self study"
 lab var teacher_e_time_tlss "Percent time spent on teacher led self study"
 
 local thing "newmat askqs review selfstudy tlss"
 foreach i of local thing {
	replace teacher_e_time_`i' = . if teacher_e_time_`i' == 1090
	}
 
* Homework
replace teacher_e_2_12_corr = "3" if teacher_e_2_12_corr == "3-4"
destring teacher_e_2_12_corr, gen(teacher_e_hw) 

//DD: Again correcting for reported ranges and strangely high numbers

replace teacher_e_hw = . if teacher_e_hw > 15 
lab var teacher_e_hw "Number of homework assignments"

* Rewards for students

 g teacher_e_rew = (teacher_e_2_14_11_corr == "1")
 replace teacher_e_rew = . if missing(teacher_e_2_14_11_corr)
 
 lab var teacher_e_rew "Teacher give rewards for better grades" 
 
* Homework assignments for secondary subjects 

local ending "e b"
 
foreach j of local ending { 
forval i = 1/3{
 g teacher_`j'_sechw_`i' = teacher_`j'_2_26_corr if teacher_`j'_secsubj_`i' == 1
 }
 
 lab var teacher_`j'_sechw_1 "Number of science homework assignments"
 lab var teacher_`j'_sechw_2 "Number of social studies homework assignments"
 lab var teacher_`j'_sechw_3 "Number of other secondary subject homework assignments"
 }
 
 *  Tutoring students

 g teacher_e_tutor = (teacher_e_2_28_corr == "1")
	replace teacher_e_tutor = . if teacher_e_2_28_corr == "."
	replace teacher_e_tutor = . if missing(teacher_e_2_28_corr)

	
 replace teacher_e_2_29_corr = "2" if teacher_e_2_29_corr == "2-3"
 replace teacher_e_2_29_corr = "3" if teacher_e_2_29_corr == "3-4"
 
* Number of secondary subject classes taught

g teacher_b_secclass = teacher_b_2_18_corr
destring teacher_e_2_18_corr, gen(teacher_e_secclass) force 

//DD: Again there are some symbols enterred
replace teacher_e_secclass = . if teacher_e_secclass > 10	
	
local ending "e b"
foreach j of local ending {	
	lab var teacher_`j'_secclass "number of secondary subject classes"
	}

 
 //DD: CAREFUL: This variable has multiple observations with unrealistically high resonponses - check what to do!!!!
	
 destring teacher_e_2_29_corr, gen(teacher_e_tutorlw) 
 
 * Correcting for outliers 
 
 replace teacher_e_tutorlw = . if teacher_e_tutorlw >30

 lab var teacher_e_tutor "Teacher tutors student outside of class"
 lab var teacher_e_tutorlw "Times teacher tutored students last week"

* Principal listened to teacher's class

local end "e b"

foreach j of local end {
	g teacher_`j'_obsprin = teacher_`j'_2_33_corr
	lab var teacher_`j'_obsprin "Times principal observed teacher's class"
}
//DD: NOTE: Correcting for outliers

replace teacher_e_obsprin = . if teacher_e_obsprin > 10
replace teacher_b_obsprin = . if teacher_b_obsprin > 20

* Time spent 

 destring teacher_e_5_8_corr, gen(teacher_e_hrs_hw) 
	replace teacher_e_hrs_hw = . if teacher_e_hrs_hw == 350
	
 replace teacher_e_5_9_corr = "2.5" if teacher_e_5_9_corr == "2/3"
 replace teacher_e_5_9_corr = " " if teacher_e_5_9_corr == "300"
 destring teacher_e_5_9_corr, gen(teacher_e_hrs_prep)
 destring teacher_e_5_13_corr, gen(teacher_e_hrs_tutor)
 destring teacher_e_5_14_corr, gen(teacher_e_hrs_prepmain)
 
 replace teacher_e_5_15_corr = "16" if teacher_e_5_15_corr == "160"
 destring teacher_e_5_15_corr, gen(teacher_e_hrs_prepsec)
 
 forval i = 8/15 {
	destring teacher_e_5_`i'_corr, gen(temp_`i') force //DD: Note: This is not a problem as it is getting stuck due to a `.` in variable 12
	}
 
 tempvar tot
 egen `tot' = rowtotal(temp_8 temp_9 temp_10 temp_11 temp_12 temp_13 temp_14 temp_15)
  
local var "hw tutor prep prepmain prepsec"
foreach i of local var { 
	replace teacher_e_hrs_`i' = teacher_e_hrs_`i'/`tot'
}
  

lab var teacher_e_hrs_hw	"Hours spent grading homework"
lab var teacher_e_hrs_prep	"Hours spent preparing class"
lab var teacher_e_hrs_tutor "Hours spent tutoring outside of class"
lab var teacher_e_hrs_prepmain	"Hours spent prepaing main class"
lab var teacher_e_hrs_prepsec	"Hours spent preparing secondary class"

drop temp* 

* Questions pertaining to secondary subjects 

g teacher_b_sectime_main = teacher_b_2_17_corr
g teacher_b_sectime_lect = teacher_b_2_19_corr
g teacher_b_sectime_askqs = teacher_b_2_20_corr
g teacher_b_sectime_review = teacher_b_2_21_corr
g teacher_b_sectime_selfstudy = teacher_b_2_22_corr
	
destring teacher_e_2_17_corr, gen(teacher_e_sectime_main)
destring teacher_e_2_19_corr, gen(teacher_e_sectime_lect)	
destring teacher_e_2_20_corr, gen(teacher_e_sectime_askqs)	
destring teacher_e_2_21_corr, gen(teacher_e_sectime_review)	
destring teacher_e_2_22_corr, gen(teacher_e_sectime_selfstudy)	
	
local ending "e b"
foreach i of local ending {	
	lab var teacher_`i'_sectime_main "Percent of secondary subject class time spent on main class"
	lab var teacher_`i'_sectime_lect "Percent of time spent lecturing in secondary subject class"
	lab var teacher_`i'_sectime_askqs "Percent of time spent asking questions in secondary subject class"
	lab var teacher_`i'_sectime_review "Percent of time spent reviewing material in secondary subject class"
	lab var teacher_`i'_sectime_selfstudy "Percent of time spent in self study in secondary subject class"
	
	}

* Vitmain distribution
 g teacher_e_distrvit = .
	forval i = 1/3 {
		replace teacher_e_distrvit = `i' if teacher_e_6_8_4_corr == "`i'"
		}
		
//DD: NOTE: Outliers have been removed	
 g teacher_e_time_distrvit = . 
	forval i = 0/60 {
		replace teacher_e_time_distrvit = `i' if teacher_e_6_8_5_corr == "`i'"
		}
		
replace teacher_e_time_distrvit = . if teacher_e_time_distrvit > 30		
		
g teacher_e_distrvit_dummy = (teacher_e_distrvit == 1)
	replace teacher_e_distrvit_dummy = . if teacher_e_distrvit == .
 
 lab var teacher_e_distrvit "When did the teacher distribute vitamins"
 lab var teacher_e_time_distrvit "Time spent distributing vitamins"
 lab var teacher_e_distrvit_dummy "Takes value 1 if teacher disbutes vitamins during classtime"
 
* Main topic during parent meetings 

g teacher_e_par_health = (strpos(teacher_e_7_5_1_corr, "3")>0 | strpos(teacher_e_7_5_1_corr, "4")>0)

lab var teacher_e_par_health "Teacher discussed health and nutrition at last parent meeting"   

* ============================================================================ * 
* Baseline data (where the question numbers were different in the two surveys)
* ============================================================================ * 

* Maximum points on last exam

 gen teacher_b_chin_maxpts = teacher_b_1_12_corr
 gen teacher_b_maths_maxpts =  teacher_b_1_13_corr
 gen teacher_b_sci_maxpts = teacher_b_1_14_corr
 gen teacher_b_eng_maxpts = teacher_b_1_15_corr
 
 lab var teacher_b_chin_maxpts "Maximum points on Chinese Exam"
 lab var teacher_b_maths_maxpts "Maximum points on Maths exam"
 lab var teacher_b_sci_maxpts "Maximum points on Science exam"
 lab var teacher_b_eng_maxpts "Maximum points on English exam" 

* Time spent
 gen teacher_b_time_newmat = teacher_b_2_4_corr 
 gen teacher_b_time_askqs = teacher_b_2_5_corr 
 gen teacher_b_time_review = teacher_b_2_6_corr
 gen teacher_b_time_selfstudy = teacher_b_2_7_corr
 gen teacher_b_time_tlss = teacher_b_2_12_corr
 
 * Correcting reponses that are percentages greater than 100
 
 replace teacher_b_time_review = . if teacher_b_time_review > 100
 
 lab var teacher_b_time_newmat "Percent time spent on lecturing"
 lab var teacher_b_time_askqs "Percent time spent on asking questions"
 lab var teacher_b_time_review "Percent time spent on review"
 lab var teacher_b_time_selfstudy "Percent time spent on self study"
 lab var teacher_b_time_tlss "Percent time spent on teacher led self study"
 
 local thing "newmat askqs review selfstudy tlss"
 foreach i of local thing {
	replace teacher_b_time_`i' = . if teacher_b_time_`i' == 1090
	}

* Homework 
 
 g teacher_b_hw = teacher_b_2_13_corr
 replace teacher_b_hw = . if teacher_b_2_13_corr > 28
 
* Tutoring students
g teacher_b_tutor = (teacher_b_2_28_corr == 1)
	replace teacher_b_tutor = . if teacher_b_2_28_corr == .
gen teacher_b_tutorlw = teacher_b_2_29_corr

 lab var teacher_b_tutor "Teacher tutors student outside of class"
 lab var teacher_b_tutorlw "Times teacher tutored students last week" 
 
 * Time spent 

 gen teacher_b_hrs_hw = teacher_b_5_8_corr  
	replace teacher_b_hrs_hw = . if teacher_b_hrs_hw >80
 gen teacher_b_hrs_prep = teacher_b_5_9_corr
 gen teacher_b_hrs_tutor = teacher_b_5_13_corr
 gen teacher_b_hrs_prepmain = teacher_b_5_14_corr 
 gen teacher_b_hrs_prepsec = teacher_b_5_15_corr 
 
 
 tempvar tot
 egen `tot' = rowtotal(teacher_b_5_8_corr teacher_b_5_9_corr teacher_b_5_10_corr teacher_b_5_11_corr teacher_b_5_12_corr teacher_b_5_13_corr teacher_b_5_14_corr teacher_b_5_15_corr)
  
local var "hw tutor prep prepmain prepsec"
foreach i of local var { 
	replace teacher_b_hrs_`i' = teacher_b_hrs_`i'/`tot'
	}
 

lab var teacher_b_hrs_hw	"Hours spent grading homework"
lab var teacher_b_hrs_prep	"Hours spent preparing class"
lab var teacher_b_hrs_tutor "Hours spent tutoring outside of class"
lab var teacher_b_hrs_prepmain	"Hours spent prepaing main class"
lab var teacher_b_hrs_prepsec	"Hours spent preparing secondary class"

g teacher_b_par_health = (strpos(teacher_b_7_5_corr, "3")>0 | strpos(teacher_b_7_5_corr, "4")>0)

lab var teacher_b_par_health "Teacher discussed health and nutrition at last parent meeting"  

* Time variables - outliers -> These are cut off as close as possible to cover 98% of the observations

replace teacher_e_time_newmat = . 		if teacher_e_time_newmat > 80
replace teacher_b_time_newmat = . 		if teacher_b_time_newmat > 80

replace teacher_e_time_askqs = . 		if teacher_e_time_askqs > 40
replace teacher_b_time_askqs = . 		if teacher_b_time_askqs > 75


replace teacher_e_time_review = . 		if teacher_e_time_review > 40
replace teacher_b_time_review = . 		if teacher_b_time_review > 40

replace teacher_e_time_selfstudy = . 	if teacher_e_time_selfstudy > 50
replace teacher_b_time_selfstudy = . 	if teacher_b_time_selfstudy > 60

replace teacher_e_time_tlss = . 		if teacher_e_time_tlss > 80
replace teacher_b_time_tlss = . 		if teacher_b_time_tlss > 80

replace teacher_e_sectime_main = . 		if teacher_e_sectime_main > 80
replace teacher_b_sectime_main = . 		if teacher_b_sectime_main > 90

replace teacher_e_sectime_lect = . 		if teacher_e_sectime_lect > 80
replace teacher_b_sectime_lect = . 		if teacher_b_sectime_lect > 90

replace teacher_e_sectime_askqs = . 	if teacher_e_sectime_askqs > 40
replace teacher_b_sectime_askqs = . 	if teacher_b_sectime_askqs > 60

replace teacher_e_sectime_review = . 	if teacher_e_sectime_review > 40
replace teacher_b_sectime_review = . 	if teacher_b_sectime_review > 50

replace teacher_e_sectime_selfstudy = . if teacher_e_sectime_selfstudy > 60
replace teacher_b_sectime_selfstudy = . if teacher_b_sectime_selfstudy > 60


******************************************************************************

* ================================ * 
* Regressions for teacher data
* ================================ *

* Merging some classroom controls

merge m:1 classcode using "$temp\NIH_working_studentdata_for_teacherdataset.dta", gen(_merge_class)

drop if smallanem == 1 | testinc == 1 | dualinc == 1

* Globals for student data

  global stu_cov = "stu_ageyear_b grade5 stu_female"
  global sch_cov = "sch_nstuds_b sch_canteen_b sch_stratio_b sch_distvill_b sch_pctboard_b  prin_e_10_1" 
  global maineff = "largeanem largesub largeanemXlarge"

* Time Variables 

local dep "time_newmat time_askqs time_review time_tlss time_selfstudy " 
 foreach var of local dep {
	fdr (teacher_e_`var' $maineff teacher_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
	    , testvar($maineff) hypadd() cluster(schoolcode)             ///
	    method(BKY)     
* Store all results
	mat variable = J(1,6,.)
	//mat list variable
	mat rownames variable = "`var'"
    mat mat_`var' = r(result)
	//Getting number of observations in the regression
	mat num = J(1,6,.)
	mat num[1,1] = e(N)
	mat rowname num = "Observations"
	// Summary statistics of dependent variable
	mat avg = J(1,6,.)
	mat min = J(1,6,.)
	mat max = J(1,6,.)
	qui sum teacher_e_`var' if e(sample)
	mat avg[1,1] = r(mean)
	mat min[1,1] = r(min)
	mat max[1,1] = r(max)
	mat rownames avg = "Mean"
	mat rownames min = "Min"
	mat rownames max = "Max" 
    //mat list mat_`var'
    mat rownames mat_`var' = $maineff 
    //mat list mat_`var'
    mat empty = J(1,6,.)
    //mat list empty 
	mat rownames empty = .
    mat results = variable\mat_`var'\num\avg\min\max\empty
	mat colnames results = beta se t pvalue adjusted rejected  
    mat drop variable mat_`var' num avg min max empty
    mat b = (nullmat(b)\ results)
    mat list b
	
}
	preserve
	drop _all
	svmat2 b, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Teachers_time.xls", replace
	restore
	mat drop b
	
* Secondary Subject time variables


local dep "time_main time_lect time_askqs time_review time_selfstudy " 
 foreach var of local dep {
	fdr (teacher_e_sec`var' $maineff teacher_b_sec`var' $sch_cov $stu_cov i.countycode i.strata) ///
	    , testvar($maineff) hypadd() cluster(schoolcode)             ///
	    method(BKY)     
* Store all results
	mat variable = J(1,6,.)
	//mat list variable
	mat rownames variable = "`var'"
    mat mat_`var' = r(result)
	//Getting number of observations in the regression
	mat num = J(1,6,.)
	mat num[1,1] = e(N)
	mat rowname num = "Observations"
	// Summary statistics of dependent variable
	mat avg = J(1,6,.)
	mat min = J(1,6,.)
	mat max = J(1,6,.)
	qui sum teacher_e_sec`var' if e(sample)
	mat avg[1,1] = r(mean)
	mat min[1,1] = r(min)
	mat max[1,1] = r(max)
	mat rownames avg = "Mean"
	mat rownames min = "Min"
	mat rownames max = "Max" 
    //mat list mat_`var'
    mat rownames mat_`var' = $maineff 
    //mat list mat_`var'
    mat empty = J(1,6,.)
    //mat list empty 
	mat rownames empty = .
    mat results = variable\mat_`var'\num\avg\min\max\empty
	mat colnames results = beta se t pvalue adjusted rejected  
    mat drop variable mat_`var' num avg min max empty
    mat b = (nullmat(b)\ results)
    mat list b
	
}
	preserve
	drop _all
	svmat2 b, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Teachers_Secondaryclass_time.xls", replace
	restore
	mat drop b	
	
* Hours teacher spends on different activities
* DD: Haven't included hrs_tutor -> too many missing
local dep "hrs_hw  hrs_prep hrs_prepmain hrs_prepsec" 
 foreach var of local dep {
	fdr (teacher_e_`var' $maineff teacher_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
	    , testvar($maineff) hypadd() cluster(schoolcode)             ///
	    method(BKY)     
* Store all results
	mat variable = J(1,6,.)
	//mat list variable
	mat rownames variable = "`var'"
    mat mat_`var' = r(result)
	//Getting number of observations in the regression
	mat num = J(1,6,.)
	mat num[1,1] = e(N)
	mat rowname num = "Observations"
	// Summary statistics of dependent variable
	mat avg = J(1,6,.)
	mat min = J(1,6,.)
	mat max = J(1,6,.)
	qui sum teacher_e_`var' if e(sample)
	mat avg[1,1] = r(mean)
	mat min[1,1] = r(min)
	mat max[1,1] = r(max)
	mat rownames avg = "Mean"
	mat rownames min = "Min"
	mat rownames max = "Max" 
    //mat list mat_`var'
    mat rownames mat_`var' = $maineff 
    //mat list mat_`var'
    mat empty = J(1,6,.)
    //mat list empty 
	mat rownames empty = .
    mat results = variable\mat_`var'\num\avg\min\max\empty
	mat colnames results = beta se t pvalue adjusted rejected  
    mat drop variable mat_`var' num avg min max empty
    mat b = (nullmat(b)\ results)
    mat list b
	
}
	preserve
	drop _all
	svmat2 b, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Teachers_hours.xls", replace
	restore
	mat drop b
	
* Number of classes, absences, tutoring, principal observed principal and discussion of health and nutriontion with parents

local dep "mainnumclass ssnumclass abs tutor tutorlw obsprin par_health" 
 foreach var of local dep {
	fdr (teacher_e_`var' $maineff teacher_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
	    , testvar($maineff) hypadd() cluster(schoolcode)             ///
	    method(BKY)     
* Store all results
	mat variable = J(1,6,.)
	//mat list variable
	mat rownames variable = "`var'"
    mat mat_`var' = r(result)
	//Getting number of observations in the regression
	mat num = J(1,6,.)
	mat num[1,1] = e(N)
	mat rowname num = "Observations"
	// Summary statistics of dependent variable
	mat avg = J(1,6,.)
	mat min = J(1,6,.)
	mat max = J(1,6,.)
	qui sum teacher_e_`var' if e(sample)
	mat avg[1,1] = r(mean)
	mat min[1,1] = r(min)
	mat max[1,1] = r(max)
	mat rownames avg = "Mean"
	mat rownames min = "Min"
	mat rownames max = "Max" 
    //mat list mat_`var'
    mat rownames mat_`var' = $maineff 
    //mat list mat_`var'
    mat empty = J(1,6,.)
    //mat list empty 
	mat rownames empty = .
    mat results = variable\mat_`var'\num\avg\min\max\empty
	mat colnames results = beta se t pvalue adjusted rejected  
    mat drop variable mat_`var' num avg min max empty
    mat b = (nullmat(b)\ results)
    mat list b
	
}
	preserve
	drop _all
	svmat2 b, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Teachers_tutoring.xls", replace
	restore
	mat drop b
	
 
 * Time spent distributing vitamins, rewards for students and test prep


local dep "distrvit_dummy time_distrvit rew testprep test testlast" 
 foreach var of local dep {
	fdr (teacher_e_`var' $maineff $sch_cov $stu_cov i.countycode i.strata) ///
	    , testvar($maineff) hypadd() cluster(schoolcode)             ///
	    method(BKY)     
* Store all results
	mat variable = J(1,6,.)
	//mat list variable
	mat rownames variable = "`var'"
    mat mat_`var' = r(result)
	//Getting number of observations in the regression
	mat num = J(1,6,.)
	mat num[1,1] = e(N)
	mat rowname num = "Observations"
	// Summary statistics of dependent variable
	mat avg = J(1,6,.)
	mat min = J(1,6,.)
	mat max = J(1,6,.)
	qui sum teacher_e_`var' if e(sample)
	mat avg[1,1] = r(mean)
	mat min[1,1] = r(min)
	mat max[1,1] = r(max)
	mat rownames avg = "Mean"
	mat rownames min = "Min"
	mat rownames max = "Max" 
    //mat list mat_`var'
    mat rownames mat_`var' = $maineff 
    //mat list mat_`var'
    mat empty = J(1,6,.)
    //mat list empty 
	mat rownames empty = .
    mat results = variable\mat_`var'\num\avg\min\max\empty
	mat colnames results = beta se t pvalue adjusted rejected  
    mat drop variable mat_`var' num avg min max empty
    mat b = (nullmat(b)\ results)
    mat list b
	
}
	preserve
	drop _all
	svmat2 b, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Teachers_vit_rewards.xls", replace
	restore
	mat drop b
	
	
 
	
* ========================== * 
* Splitting Datasets 
* ========================== * 

* Keeping only those variables that we need (Check if we want teacher_?_sectime*)

global vars "teacher_e_age teacher_?_subj teacher_?_secsubj* teacher_?_*_maxpts teacher_?_time* teacher_?_hw teacher_?_rew teacher_?_sechw_* teacher_?_tutor* teacher_?_obsprin teacher_?_hrs* teacher_?_distrvit teacher_?_time_distrvit teacher_?_par_health"

keep classcode $vars

* Generating a string variable which indicates main subject (this is just for ease of coding the next portion)

g str teacher_topic = " " 
replace teacher_topic = "maths" if teacher_e_subj == 1
replace teacher_topic = "chinese" if teacher_e_subj == 2

* Splitting the dataset by subject taught by teacher - maths or chinese
local subject "maths chinese"

foreach i of local subject {
preserve
keep if teacher_topic == "`i'" 
foreach x of var * {
	ren `x' `i'_`x'
	}
	ren `i'_classcode classcode
save "$temp\Multitasking_`i'teachers_june2016.dta", replace 
restore
}


local subject "maths chinese"
foreach i of local subject {
use "$temp\Multitasking_`i'teachers_june2016.dta", clear
	
duplicates tag classcode, gen(flag)
* Dropping those teachers that do not have classcodes as they cannot be used anyway
drop if classcode == .

* Taking an average of those teachers who are not unique for the classroom

preserve
* Only keeping those teachers who are not unique for the classroom
keep if flag == 1
ds
local a = r(varlist)
local b classcode `i'_teacher_topic
local c:list a-b
disp "`c'"

collapse "`c'" , by(classcode)

* Correcting the values of an indicator variable
replace `i'_teacher_e_par_health = 1 if `i'_teacher_e_par_health == 0.5

tempfile duplicateteachers
save `duplicateteachers'
restore

drop if flag == 1

* Adding these observations back to the original dataset
append using `duplicateteachers'

drop flag

save "$temp\Multitasking_`i'teachers_june2016.dta", replace 
}


 log close

  
