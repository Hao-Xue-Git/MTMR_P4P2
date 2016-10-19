 * ======================================================= *
 * MECHANISM HYPOTHESES - RELATING TO EDUCATION
 *
 *
 * Divya Dev
 * Date: June 24, 2016
 * ======================================================= *
 
  clear all
  set more off
  set mem 200m
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
  
* Running do file that puts the teacher dataset together 

 
*do "$dofile\Multitasking_teachers_June2016"
  *quietly do "$dofile\Multitasking_maneff_fdr_mechhyp_teachers_foredindex"
  
* set seed
  set seed 30062015

* Run ado
*  quietly do "$main\do files\ado\fsdrm.ado"
*  quietly do "$main\do files\ado\fdr.ado"
   quietly do "$main/do files/aindex.ado"  
  
* Log 
 *log using "$log\Multitasking_maineff_June2016.txt.", replace
 
* Open dataset
  use "$datadir/NIH_working.dta", clear
  
  
* Samples
  gen all = 1
  gen     anem = 0
  replace anem = 1 if anemic_b==1
  gen     hb = 0
  replace hb = 1 if hb_b_alt!=.	
  drop if smallanem==1                /*DD: small anemia incentive excluded*/
  gen nonanem = (anem == 0)
  
  drop if testinc ==1 | dualinc == 1               /*DD: excluding other incentive schools as well */

  
  
 * Var lists
  global stu_cov = "stu_ageyear_b grade5 stu_female"
  global sch_cov = "sch_nstuds_b sch_canteen_b sch_stratio_b sch_distvill_b sch_pctboard_b  prin_e_10_1" 
  global maineff = "largeanem largesub largeanemXlarge"
  
 * ----------------------------------------- * 
 * Creating Indicators from student data
 * ----------------------------------------- * 
 
 * Homework Variables
 
 g stu_e_mathhw_comp = (student_e_3_40_corr > 0 & student_e_3_41_corr > 0 ) 
	replace stu_e_mathhw_comp = . if student_e_3_40_corr == . | student_e_3_41_corr == . 

	
 g stu_e_chinhw_comp = (student_e_3_43_corr > 0 & student_e_3_44_corr > 0 )
	replace stu_e_chinhw_comp = . if student_e_3_43_corr == . | student_e_3_44_corr == . 
	
 label var stu_e_mathhw_comp "Indicates if child submitted Maths homework and teacher corrected it"
 label var stu_e_chinhw_comp "Indicates if child submitted Chinese homework and teacher corrected it"
	
 * Teacher asks questions 
 
 g stu_e_math_askqs = (student_e_3_42_corr > 0 & student_e_3_42_corr != .)
	replace stu_e_math_askqs = . if student_e_3_42_corr == .
	
 g stu_e_chin_askqs = (student_e_3_45_corr >0 & student_e_3_45_corr != . )
	replace stu_e_chin_askqs = . if student_e_3_45_corr == .
	
 label var stu_e_math_askqs "Indicates if child was asked questions by maths teacher"
 label var stu_e_chin_askqs "Indicates if child was asked questions by Chinese teacher" 
 
 * Times teacher was absent
 
 //DD: CAREFUL: There are some outliers - check what to do!!!
 
 g stu_e_hometeachabs = student_e_3_54_5_corr
 g stu_e_mathsteachabs = student_e_3_54_6_corr
 g stu_e_chinteachabs = student_e_3_54_7_corr
 g stu_e_sciteachabs = student_e_3_54_8_corr
	replace stu_e_sciteachabs = " " if stu_e_sciteachabs == "没有科学" //No Science teacher
	replace stu_e_sciteachabs = " " if stu_e_sciteachabs == "改上语文" //Change language (?)
	replace stu_e_sciteachabs = " " if stu_e_sciteachabs == "改上英语" //English change (?)
	replace stu_e_sciteachabs = " " if stu_e_sciteachabs == "改上数学" //Maths change (?)
	replace stu_e_sciteachabs = " " if stu_e_sciteachabs == "上其它课" //Other subbject change (?)
	destring stu_e_sciteachabs, replace 
	
 * Correcting for outliers 
 local name "home maths chin sci"
 foreach i of local name {
 replace stu_e_`i'teachabs = . if stu_e_`i'teachabs > 10 
 
}
 
 lab var stu_e_hometeachabs "Number of times homeroom teacher was absent"
 lab var stu_e_mathsteachabs "Number of times maths teacher was absent"
 lab var stu_e_chinteachabs "Number of times chinese teacher was absent"
 lab var stu_e_sciteachabs "Number of times science teacher was absent"
 
 
 *Extracting class code from student code
 
 nsplit stucode, digits (8,2)
 ren stucode1 classcode

  * Student letter grades
 
 *First tagging what schools have a lot of science grade missings (probably, because there is no science)
 gen science_missing=1 if student_e_3_52_corr==.
 replace science_missing=0 if student_e_3_52_corr!=.
 bys classcode: egen science_missing_mean=mean(science_missing)
 

