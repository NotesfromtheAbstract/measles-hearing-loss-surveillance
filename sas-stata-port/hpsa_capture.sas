/******************************************************************************
  Outbreak-county HPSA capture summary.

  Reproduces the rounded table from track3_hpsa_capture.R.
  Read data/outbreak_counties.csv. For each county:

    capture probability = 0.18 * exp(-0.145 * HPSA score)
    expected hearing-loss cases = confirmed cases * 0.0085
    captured cases = expected hearing-loss cases * capture probability

  Round each result to three decimals with R's tie rule, then write the
  table to the log between BEGIN_HPSA_CAPTURE_TABLE and
  END_HPSA_CAPTURE_TABLE. Compare that block with
  r_reference/r_output.txt.
******************************************************************************/

/* Folder that contains outbreak_counties.csv.
   SYSGET(HOME) returns the home directory in SAS OnDemand for Academics.
   Upload outbreak_counties.csv to that folder, or point datadir at the
   data folder, for example /home/your-user-id/sas-stata-port/data.
   No trailing slash. */
%let datadir = %sysget(HOME);

options linesize=256;

/******************************************************************************
  Step 1. Read the county extract.
  Columns: state abbreviation, county name, confirmed cases, HPSA score.
******************************************************************************/
data outbreak;
  infile "&datadir/outbreak_counties.csv" dsd truncover firstobs=2 lrecl=200;
  length state_abbr $2 county_clean $20;
  input state_abbr :$2. county_clean :$20. cases hpsa_score;
  /* Row number keeps tied case counts in the original file order. */
  seq = _n_;
run;

/******************************************************************************
  Step 2. Apply the capture formula from the R script.
******************************************************************************/
proc sql;
  create table modeled as
  select state_abbr,
         county_clean,
         cases,
         hpsa_score,
         seq,
         0.18 * exp(-0.145 * hpsa_score) as capture_prob,
         cases * 0.0085 as expected_hl_raw,
         calculated capture_prob * calculated expected_hl_raw
           as expected_hl_captured
  from outbreak;
quit;

/******************************************************************************
  Step 3. Round to three decimals the way R's round(x, 3) does.
  Pick the nearer thousandth. When the value sits exactly halfway
  between two thousandths, keep the even thousandth.
  Gaines County is a halfway case: 393 * 0.0085 = 3.3405, and the
  printed raw hearing-loss count is 3.340.
  The SAS ROUND function uses the other halfway rule and prints 3.341
  for that row, so this step does not call ROUND.
******************************************************************************/
data rounded;
  set modeled;
  array xin{3} capture_prob expected_hl_raw expected_hl_captured;
  array thou{3} thou_cap thou_raw thou_capd;
  do i = 1 to 3;
    x = xin{i};
    x10 = x * 1000;
    i10 = floor(x10);
    xd = i10 / 1000;
    xu = ceil(x10) / 1000;
    du = xu - x;
    dd = x - xd;
    if du < dd or (mod(i10, 2) = 1 and du = dd) then thou{i} = ceil(x10);
    else thou{i} = i10;
  end;
  drop i x x10 i10 xd xu du dd;
run;

/******************************************************************************
  Step 4. Put the largest outbreaks first.
  Counties with the same case count stay in file order.
******************************************************************************/
proc sort data=rounded;
  by descending cases seq;
run;

/* Stop if the extract is not the 20-county table. */
data _null_;
  if 0 then set rounded nobs=nobs;
  if nobs ne 20 then do;
    put "ERROR: Expected 20 counties but found " nobs ".";
    abort cancel;
  end;
  stop;
run;

/******************************************************************************
  Step 5. Write the comparison table to the log.
  Each data line is 83 characters, the same width as r_output.txt.
******************************************************************************/
data _null_;
  set rounded end=last;
  file log ls=256;
  length fcap $12 fraw $15 fcapd $20 line $120;

  fcap = cats(int(thou_cap / 1000), ".", put(mod(thou_cap, 1000), z3.));
  fcap = right(fcap);
  fraw = cats(int(thou_raw / 1000), ".", put(mod(thou_raw, 1000), z3.));
  fraw = right(fraw);
  fcapd = cats(int(thou_capd / 1000), ".", put(mod(thou_capd, 1000), z3.));
  fcapd = right(fcapd);

  if _n_ = 1 then do;
    put "BEGIN_HPSA_CAPTURE_TABLE";
    put "Outbreak county HPSA summary (v2 recalibrated)";
    put "county     state cases hpsa_score capture_prob expected_hl_raw expected_hl_captured";
  end;

  line = cat(put(county_clean, $10.), " ",
             put(state_abbr, $5.), " ",
             put(cases, 5.), " ",
             put(hpsa_score, 10.), " ",
             fcap, " ",
             fraw, " ",
             fcapd);
  len = length(line);
  put line $varying120. len;

  if last then put "END_HPSA_CAPTURE_TABLE";
run;
