capture log close

log using "ols_regression_stata.log",replace

/* PhD Practicum, Spring 2019 */
/* Outputting regression results*/
/* Will Doyle*/
/* 1/22/19 */
/* Saved on OAK */

clear

ssc install plotbeta

/*Locals for system */

local tab_type rtf  /*I use tex, word=rtf */

local gtype eps /*Png or bmp for windows */

/* Check to see if file exists if not then download it. */
capture confirm file caschool.dta

if _rc==601{
use http://fmwww.bc.edu/ec-p/data/stockwatson/caschool.dta
save caschool, replace
} /* End Download Section */

use caschool, clear

/// Transformations of key independent variables

gen expn_stu_k=expn_stu/1000

gen comp_stu_h=comp_stu*100

gen str_20=str>=20

replace str_20=. if str==.

/*Label variables*/

label variable testsc "Combined test scores"

label variable avginc "Average income"

label variable el_pct "Pct English Lang Learners"

label variable calw_pct "Pct of Families on Welfare"

label variable meal_pct "Pct Free/Reduced Lunch"

label variable str "Student/Teacher Ratio"

label variable expn_stu "Expenditures/student"

label variable expn_stu_k "Expenditures/student (1000s)"

label variable comp_stu "Computers/Student"

label variable comp_stu_h "Computers/100 Students"

label variable str_20 "Avg Class Size>20"

label variable read_scr "Reading Score"

/*Locals for groups of variables*/

local y read_scr

local ytitle "Reading Score"

local students avginc el_pct calw_pct meal_pct

local teacher str str_20

local finance expn_stu_k

local computers comp_stu_h

estimates clear


/* Setting up and outputting descriptive stats */

eststo descriptives: estpost tabstat `y' `students' `teacher' `finance', ///
    statistics(mean sd) ///
    columns(statistics) 


   
esttab descriptives using esttab_means.`tab_type' , ///
    main(mean) ///
    aux(sd) ///
    nostar ///
    nonote ///
    label ///
    nonumber ///
    replace 

	
/* Describing conditional mean of outcome as a function of covariates*/

/* Three groups: small class size, middle, and large */
sum str, detail 
  
gen class_size=str<=r(p25)

replace class_size=2 if str>r(p25)&str<=r(p75)

replace class_size=3 if str>r(p75)

replace class_size=. if str==.

label define sizes 1 "Small Class Size" 2 "Medium Class Size"  3 "Large Class Size"

label values class_size sizes

/*Summary table */

eststo descriptives_size: estpost tabstat `y' `students' `teacher' `finance', ///
    by(class_size) ///
    statistics(mean sd) ///
    columns(statistics) ///
    listwise 

esttab descriptives_size using esttab_means_size.`tab_type', ///
    main(mean) ///
    aux(sd) ///
    nostar ///
    nonote ///
    label ///
    unstack ///
    nonumbers ///
    nomtitles ///
	collabels(none) ///
    replace 

/* Three groups: small class size, middle, and large */
sum expn_stu_k, detail 
  
gen expend_level=expn_stu_k<=r(p25)

local perc25=round(r(p25),0)

replace expend_level=2 if expn_stu_k>r(p25)&expn_stu_k<=r(p75)

replace expend_level=3 if expn_stu_k>r(p75)

replace expend_level=. if expn_stu_k==.

label define expend_levels 1 "Low Spending" 2 "Moderate Spending"  3 "High Spending"

label values expend_level expend_levels


/*Summary table */

eststo descriptives_spending: estpost tabstat `y' `students' `teacher' `finance', ///
    by(expend_level) ///
    statistics(mean sd) ///
    columns(statistics) ///
    listwise 

esttab descriptives_spending using esttab_means_spend.`tab_type', ///
    main(mean) ///
    aux(sd) ///
    nostar ///
    nonote ///
    label ///
    unstack ///
    nonumbers ///
    nomtitles ///
	collabels(none) ///
    replace 
	 
	
/* Estimate Models */
	
quietly reg `y' `teacher'
estimates store teach_model, title ("Model 1")                                

quietly reg `y'  `teacher' `students'
estimates store st_tch_model, title ("Model 2")

quietly reg `y' `teacher' `students'  `finance'
estimates store st_tch_fin_model, title ("Model 3")

quietly reg `y'  `teacher' `students' `finance' `computers'
estimates store st_tch_fin_comp_model, title ("Model 4")

#delimit;