* Inspecting the distribution of missigness of science grades across classes
preserve	
*statsby number=(r(N)), by(schoolcode): sum stu_e_sciscore 
statsby number=(r(mean)), clear by(classcode): sum science_missing 
sort number
list
* There are a lot of classes with all missing, and a lot with zero missings, but some in the middle
restore

  
 * tab student_e_3_46_corr, gen(stu_mathgrade_)
 
 g stu_e_mathgrade_AB = (student_e_3_46_corr == 1 | student_e_3_46_corr == 2)
	replace stu_e_mathgrade_AB = . if student_e_3_46_corr == .
	replace stu_e_mathgrade_AB = . if student_e_3_46_corr == 0
	
 g stu_e_mathgrade_ABC = (student_e_3_46_corr <= 3 & student_e_3_46_corr > 0 ) 
	replace stu_e_mathgrade_ABC = . if student_e_3_46_corr == .
	replace stu_e_mathgrade_ABC = . if student_e_3_46_corr == 0

	
 g stu_e_mathscore = student_e_3_48_corr 
 
 label var stu_e_mathgrade_AB "Student got either A or B grade in last maths exam"
 label var stu_e_mathgrade_ABC "Student got A, B or C grade in last maths exam"
 
 g stu_e_chingrade_AB = (student_e_3_49_corr == 1 | student_e_3_49_corr == 2) 
	replace stu_e_chingrade_AB = . if student_e_3_49_corr == 0 | student_e_3_49_corr == .
	
 g stu_e_chingrade_ABC = (student_e_3_49_corr > 0 & student_e_3_49_corr <= 3)
	replace stu_e_chingrade_ABC = . if student_e_3_49_corr == 0 | student_e_3_49_corr == . 
	
 label var stu_e_chingrade_AB "Student got either A or B grade in last Chinese exam"
 label var stu_e_chingrade_ABC "Student got A, B or C grade in last Chinese exam"	

 g stu_e_chinscore = student_e_3_51_corr

 g stu_e_scigrade_AB = (student_e_3_52_corr == 1 | student_e_3_52_corr == 2) 
	replace stu_e_scigrade_AB = . if student_e_3_52_corr == 0 | student_e_3_52_corr == . 
	
 g stu_e_scigrade_ABC = (student_e_3_52_corr > 0 & student_e_3_52_corr <= 3) 
	replace stu_e_scigrade_ABC = . if student_e_3_52_corr == . | student_e_3_52_corr == 0	
	
g stu_e_sciscore = student_e_3_54_corr	

 label var stu_e_scigrade_AB "Student got either A or B grade in last science exam"
 label var stu_e_scigrade_ABC "Student got A, B or C grade in last science exam"	
	
 g stu_e_enggrade_AB = (student_e_3_54_1_corr == 1 | student_e_3_54_1_corr == 2) 
	replace stu_e_enggrade = . if student_e_3_54_1_corr == . | student_e_3_54_1_corr == 0
	
 g stu_e_enggrade_ABC = (student_e_3_54_1_corr > 0 & student_e_3_54_1_corr <= 3) 
	replace stu_e_enggrade_ABC = . if student_e_3_54_1_corr == . | student_e_3_54_1_corr == 0
	
 label var stu_e_enggrade_AB "Student got either A or B grade in last English exam"
 label var stu_e_enggrade_ABC "Student got A, B or C grade in last English exam"	
 
g stu_e_engscore = student_e_3_54_3_corr 
	replace stu_e_engscore = . if stu_e_engscore > 100 //DD: Correcting for some outliers
 
* Recoding Student letter grades to incorporate them into an index

g stu_e_mathgrade = student_e_3_46_corr
recode stu_e_mathgrade (4=1) (3=2) (2=3) (1=4) 

g stu_e_chingrade = student_e_3_49_corr
recode stu_e_chingrade (4=1) (3=2) (2=3) (1=4)

g stu_e_scigrade = student_e_3_52_corr
recode stu_e_scigrade (4=1) (3=2) (2=3) (1=4)

g stu_e_enggrade = student_e_3_54_1_corr
recode stu_e_enggrade (4=1) (3=2) (2=3) (1=4)

lab var stu_e_mathgrade "Recoded student math letter grade" 
lab var stu_e_chingrade "Recoded student chinese letter grade" 
lab var stu_e_scigrade "Recoded student science letter grade"
lab var stu_e_enggrade "Recoded student english letter grade"
 
* School provided tutoring outside of class

 g stu_e_rectutor = (student_e_3_54_4 == 1) 
	replace stu_e_rectutor = . if student_e_3_54_4 == .
	
lab var stu_e_rectutor "Student received tutoring outside of class" 

/** Teacher absences (student reported)
 g stu_e_hrteach_abs = student_e_3_54_5_corr
 g stu_e_mathsteach_abs = student_e_3_54_6_corr
 g stu_e_chinteach_abs = student_e_3_54_7_corr
 g stu_e_sciteach_abs = student_e_3_54_8_corr
 
 
 lab var stu_e_hrteach_abs "Homeroom teacher absent (times)" 
 lab var stu_e_mathsteach_abs "Maths teacher absent (times)"
 lab var stu_e_chinteach_abs "Chinese teacher absent (times)"
 lab var stu_e_sciteach_abs "Science teacher absent (times)"
*/
 
 
* ------------------------------------ * 
* Creating indicators from School Data 
* ------------------------------------ *

