* Outbreak-county HPSA capture summary.
* Reproduces the rounded table from track3_hpsa_capture.R.
*
* Run this file with the working directory set to sas-stata-port:
*     cd "/path/to/sas-stata-port"
*     do hpsa_capture.do
*
* The log is written to stata_output.log in that directory.
* Base Stata 15 or newer. No add-on packages.
*
* capture probability       = 0.18 * exp(-0.145 * HPSA score)
* expected hearing-loss cases = confirmed cases * 0.0085
* captured cases            = expected hearing-loss cases * capture probability

version 15
set more off
set linesize 255
set varabbrev off
capture log close
log using "stata_output.log", text replace

* Step 1. Read the same county extract the R reference reads.
import delimited "data/outbreak_counties.csv", varnames(1) case(preserve) asdouble stringcols(1 2) clear
quietly count
if r(N) != 20 {
    display as error "Expected 20 outbreak counties in data/outbreak_counties.csv."
    exit 459
}

* Row number keeps tied case counts in the original file order.
gen long seq = _n

* Step 2. Apply the capture formula from the R script.
gen double capture_prob = 0.18 * exp(-0.145 * hpsa_score)
gen double expected_hl_raw = cases * 0.0085
gen double expected_hl_captured = expected_hl_raw * capture_prob

* Step 3. Round to three decimals the way R's round(x, 3) does.
* Pick the nearer thousandth. When the value sits exactly halfway
* between two thousandths, keep the even thousandth.
* Gaines County is a halfway case: 393 * 0.0085 = 3.3405, and the
* printed raw hearing-loss count is 3.340.
* The result is stored as an integer count of thousandths so the
* printed decimals do not get rounded a second time.
foreach v in capture_prob expected_hl_raw expected_hl_captured {
    tempvar x10 i10 xd xu du dd take_up
    gen double `x10' = `v' * 1000
    gen double `i10' = floor(`x10')
    gen double `xd' = `i10' / 1000
    gen double `xu' = ceil(`x10') / 1000
    gen double `du' = `xu' - `v'
    gen double `dd' = `v' - `xd'
    gen byte `take_up' = (`du' < `dd') | (mod(`i10', 2) == 1 & `du' == `dd')
    gen double thou_`v' = cond(`take_up', ceil(`x10'), `i10')
    drop `x10' `i10' `xd' `xu' `du' `dd' `take_up'
}

* Step 4. Put the largest outbreaks first.
* Counties with the same case count stay in file order.
gsort -cases seq

* Step 5. Write the comparison table.
* Spaces are written one at a time so the fixed columns survive
* into stata_output.log unchanged. The block between the BEGIN
* and END lines matches r_reference/r_output.txt.
capture program drop write_fixed
program define write_fixed
    args text width side
    local n = strlen("`text'")
    local npad = `width' - `n'
    if `npad' > 0 & "`side'" == "R" {
        forvalues p = 1/`npad' {
            file write cap " "
        }
    }
    file write cap "`text'"
    if `npad' > 0 & "`side'" == "L" {
        forvalues p = 1/`npad' {
            file write cap " "
        }
    }
end

capture program drop thou_text
program define thou_text, rclass
    args thou
    local whole = floor(`thou' / 1000)
    local frac = mod(`thou', 1000)
    local frac_s = strtrim(string(`frac', "%12.0f"))
    local frac_s = "00" + "`frac_s'"
    local len = strlen("`frac_s'")
    local frac_s = substr("`frac_s'", `len' - 2, 3)
    return local piece "`whole'.`frac_s'"
end

capture file close cap
file open cap using "_hpsa_capture_table.txt", write replace text
file write cap "BEGIN_HPSA_CAPTURE_TABLE" _n
file write cap "Outbreak county HPSA summary (v2 recalibrated)" _n
file write cap "county     state cases hpsa_score capture_prob expected_hl_raw expected_hl_captured" _n

forvalues i = 1/`=_N' {
    local county = county_clean[`i']
    local st = state_abbr[`i']
    local cases_txt = strtrim(string(cases[`i'], "%12.0f"))
    local score_txt = strtrim(string(hpsa_score[`i'], "%12.0f"))
    thou_text thou_capture_prob[`i']
    local cap_piece = r(piece)
    thou_text thou_expected_hl_raw[`i']
    local raw_piece = r(piece)
    thou_text thou_expected_hl_captured[`i']
    local capd_piece = r(piece)

    write_fixed "`county'" 10 L
    file write cap " "
    write_fixed "`st'" 5 L
    file write cap " "
    write_fixed "`cases_txt'" 5 R
    file write cap " "
    write_fixed "`score_txt'" 10 R
    file write cap " "
    write_fixed "`cap_piece'" 12 R
    file write cap " "
    write_fixed "`raw_piece'" 15 R
    file write cap " "
    write_fixed "`capd_piece'" 20 R
    file write cap _n
}

file write cap "END_HPSA_CAPTURE_TABLE" _n
file close cap

type "_hpsa_capture_table.txt"
erase "_hpsa_capture_table.txt"
log close
