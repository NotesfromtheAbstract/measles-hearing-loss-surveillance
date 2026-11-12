# SAS and Stata port: outbreak-county HPSA capture

## Question

In the 2025 measles outbreak counties, what share of expected measles-associated hearing-loss cases reaches a coded, measles-linked diagnosis at each county's primary-care HPSA score?

This folder reproduces the rounded county table behind the capture curve in `track3_hpsa_capture.R` (the table that script prints under "Outbreak county HPSA summary"). For each county the R script calculates:

- capture probability = `0.18 * exp(-0.145 * HPSA score)`
- expected hearing-loss cases = `confirmed cases * 0.0085`
- captured cases = expected hearing-loss cases times the capture probability

`0.0085` is the Cohen et al. 2014 midpoint hearing-loss rate. Results are rounded to three decimals with the same rule as R's `round(x, 3)`.

## Data

`data/outbreak_counties.csv` is the analytic input. It has one row per outbreak county: state, county, confirmed cases, and the HPSA score used in the capture table. `r_reference/build_analytic_extract.R` writes that CSV from the `outbreak_counties` table in `track3_hpsa_capture.R`, so SAS and Stata start from the same rows the R analysis uses. Each row is a published case count and an assigned HPSA score from that script.

Case counts in that table are the counts coded in `track3_hpsa_capture.R`, cited there to:

- Texas Department of State Health Services, "Texas announces end of West Texas measles outbreak," 18 August 2025. <https://www.dshs.texas.gov/news-alerts/texas-announces-end-west-texas-measles-outbreak>
- CDC MMWR 74(14), 24 April 2025 (Mathis et al.). <https://doi.org/10.15585/mmwr.mm7414a1>
- New Mexico Department of Health and Oklahoma State Department of Health outbreak reports, as named in the R script

HPSA scores in that table are the scores assigned in the R script from HRSA Area Health Resources Files and HRSA data portal lookups:

- HRSA Area Health Resources Files. <https://data.hrsa.gov/topics/health-workforce/ahrf>
- HRSA data portal. <https://data.hrsa.gov/>

The R script also downloads the HRSA Bureau of Health Workforce primary-care HPSA detail file and uses it for the state counts in Figure 3D. That file is a separate source from the capture table.

| Item | Value |
|---|---|
| Agency | U.S. Health Resources and Services Administration, Bureau of Health Workforce |
| Dataset | Primary Care Health Professional Shortage Area (HPSA) detail file, `BCD_HPSA_FCT_DET_PC.csv` |
| URL | <https://data.hrsa.gov/DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv> |
| Downloaded | 12 November 2026 |
| Server last-modified | 10 November 2026, 12:02:11 GMT |
| File | 49,341,283 bytes, 81,033 data rows |

On that download, designated HPSA scores for these counties differ from the scores in the capture table. Gaines County is a designated High Needs Geographic HPSA with score 13 in the file; the capture table uses score 20. Motley County is a designated Geographic HPSA with score 9; the capture table uses score 20. Terry County has a designated low-income population HPSA with score 18 and no designated geographic HPSA; the capture table uses score 17. The port keeps the scores from `track3_hpsa_capture.R` so the rounded table matches that script.

## Data note

The current HRSA bulk file lists Gaines County at HPSA score 13 and Motley County at 9, while track3_hpsa_capture.R uses 20 for both. The port reproduces the script as written.

## How to run

### R

From the repository root, or from any working directory:

```bash
Rscript sas-stata-port/r_reference/build_analytic_extract.R
Rscript sas-stata-port/r_reference/hpsa_capture_reference.R
```

The second script reads `data/outbreak_counties.csv` and writes `r_reference/r_output.txt`. Base R is enough. The reference script checks that its three-decimal rounding matches `round(x, 3)`.

### SAS OnDemand for Academics

1. Upload `data/outbreak_counties.csv` to your SAS OnDemand home directory. The program reads `&datadir/outbreak_counties.csv`.
2. Open `hpsa_capture.sas` and run it.
3. The home directory comes from `%let datadir = %sysget(HOME);`. To use a different folder, replace that line with the folder that contains the CSV and leave off the trailing slash. Example: `%let datadir = /home/your-user-id/sas-stata-port/data;`
4. In the log, compare the block between `BEGIN_HPSA_CAPTURE_TABLE` and `END_HPSA_CAPTURE_TABLE` with `r_reference/r_output.txt`.