* Number of self study classes 

 g sch_e_selfstudy = sch_e_1_23_corr   
 g sch_e_nssclass = sch_e_1_22_corr - sch_e_1_23_corr
 lab var sch_e_nssclass "Number of classes that are not self study"
 
* Share of cost on "inputs" versus other expenses 
tempvar tot_cost
egen `tot_cost' = rowtotal(sch_e_3_4_corr sch_e_3_5_corr sch_e_3_6_corr sch_e_3_10_corr sch_e_3_11_corr) 
g sch_e_shr_inputcost = `tot_cost'/sch_e_3_14_corr

lab var sch_e_shr_inputcost "Share of total cost spent on inputs"


* ------------------------------------------ * 
* Creating indicators from Principal data 
* ------------------------------------------ * 

* Number of classes taught by the principal in a week

 g prin_e_tchclass = prin_e_2_4_corr

* Topics covered in last parent wide meeting 

forvalues i = 1/6 {
 g prin_e_topic_`i' = (strpos(prin_e_2_6_1_corr, "`i'") > 0 )
 }
 
 g prin_e_topic_nutr = (prin_e_topic_3 == 1 | prin_e_topic_4 == 1) 
	replace prin_e_topic_nutr = . if missing(prin_e_2_6_1_corr)
 
 egen prin_e_topic_tot = rowtotal(prin_e_topic_1 prin_e_topic_2 prin_e_topic_3 prin_e_topic_4 prin_e_topic_5 prin_e_topic_6)
 
 lab var prin_e_topic_nutr "Principal spoke about nutrition and health"
 lab var prin_e_topic_tot "Total number of topics discussed in meeting"
 
 * Topic discussed for longest time 
 
 g prin_e_main_notnutr = 0
 g prin_e_sec_notnutr = 0 
 local numlist "1 2 5 6" 
 foreach i of local numlist { 
	replace prin_e_main_notnutr = 1 if prin_e_2_9_corr == `i'
	replace prin_e_sec_notnutr = 1 if prin_e_2_10_corr == `i'
	}
	
 lab var prin_e_main_notnutr "Topic that was discussed for the most time was NOT nutrition or health"
 lab var prin_e_sec_notnutr "Topic that was dicussed for the second longest amount of time was NOT nutrition or health"
 
 
* Fraction of time spent monitoring teaching 

replace prin_e_9_15_corr = 48 if prin_e_9_15_corr == 480 //DD: Note: 480 appears to be an error and is being corrected to 48
replace prin_e_9_15_corr = 18 if prin_e_9_15_corr == 180 //DD: Note: 180 appears to be an error and is being corrected to 18

tempvar tot_time
egen `tot_time' = rowtotal(prin_e_9_14_corr prin_e_9_15_corr prin_e_9_16_corr prin_e_9_17_corr prin_e_9_18_corr prin_e_9_19_corr prin_e_9_20_corr prin_e_9_21_corr prin_e_9_22_corr prin_e_9_23_corr prin_e_9_24_corr)
tempvar frac
egen `frac' = rowtotal( prin_e_9_15_corr prin_e_9_16_corr)

g prin_e_time_monteach = `frac'/`tot_time'

lab var prin_e_time_monteach "Time spent monitoring teaching"

* Fraction of time spent monitoring students' nutrition and dining

tempvar tot_time
egen `tot_time' = rowtotal(prin_e_9_14_corr prin_e_9_15_corr prin_e_9_16_corr prin_e_9_17_corr prin_e_9_18_corr prin_e_9_19_corr prin_e_9_20_corr prin_e_9_21_corr prin_e_9_22_corr prin_e_9_23_corr prin_e_9_24_corr)
tempvar frac
egen `frac' = rowtotal( prin_e_9_17_corr prin_e_9_21_corr)

g prin_e_time_monfood = `frac'/`tot_time'

lab var prin_e_time_monfood "Time spent monitoring dining halls and students' nutrition"


* Fraction of school expendiutes spent on items to improve students' academic performance 
destring prin_e_11_6_2_corr, g(prin_e_11_6_2_corr_destr) force
replace prin_e_11_6_2_corr_destr = 200 if strpos(prin_e_11_6_2_corr, "200")>0 & prin_e_11_6_2_corr_destr == . //DD: Note: "force" option used as the original variable contained some chinese characters to donate currence

