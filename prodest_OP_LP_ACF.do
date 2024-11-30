
use data, clear

*********************************************************
**** 0. install the prodest package 
*********************************************************
/*
ssc install prodest
ssc install ftools
ssc install gtools
*/

*********************************************************
**** 1. clean the data and generate relevant variables***
*********************************************************

***** We make use of the following variables (in thousands of 1982 peso)

* pro: Output
* k   : capital
* labor : labor (# of Employees)
* mat : material

****************** 1.1 Generate investment (for OP)

* set panel structure

xtset id year

*** geneate investment as the difference of current capital and past undepreciated capital
*** set a depreciation rate of 0.074 (a weighted average of BEA depreciation rates for equipment and structure)

gen inv = k- (1-0.074)*L.k

* Notice that more than 25% of investment is non-positive, which is a potential drawback for OP.
sum inv, d 

****************** 1.2 generate log variables

gen log_y   = log(pro)
gen log_k   = log(k)
gen log_l   = log(labor)
gen log_m   = log(mat)

gen log_inv = log(inv)

******************************************************
***2. OP estimation
******************************************************

** trim the op sample selection by bottom and top 0.5% of input-output ratio of all inputs and investment-capital ratio

gen op = 0

replace op =1 if log_y!=. &  log_l!=. &  log_k!=. &  log_m!=. &  log_inv!=. 

gen log_k_y =   log_k- log_y
gen log_l_y =   log_l- log_y
gen log_m_y =   log_m- log_y
gen log_inv_k = log_inv- log_k

gstats winsor log_k_y log_l_y log_m_y log_inv_k if op ==1 , suffix(_op_tr) trim cuts(1 99)

replace op =0 if (log_k_y_op_tr==. | log_l_y_op_tr ==. | log_m_y_op_tr ==. | log_inv_k_op_tr==.) & op ==1

* carry out the OP estimation for the sample

prodest log_y if op==1, free(log_l log_m) state(log_k) proxy(log_inv)  met(op)  opt(dfp) reps(50) id(id) t(year) fsresiduals(op_fsres)

gen ln_tfp_op   = log_y-_b[log_k]*log_k-_b[log_l]*log_l -_b[log_m]*log_m  if op==1


******************************************************
***2. LP estimation
******************************************************

** trim the lp sample selection by bottom and top 0.5% of input-output ratio of all inputs 

gen lp = 0

replace lp =1 if log_y!=. &  log_l!=. &  log_k!=. &  log_m!=.  

gstats winsor log_k_y log_l_y log_m_y   if lp ==1 , suffix(_lp_tr) trim cuts(1 99)

replace lp =0 if (log_k_y_lp_tr==. | log_l_y_lp_tr ==. | log_m_y_lp_tr ==.) & lp ==1

* carry out the LP estimation for the sample

prodest log_y  if lp==1, free(log_l) state(log_k) proxy(log_m)  met(lp) opt(dfp) reps(50) id(id) t(year) fsresiduals(lp_fsres)

gen ln_tfp_lp  = log_y-_b[log_k]*log_k-_b[log_l]*log_l -_b[log_m]*log_m  if lp==1

******************************************************
***3.1 OP estimation with ACF correction
******************************************************

* Note: Although still somewhat commonly used, ACF (2015) did point out that Gross Output Production Fucntion might not be correctly identified under ACF correction.
  
prodest log_y if op==1, free(log_l log_m) state(log_k) proxy(log_inv) met(op) acf opt(dfp) reps(50) id(id) t(year) fsresiduals(op_acf_fsres)

gen ln_tfp_op_acf  = log_y-_b[log_k]*log_k-_b[log_l]*log_l -_b[log_m]*log_m  if op==1


******************************************************
***3.2 LP estimation with ACF correction
******************************************************

* Note: One needs to care about the optimization challenge of ACF. You could play with  init(".4,.5,.3") and opt()

prodest log_y  if lp==1, free(log_l) state(log_k) proxy(log_m)  met(lp) acf    reps(50) id(id) t(year)  init(".4,.5,.3") fsresiduals(lp_acf_fsres)

gen ln_tfp_lp_acf = log_y-_b[log_k]*log_k-_b[log_l]*log_l -_b[log_m]*log_m  if lp==1

save data_post_est, replace
  
  
  
  
***************************************************
* 4. Check correlations
***************************************************
  
binscatter ln_tfp_op ln_tfp_lp, name(g1, replace) title("OP vs. LP")
binscatter ln_tfp_op ln_tfp_op_acf, name(g2, replace) title("OP vs. OP ACF")
binscatter ln_tfp_op ln_tfp_op_acf, name(g3, replace) title("LP vs. LP ACF")
binscatter ln_tfp_op_acf ln_tfp_lp_acf, name(g4, replace) title("OP ACF vs. LP ACF")

graph combine g1 g2 g3 g4, col(2) row(2) title("Comparison of Different Methods")


graph export comparison.pdf, replace 











  
  
  