The program uses a DATA step, PROC SQL, and PROC SORT. Block comments use `/* */`. A `*` comment in SAS runs until the next semicolon, and a `*` line with no semicolon swallows the next statement. The three-decimal step follows R's halfway rule (keep the even thousandth). Gaines County raw hearing-loss cases are the halfway value 3.3405, which this table prints as 3.340.

This program was run in SAS OnDemand for Academics on Nov 11, 2026: 0 errors, 0 warnings, output identical to R. The log block is `sas_output/sas_output.txt`. The full log is `sas_output/hpsa_capture_log.html`. Each saved log line has the blank SAS writes in column 1; the characters after that blank match `r_reference/r_output.txt`.

### Stata

Stata 15 or newer, with no add-on packages. From the `sas-stata-port` directory:

```stata
cd "/path/to/sas-stata-port"
do hpsa_capture.do
```

The do-file writes `stata_output.log` with `log using`. Compare the block between `BEGIN_HPSA_CAPTURE_TABLE` and `END_HPSA_CAPTURE_TABLE` with `r_reference/r_output.txt`. Lines Stata echoes as commands are marked with a leading period; the table text under `type` is the block to compare. A `*` at the start of a line is a one-line comment in Stata. It ends at the newline, and every `*` comment in `hpsa_capture.do` starts in column 1. The file has no `/*` block comment.

## Results

R values are the three-decimal figures in `r_reference/r_output.txt`. They match the rounded columns printed by `track3_hpsa_capture.R`. SAS was run in SAS OnDemand for Academics on Nov 11, 2026: 0 errors, 0 warnings, output identical to R. The Stata column is not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt.

| County | State | Cases | HPSA score | R capture probability | R expected hearing-loss cases | R captured cases | SAS | Stata |
|---|---|---:|---:|---:|---:|---:|---|---|
| GAINES | TX | 393 | 20 | 0.010 | 3.340 | 0.033 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| TERRY | TX | 89 | 17 | 0.015 | 0.757 | 0.012 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| YOAKUM | TX | 72 | 16 | 0.018 | 0.612 | 0.011 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| LYNN | TX | 48 | 18 | 0.013 | 0.408 | 0.005 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| LEA | NM | 42 | 14 | 0.024 | 0.357 | 0.008 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| GARZA | TX | 35 | 17 | 0.015 | 0.298 | 0.005 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| DAWSON | TX | 27 | 15 | 0.020 | 0.230 | 0.005 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| LUBBOCK | TX | 24 | 5 | 0.087 | 0.204 | 0.018 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| HOCKLEY | TX | 18 | 16 | 0.018 | 0.153 | 0.003 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| COCHRAN | TX | 14 | 19 | 0.011 | 0.119 | 0.001 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| OKLAHOMA | OK | 14 | 8 | 0.056 | 0.119 | 0.007 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| CROSBY | TX | 10 | 16 | 0.018 | 0.085 | 0.002 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| TULSA | OK | 10 | 6 | 0.075 | 0.085 | 0.006 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| CHAVES | NM | 9 | 13 | 0.027 | 0.077 | 0.002 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| FLOYD | TX | 8 | 17 | 0.015 | 0.068 | 0.001 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| EDDY | NM | 8 | 12 | 0.032 | 0.068 | 0.002 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| CANADIAN | OK | 7 | 10 | 0.042 | 0.060 | 0.003 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| ROOSEVELT | NM | 6 | 16 | 0.018 | 0.051 | 0.001 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| COMANCHE | OK | 6 | 12 | 0.032 | 0.051 | 0.002 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |
| MOTLEY | TX | 5 | 20 | 0.010 | 0.043 | 0.000 | matches R | not run: Stata not available to the author of the port; run hpsa_capture.do and compare stata_output.log with r_reference/r_output.txt |

Motley County's captured-case value prints as 0.000 after rounding to three decimals.

## Authorship

The SAS and Stata ports in this folder were written by an AI coding assistant (Gus, Grok Bot) at Andrew Crocker's direction; the original R analysis is Andrew's.