tempvar tot
egen `tot' = rowtotal(prin_e_11_1_2_corr prin_e_11_2_2_corr prin_e_11_3_2_corr prin_e_11_4_2_corr prin_e_11_5_2_corr prin_e_11_6_2_corr_destr prin_e_11_7_2_corr prin_e_11_8_2_corr prin_e_11_9_2_corr prin_e_11_10_2_corr prin_e_11_11_2_corr prin_e_11_12_2_corr prin_e_11_13_2_corr prin_e_11_14_2_corr prin_e_11_15_2_corr prin_e_11_16_2_corr prin_e_11_17_2_corr prin_e_11_18_2_corr prin_e_11_19_2_corr prin_e_11_20_2_corr prin_e_11_21_2_corr prin_e_11_22_2_corr prin_e_11_23_2_corr prin_e_11_24_2_corr prin_e_11_25_2_corr prin_e_11_26_2_corr prin_e_11_27_2_corr prin_e_11_28_2_corr)
tempvar stu 
egen `stu' = rowtotal(prin_e_11_17_2_corr prin_e_11_18_2_corr prin_e_11_19_2_corr prin_e_11_20_2_corr prin_e_11_21_2_corr prin_e_11_22_2_corr prin_e_11_23_2_corr prin_e_11_24_2_corr prin_e_11_25_2_corr prin_e_11_26_2_corr prin_e_11_27_2_corr prin_e_11_28_2_corr)

g prin_e_shsub_stu = `stu'/`tot'

tempvar tot
egen `tot' = rowtotal(prin_e_11_1_3_corr prin_e_11_2_3_corr prin_e_11_3_3_corr prin_e_11_4_3_corr prin_e_11_5_3_corr prin_e_11_6_3_corr prin_e_11_7_3_corr prin_e_11_8_3_corr prin_e_11_9_3_corr prin_e_11_10_3_corr prin_e_11_11_3_corr prin_e_11_12_3_corr prin_e_11_13_3_corr prin_e_11_14_3_corr prin_e_11_15_3_corr prin_e_11_16_3_corr prin_e_11_17_3_corr prin_e_11_18_3_corr prin_e_11_19_3_corr prin_e_11_20_3_corr prin_e_11_21_3_corr prin_e_11_22_3_corr prin_e_11_23_3_corr prin_e_11_24_3_corr prin_e_11_25_3_corr prin_e_11_26_3_corr prin_e_11_27_3_corr prin_e_11_28_3_corr)
tempvar stu 
egen `stu' = rowtotal(prin_e_11_17_3_corr prin_e_11_18_3_corr prin_e_11_19_3_corr prin_e_11_20_3_corr prin_e_11_21_3_corr prin_e_11_22_3_corr prin_e_11_23_3_corr prin_e_11_24_3_corr prin_e_11_25_3_corr prin_e_11_26_3_corr prin_e_11_27_3_corr prin_e_11_28_3_corr)

g prin_e_shtot_stu = `stu'/`tot'

lab var prin_e_shsub_stu "Share of subsidy spent on items related to student performance"
lab var prin_e_shtot_stu "Share to total cost spent on items related to student performance" 

***********************************************************************************************

* ===================== * 
* Baseline Variables 
* ===================== *

* ---------------------- * 
* Student data 
* ---------------------- * 

 * Homework Variables
 
 g stu_b_mathhw_comp = (stu_b_3_5_corr > 0 & stu_b_3_6_corr > 0 ) 
	replace stu_b_mathhw_comp = . if stu_b_3_5_corr == . | stu_b_3_6_corr == . 

	
 g stu_b_chinhw_comp = (stu_b_3_8_corr > 0 & stu_b_3_9_corr > 0 )
	replace stu_b_chinhw_comp = . if stu_b_3_8_corr == . | stu_b_3_9_corr == . 
	
 label var stu_b_mathhw_comp "Indicates if child submitted Maths homework and teacher corrected it"
 label var stu_b_chinhw_comp "Indicates if child submitted Chinese homework and teacher corrected it"

	
 * Teacher asks questions 
 
 g stu_b_math_askqs = (stu_b_3_7_corr > 0 & stu_b_3_7_corr != .)
	replace stu_b_math_askqs = . if stu_b_3_7_corr == .
	
 g stu_b_chin_askqs = (stu_b_3_10_corr >0 & stu_b_3_10_corr != . )
	replace stu_b_chin_askqs = . if stu_b_3_10_corr == .
	
 label var stu_b_math_askqs "Indicates if child was asked questions by maths teacher"
 label var stu_b_chin_askqs "Indicates if chidl was asked questions by Chinese teacher" 
 
 * Student letter grades
 
 * tab student_e_3_46_corr, gen(stu_mathgrade_)
 
 g stu_b_mathgrade_AB = (stu_b_3_11_corr == 1 | stu_b_3_11_corr == 2)
	replace stu_b_mathgrade_AB = . if stu_b_3_11_corr == .
	replace stu_b_mathgrade_AB = . if stu_b_3_11_corr == 0
	
 g stu_b_mathgrade_ABC = (stu_b_3_11_corr <= 3 & stu_b_3_11_corr > 0 ) 
	replace stu_b_mathgrade_ABC = . if stu_b_3_11_corr == .
	replace stu_b_mathgrade_ABC = . if stu_b_3_11_corr == 0

	
 g stu_b_mathscore = stu_b_3_13_corr 
 
 label var stu_b_mathgrade_AB "Student got either A or B grade in last maths exam"
 label var stu_b_mathgrade_ABC "Student got A, B or C grade in last maths exam"
 
 g stu_b_chingrade_AB = (stu_b_3_14_corr == 1 | stu_b_3_14_corr == 2) 
	replace stu_b_chingrade_AB = . if stu_b_3_14_corr == 0 | stu_b_3_14_corr == .
	
 g stu_b_chingrade_ABC = (stu_b_3_14_corr > 0 & stu_b_3_14_corr <= 3)
	replace stu_b_chingrade_ABC = . if stu_b_3_14_corr == 0 | stu_b_3_14_corr == . 
	
 label var stu_b_chingrade_AB "Student got either A or B grade in last Chinese exam"
 label var stu_b_chingrade_ABC "Student got A, B or C grade in last Chinese exam"	

 g stu_b_chinscore = stu_b_3_16_corr

 g stu_b_scigrade_AB = (stu_b_3_17_corr == 1 | stu_b_3_17_corr == 2) 
	replace stu_b_scigrade_AB = . if stu_b_3_17_corr == 0 | stu_b_3_17_corr == . 
	
 g stu_b_scigrade_ABC = (stu_b_3_17_corr > 0 & stu_b_3_17_corr <= 3) 
	replace stu_b_scigrade_ABC = . if stu_b_3_17_corr == . | stu_b_3_17_corr == 0	

 label var stu_b_scigrade_AB "Student got either A or B grade in last science exam"
 label var stu_b_scigrade_ABC "Student got A, B or C grade in last science exam"	
 
 g stu_b_sciscore = stu_b_3_19_corr
	
 