esttab *_model using `y'_models.`tab_type',     /* estout command: * indicates all estimates in memory. rtf specifies rich text, best for word */
               label                          /*Use labels for models and variables */
               nodepvars                      /* Use my model titles */
               b(2)                           /* b= coefficients , this gives two sig digits */
               se(2)                         /* I do want standard errors */
               r2 (2)                      /* R squared */
               ar2 (2)                     /* Adj R squared */
               scalar(F  "df_m DF model"  "df_r DF residual" N)   /* select stats from the ereturn (list) */
               sfmt (2 0 0 0)                /* format for scalar stats*/
               replace                   /* replace existing file */
               ;

#delimit cr
 
#delimit ;
// Redo table, this time include t stats instead of se and no stars!

esttab *_model using `y'_models_b.`tab_type',      /* estout command: * indicates all estimates in memory. rtf specifies rich text, best for word */
               label                          /*Use labels for models and variables */
               nodepvars                      /* Use my model titles */
               b(2)                           /* b= coefficients , this gives two sig digits */
               t(2)                         /* I do want t-stats */
			   nostar 						/* No p value stars */
               r2 (2)                      /* R squared */
               ar2 (2)                     /* Adj R squared */
               scalar(F  "df_m DF model"  "df_r DF residual" N)   /* select stats from the ereturn (list) */
               sfmt (2 0 0 0)                /* format for scalar stats*/
               replace                   /* replace existing file */
               ;

#delimit cr

#delimit ;
// Redo table, this time include CI instead of se and 4 significant digits!

esttab *_model using `y'_models_c.`tab_type',      /* estout command: * indicates all estimates in memory. rtf specifies rich text, best for word */
               label                          /*Use labels for models and variables */
               nodepvars                      /* Use my model titles */
               b(4)                           /* b= coefficients , this gives two sig digits */
               ci(4)                         /* I do want t-stats */
			   nostar 						/* No p value stars */
               r2 (4)                      /* R squared */
               ar2 (4)                     /* Adj R squared */
               scalar(F  "df_m DF model"  "df_r DF residual" N)   /* select stats from the ereturn (list) */
               sfmt (2 0 0 0)                /* format for scalar stats*/
               replace                   /* replace existing file */
               ;

#delimit cr


/// Plotting regression results

estimates restore teach_model

#delimit;
plotbeta  avginc|el_pct|calw_pct|meal_pct|str_20|str, /*Variables in regression to report */
          labels                              /*Use Variable Labels*/
          xtitle (Parameters)                 /*Label of x axis*/
          title ("Model w/ No Covariates")    /*Title */ 
          subtitle ("From OLS regression. Dep Var= `ytitle'") /*Description */
          xline(0,lp(dash)) /* Line at 0: if 95% ci crosses, not stat sig */
          xscale(range(-1.5 4)) /* Range of X axis*/
		  xlabel(-4(.5)4)
		  scale(.5)
		  ;

#delimit cr
 
graph save teach_model, replace

estimates restore st_tch_model

#delimit;
plotbeta avginc|el_pct|calw_pct|meal_pct|str_20|str, /*Variables in regression to report */
          labels                              /*Use Variable Labels*/
          xtitle (Parameters)                 /*Label of x axis*/
          title ("Model w/ Student Chars")    /*Title */ 
          subtitle ("From OLS regression. Dep Var= `ytitle'") /*Description */
          xline(0,lp(dash)) /* Line at 0: if95% ci crosses, not stat sig */
          xscale(range(-1.5 4)) /* Range of X axis*/
		  xlabel(-4(.5)4)
		  scale(.5)
		  ;

#delimit cr

graph save st_teach_model, replace

estimates restore st_tch_fin_model

#delimit;
plotbeta avginc|el_pct|calw_pct|meal_pct|expn_stu_k|str_20|str,
          labels
          xtitle (Parameters)
          title ("Model w/ Spending")
          subtitle ("From OLS regression. Dep Var= `ytitle'")
          xline(0,lp(dash))
          xscale(range(-1.4 4))
          xlabel(-4(.5)4)
		  scale(.5)
		  ;

graph save st_teach_fin_model,replace;

estimates restore st_tch_fin_comp_model; 

#delimit;
plotbeta avginc|el_pct|calw_pct|meal_pct|expn_stu_k|comp_stu|str_20|str,
          labels
          xtitle (Parameters)
          title ("Full Model")
          subtitle ("From OLS regression. Dep Var= `ytitle'")
          xline(0,lp(dash))
          xscale(range(-1.4 4))
          xlabel(-4(.5)4)
		  scale(.5)
		  ;

graph save st_teach_fin_comp_model,replace;

graph combine teach_model.gph //
	st_teach_model.gph //
	st_teach_fin_model.gph //
	st_teach_fin_comp_model.gph
	,
         cols(2)
         rows(2)
         ;

#delimit cr

graph export all_models.`gtype', replace 

exit