* Recoding Student letter grades to incorporate them into an index

g stu_b_mathgrade = stu_b_3_11_corr
recode stu_b_mathgrade (4=1) (3=2) (2=3) (1=4) 

g stu_b_chingrade = stu_b_3_14_corr
recode stu_b_chingrade (4=1) (3=2) (2=3) (1=4)

g stu_b_scigrade = stu_b_3_17_corr
recode stu_b_scigrade (4=1) (3=2) (2=3) (1=4)


lab var stu_b_mathgrade "Recoded student math letter grade" 
lab var stu_b_chingrade "Recoded student chinese letter grade" 
lab var stu_b_scigrade "Recoded student science letter grade"
 
 
* ----------------------- * 
* School Data
* ----------------------- * 

* Number of classes that are not self study
 g sch_b_selfstudy = sch_b_1_23_corr   
 g sch_b_nssclass = sch_b_1_22_corr - sch_b_1_23_corr
 lab var sch_b_nssclass "Number of classes that are not self study"
 
 * Share of cost on "inputs" versus other expenses 
tempvar tot_cost
egen `tot_cost' = rowtotal(sch_b_3_4_corr sch_b_3_5_corr sch_b_3_6_corr sch_b_3_10_corr sch_b_3_11_corr) 
g sch_b_shr_inputcost = `tot_cost'/sch_b_3_13_corr

lab var sch_b_shr_inputcost "Share of total cost spent on inputs"

* ---------------------------- *
* Principal Data
* ---------------------------- *

* Number of classes taught by the principal in a week

 g prin_b_tchclass = prin_b_2_4_corr
 
 * Topics covered in last parent wide meeting 

forvalues i = 1/6 {
 g prin_b_topic_`i' = (strpos(prin_b_2_6_corr, "`i'") > 0 )
 }
 
 g prin_b_topic_nutr = (prin_b_topic_3 == 1 | prin_b_topic_4 == 1) 
	replace prin_b_topic_nutr = . if missing(prin_b_2_6_corr)
 
 egen prin_b_topic_tot = rowtotal(prin_b_topic_1 prin_b_topic_2 prin_b_topic_3 prin_b_topic_4 prin_b_topic_5 prin_b_topic_6)
 
 lab var prin_b_topic_nutr "Principal spoke about nutrition and health"
 lab var prin_b_topic_tot "Total number of topics discussed in meeting"
 
  * Topic discussed for longest time 
 
 g prin_b_main_notnutr = 0
 g prin_b_sec_notnutr = 0 
 local numlist "1 2 5 6" 
 foreach i of local numlist { 
	replace prin_b_main_notnutr = 1 if prin_b_2_9_corr == `i'
	replace prin_b_sec_notnutr = 1 if prin_b_2_10_corr == `i'
	}
	
 lab var prin_b_main_notnutr "Topic that was discussed for the most time was NOT nutrition or health"
 lab var prin_b_sec_notnutr "Topic that was dicussed for the second longest amount of time was NOT nutrition or health"
 
 
* Fraction of time spent monitoring teaching 

*replace prin__corr = 48 if prin_e_9_15_corr == 480 //DD: Note: 480 appears to be an error and is being corrected to 48
*replace prin_e_9_15_corr = 18 if prin_e_9_15_corr == 180 //DD: Note: 180 appears to be an error and is being corrected to 18

tempvar tot_time
egen `tot_time' = rowtotal(prin_b_9_4_corr prin_b_9_5_corr prin_b_9_6_corr prin_b_9_7_corr prin_b_9_8_corr prin_b_9_9_corr prin_b_9_10_corr prin_b_9_11_corr prin_b_9_12_corr prin_b_9_13_corr prin_b_9_14_corr)
tempvar frac
egen `frac' = rowtotal( prin_b_9_5_corr prin_b_9_6_corr)

g prin_b_time_monteach = `frac'/`tot_time'

lab var prin_b_time_monteach "Time spent monitoring teaching"

* Fraction of time spent managing student meals/cafeteria operations 

tempvar tot_time
egen `tot_time' = rowtotal(prin_b_9_4_corr prin_b_9_5_corr prin_b_9_6_corr prin_b_9_7_corr prin_b_9_8_corr prin_b_9_9_corr prin_b_9_10_corr prin_b_9_11_corr prin_b_9_12_corr prin_b_9_13_corr prin_b_9_14_corr)
tempvar frac
egen `frac' = rowtotal(prin_b_9_7_corr prin_b_9_11_corr)

g prin_b_time_monfood = `frac'/`tot_time'

lab var prin_b_time_monfood "Time spent monitoring dining hall and students' nutrition"

********************************************************************************
* -------------------------- * 
* Merging Teacher Data
* -------------------------- *	
 
 
 * Merging Data from Maths Teachers
 
 merge m:1 classcode using "$temp\Multitasking_mathsteachers_june2016.dta", gen(_maths_merge)
 merge m:1 classcode using "$temp\Multitasking_chineseteachers_june2016.dta", gen(_chinese_merge)
 
 
 * ----------------------------------------------- * 
 * Creating some new variables using teacher data
 * ----------------------------------------------- *
 
 * Re-scaling student exam marks using maxpts variables from teacher dataset
  local ending "e b"
 foreach i of local ending {
 g scale_stu_`i'_mathscore = 100*stu_`i'_mathscore/maths_teacher_`i'_maths_maxpts if _maths_merge == 3 & maths_teacher_`i'_maths_maxpts != .
	replace scale_stu_`i'_mathscore = 100 * stu_`i'_mathscore/chinese_teacher_`i'_maths_maxpts if _chinese_merge == 3 & scale_stu_`i'_mathscore == . 
	
 g scale_stu_`i'_chinscore = 100*stu_`i'_chinscore/chinese_teacher_`i'_chin_maxpts if _chinese_merge == 3 & chinese_teacher_`i'_maths_maxpts != .
	replace scale_stu_`i'_chinscore = 100*stu_`i'_chinscore/maths_teacher_`i'_chin_maxpts if _maths_merge == 3 & scale_stu_`i'_chinscore == .
  
 lab var scale_stu_`i'_mathscore "Students' percentage score on last maths exam" 
 lab var scale_stu_`i'_chinscore "Students' percentage score on last chinese exam" 
 
 
 * Using number of homework assignments to compute the share that were graded 
 }

 g sh_e_mathshw_graded = 100*student_e_3_40_corr/maths_teacher_e_hw if _maths_merge == 3 & stu_e_mathhw_comp == 1
 g sh_e_chinhw_graded = 100*student_e_3_43_corr/chinese_teacher_e_hw if _chinese_merge == 3 & stu_e_chinhw_comp == 1
	
 g sh_b_mathshw_graded = 100*stu_b_3_5_corr/maths_teacher_b_hw if _maths_merge == 3 & stu_b_mathhw_comp == 1
 g sh_b_chinhw_graded = 100*stu_b_3_8_corr/chinese_teacher_b_hw if _chinese_merge == 3 & stu_b_chinhw_comp == 1	
 
local ending "e b"
 foreach i of local ending {
 lab var sh_`i'_mathshw_graded "Share of maths homework that was graded by teacher"
 lab var sh_`i'_chinhw_graded "Share of chinese homework that was graded by teacher"
 }
 
 //DD: CAREFUL: There are many observations where the share graded is greater than 100 percent! 
 //This means either the student or the teacher has reported incorrectly. I am correcting these to be less than or equal to 100. 
 
local ending "e b"
local name "mathshw chinhw"
foreach i of local ending {
	foreach j of local name {
		replace sh_`i'_`j'_graded = . if sh_`i'_`j'_graded > 100
		}
		}
 
 
 * ========================================== * 
 * Creating Indices to then run regressions
 * ========================================== * 
 
* Time in class devoted to learning (including tutoring etc) 


local negative "maths_teacher_e_time_selfstudy maths_teacher_e_time_distrvit chinese_teacher_e_time_selfstudy chinese_teacher_e_time_distrvit"
local k = 0
foreach i of local negative {
	local k = `k' + 1
	g neg_`k' = -1 * `i'
	}
	
local negative "maths_teacher_b_time_selfstudy chinese_teacher_b_time_selfstudy"
local k = 4
foreach i of local negative {
	local k = `k' + 1
	g neg_`k' = -1 * `i'
	}
 
ren maths_teacher* mteach*
ren chinese_teacher* cteach*
 
//DD: NOTE: neg_2 = -1 * math_teacher_e_time_distrvit -> dropped due to too many missing values 
 aindex mteach_e_time_newmat mteach_e_time_askqs mteach_e_time_review mteach_e_time_tlss mteach_e_tutor mteach_e_tutorlw cteach_e_time_newmat cteach_e_time_askqs cteach_e_time_review cteach_e_time_tlss cteach_e_tutor cteach_e_tutorlw neg_1 neg_3 neg_4, gen(e_learning_index)
 aindex mteach_b_time_newmat mteach_b_time_askqs mteach_b_time_review mteach_b_time_tlss mteach_b_tutor mteach_b_tutorlw cteach_b_time_newmat cteach_b_time_askqs cteach_b_time_review cteach_b_time_tlss cteach_b_tutor cteach_b_tutorlw neg_5 neg_6, gen(b_learning_index)
 
 drop neg*
 
* Communication with parents 
local ending "e b"
foreach q of local ending {
local negative "prin_`q'_main_notnutr prin_`q'_sec_notnutr prin_`q'_topic_tot"
local k = 4
foreach i of local negative { 
	local k = `k' + 1
	g neg_`k' = -1 * `i'
	}
	
	
* NOTE: The two negative variables only take value -1 and therefore have been left out of the index 	

aindex prin_`q'_topic_nutr mteach_`q'_par_health cteach_`q'_par_health neg_7, gen(`q'_comm_index)

drop neg*

}	
	
* Management/Administrative and class planning     

//DD: NOTE: sh_e_mathshw_graded sh_e_chinhw_graded mteach_e_hrs_tutor sh_b_mathshw_graded sh_b_chinhw_graded -> Dropped due to too many missing values 

aindex prin_e_time_monteach  mteach_e_hrs_hw mteach_e_hrs_prep  mteach_e_hrs_prepmain mteach_e_hrs_prepsec mteach_e_obsprin cteach_e_hrs_hw cteach_e_hrs_prep cteach_e_hrs_tutor cteach_e_hrs_prepmain cteach_e_hrs_prepsec cteach_e_obsprin, gen(e_mgmt_index)
aindex prin_b_time_monteach  mteach_b_hrs_hw mteach_b_hrs_prep mteach_b_hrs_tutor mteach_b_hrs_prepmain mteach_b_hrs_prepsec mteach_b_obsprin cteach_b_hrs_hw cteach_b_hrs_prep cteach_b_hrs_tutor cteach_b_hrs_prepmain cteach_b_hrs_prepsec cteach_b_obsprin, gen(b_mgmt_index) 
 
* Budget and Resources

aindex prin_e_shsub_stu prin_e_shtot_stu sch_e_shr_inputcost sch_e_nssclass, gen(e_res_index)

* Student Grades

aindex stu_e_mathgrade stu_e_chingrade, gen(e_grade_index_1)
aindex stu_e_scigrade stu_e_enggrade, gen(e_grade_index_2)
aindex stu_e_mathgrade stu_e_chingrade stu_e_scigrade stu_e_enggrade, gen(e_grade_index_3)
aindex stu_e_scigrade stu_e_enggrade, gen(e_grade_index_4)


aindex stu_b_mathgrade stu_b_chingrade, gen(b_grade_index_1)
aindex stu_b_mathgrade stu_b_chingrade stu_b_scigrade, gen(b_grade_index_2)
aindex stu_b_mathgrade stu_b_chingrade stu_b_scigrade, gen(b_grade_index_3)

* Computing old education index
 
 g stu_absent_lw_b = (stu_b_3_1_corr > 0)
	replace stu_absent_lw_b = . if stu_b_3_1_corr == . //DD: indicators if the student was absent last week
	
 g stu_absent_lw_e = (student_e_3_36_corr > 0)
	replace stu_absent_lw_e = . if student_e_3_36_corr == . 
	

local negative "home maths chin sci"
foreach q of local negative {
	g negstu_e_`q'teachabs = (stu_e_`q'teachabs>0) * (-1)
	}
	
foreach i of varlist stu_absent_lw_b stu_absent_lw_e {
	g `i'_neg = `i'* (-1)
	}
	
	
	
*sh_b_chinhw_graded sh_b_mathshw_graded -> These have too many missings

*aindex stu_absent_lw_b_neg   stu_b_math_askqs stu_b_chin_askqs stu_b_mathhw_comp stu_b_chinhw_comp , gen(b_educ_index)
*  aindex stu_absent_lw_e_neg sh_e_mathshw_graded stu_e_math_askqs stu_e_chin_askqs  negstu_e_mathsteachabs negstu_e_chinteachabs negstu_e_hometeachabs, gen(e_educ_index)
  
* Education index without student absences

aindex  stu_b_math_askqs stu_b_chin_askqs   , gen(b_educ_index)
  aindex sh_e_mathshw_graded  stu_e_math_askqs stu_e_chin_askqs  negstu_e_mathsteachabs negstu_e_chinteachabs negstu_e_hometeachabs, gen(e_educ_index) 
   
/*
   * Saving this dataset (to use before using statsby)

save "$temp/Multitasking_workingdata.dta", replace
	
* Checking for missing science scores
	
*statsby number=(r(N)), by(schoolcode): sum stu_e_sciscore 
statsby number=(r(mean)), by(schoolcode): sum science_missing 
*/



*  sh_e_chinhw_graded sh_b_chinhw_graded
* stu_b_mathhw_comp stu_b_chinhw_comp stu_e_mathhw_comp stu_e_chinhw_comp
*********************************************************************************

exit

* =================== * 
* Regressions
* =================== * 

* FDR Regressions 

* Student grade regressions

local dep "mathgrade_AB chingrade_AB mathgrade_ABC chingrade_ABC mathgrade chingrade scigrade mathscore chinscore sciscore"
  foreach var of local dep {
	fdr (stu_e_`var' $maineff stu_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum stu_e_`var' if e(sample)
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
local dep "scigrade sciscore enggrade enggrade_AB enggrade_ABC engscore"
  foreach var of local dep {
	fdr (stu_e_`var' $maineff $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum stu_e_`var' if e(sample)
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
    mat c = (nullmat(c)\ results)
    mat list c
	}
//DD: mathshw_graded: Not included because of too many missing 	
local dep " chinhw_graded"
foreach var of local dep {
	fdr (sh_e_`var' $maineff sh_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum sh_e_`var' if e(sample)
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
    mat x = (nullmat(x)\ results)
    mat list x
	mat v = (x\b\c)
	
	}
	
	preserve
	drop _all
	svmat2 v, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Student_effects.xls", replace
	restore
	mat drop v b x c
	
	


	
* Grade Indices 
local dep "grade_index_1 grade_index_2 grade_index_3"
  foreach var of local dep {
	fdr (e_`var' $maineff b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum e_`var' if e(sample)
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

*stu_b_scigrade stu_b_chingrade b_grade_index_1
local dep "grade_index_4"
  foreach var of local dep {
	fdr (e_`var' $maineff stu_b_mathgrade $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum e_`var' if e(sample)
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
    mat v = (b\ results)
    mat list v
	
}
	preserve
	drop _all
	svmat2 v, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Grade_indices.xls", replace
	restore
	mat drop b
	
* Teacher Absences 	

local dep "hometeachabs mathsteachabs chinteachabs sciteachabs"
  foreach var of local dep {
	fdr (stu_e_`var' $maineff $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum stu_e_`var' if e(sample)
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
	outsheet using "$outdir\StudentReported_TeacherAbsence.xls", replace
	restore
	mat drop b


* Teachers' time variables
/*
local subj "mteach cteach"
foreach i of local subj {
local dep "time_newmat time_askqs time_review time_tlss tutor tutorlw time_newmat time_selfstudy" 
 foreach var of local dep {
	fdr (`i'_e_`var' $maineff `i'_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
	    , testvar($maineff) hypadd() cluster(schoolcode)             ///
	    method(BKY)     
* Store all results
	mat variable = J(1,6,.)
	//mat list variable
	mat rownames variable = "`var'"
    mat mat_`var' = r(result)
    //mat list mat_`var'
    mat rownames mat_`var' = $maineff 
    //mat list mat_`var'
    mat empty = J(1,6,.)
    //mat list empty 
	mat rownames empty = .
    mat results = variable\mat_`var'\empty
	mat colnames results = beta se t pvalue adjusted rejected  
    mat drop variable mat_`var' empty
    mat b = (nullmat(b)\ results)
    mat list b
	
}
	preserve
	drop _all
	svmat2 b, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Learning_`i'.xls", replace
	restore
	mat drop b
	}
	*/
	
* Indexes
	
local list "learning_index comm_index mgmt_index educ_index"
foreach var of local list {	
fdr (e_`var' $maineff b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum e_`var' if e(sample)
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

local list "res_index"
foreach var of local list {	
fdr (e_`var' $maineff $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum e_`var' if e(sample)
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
	mat v = (b\ results)
    mat list v	
	
	}
	preserve
	drop _all
	svmat2 v, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Indexes.xls", replace
	restore
	mat drop v b
	
* Collapsing dataset to school level

collapse *tchclass *topic_nutr *topic_tot *main_notnutr *sec_notnutr *time_monteach *time_monfood prin_e_shsub_stu prin_e_shtot_stu	*shr_inputcost $maineff $sch_cov $stu_cov countycode strata, by(schoolcode)
	
* 	Principal Data

local list "tchclass topic_nutr topic_tot main_notnutr sec_notnutr time_monteach time_monfood"
foreach var of local list {	
fdr (prin_e_`var' $maineff prin_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum prin_e_`var' if e(sample)
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
	outsheet using "$outdir\Principal_inputs.xls", replace
	restore
	mat drop b	
	
* Costs 

local list "prin_e_shsub_stu prin_e_shtot_stu"
foreach var of local list {	
fdr (`var' $maineff $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum `var' if e(sample)
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
local list "shr_inputcost"
foreach var of local list {	
fdr (sch_e_`var' $maineff sch_b_`var' $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum sch_e_`var' if e(sample)
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
	mat v = (b\ results)
    mat list v	
	
	}
	
	preserve
	drop _all
	svmat2 v, rname(variable) name(col)
	order variable, first
	outsheet using "$outdir\Costs.xls", replace
	restore
	mat drop v b
	
log close	
	
/*	
* Education Index

local list "educ_index"
foreach var of local list {	
fdr (`var'_e $maineff `var'_b $sch_cov $stu_cov i.countycode i.strata) ///
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
	qui sum `var'_e if e(sample)
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
	outsheet using "$outdir\EducationIndex_new.xls", replace
	restore
	mat drop b		

log close

