# Measles-Associated Hearing Loss and Surveillance Failure

**Companion code for ["The Burden That Was Never Counted"](https://andrewrcrocker.substack.com/p/the-burden-that-was-never-counted) — *Notes from the Abstract***

This repository contains the R code and data sources behind a three-track analysis of how measles-associated hearing loss disappears from surveillance data. The analysis demonstrates that the gap is structural, produced by encounter-based coding workflows that systematically disconnect downstream complications from their original infectious cause, and that the gap widens dramatically in communities with the fewest healthcare resources.

## What this project does

The code produces 13 publication-ready figures across three analytical tracks. All data is either embedded in the scripts (historical case counts, outbreak county data) or downloaded at runtime from public federal sources (HRSA HPSA designations). No private or restricted data is required.

## Repository structure

```
R/
├── track1_historical_burden.R      # Historical cases + projected hearing loss, 1950–2025
├── track2_outbreak_anatomy.R       # 2025 outbreak demographics, geography, surveillance funnel
└── track3_hpsa_capture.R           # HPSA shortage analysis + capture probability model
```

## Track descriptions

### Track 1: Historical Measles Burden and Projected Hearing Loss

Reconstructs the annual and cumulative burden of measles-associated hearing loss in the United States from 1950 to 2025 using CDC historical case series and the 0.5%–1.3% hearing loss complication rate from Cohen, Durstenfeld, and Roehm (2014). Pre-vaccine era true infections are estimated at 6.5x reported cases per CDC methodology.

**Figures produced:**
- `track1_fig1a_reported_cases.png` — Reported measles cases with vaccine era annotations
- `track1_fig1b_projected_hl.png` — Projected annual hearing loss cases with uncertainty band
- `track1_fig1c_cumulative_hl.png` — Cumulative projected hearing loss, 1950–2000
- `track1_fig1d_era_comparison.png` — Era comparison bar chart
- `track1_combined.png` — Four-panel overview layout

### Track 2: 2025 Outbreak Anatomy

Characterizes the 2025 U.S. measles outbreak (2,281 confirmed cases) with focus on age distribution, geographic concentration in West Texas, audiologist access gaps, and a per-1,000-case surveillance funnel modeling how hearing loss cases are lost at each step from infection to coded diagnosis. The funnel uses Cohen et al.'s 0.85% midpoint hearing loss rate and compares urban insured populations against the rural outbreak epicenter.

**Figures produced:**
- `track2_fig2a_age_distribution.png` — Age distribution of outbreak cases
- `track2_fig2b_geography.png` — Geographic concentration by location
- `track2_fig2c_funnel.png` — Surveillance funnel: infection to coded diagnosis
- `track2_fig2d_access.png` — Audiologist access by location

### Track 3: Shortage Areas, Outbreak Risk, and Surveillance Capture

Downloads HRSA Health Professional Shortage Area (HPSA) primary care data and maps outbreak county case burden against shortage severity. Models surveillance capture probability as an exponential function of HPSA score, anchored at 18% (urban, no shortage), 5.28% (VA integrated system benchmark from Wander et al. 2023), and <1% (maximum shortage). Shows projected hearing loss cases captured versus lost to surveillance by county.

**Figures produced:**
- `track3_fig3a_hpsa_vs_cases.png` — Case burden vs. HPSA shortage severity
- `track3_fig3b_capture_curve.png` — Capture probability by HPSA score
- `track3_fig3c_captured_vs_lost.png` — Captured vs. lost hearing loss cases by county
- `track3_fig3d_national_context.png` — Vaccination rates vs. shortage burden by state

## Requirements

**R version:** 4.1.0 or later

**Packages** (installed automatically if missing):
- `tidyverse`
- `scales`
- `patchwork`
- `ggtext`

**External data** (downloaded at runtime by Track 3):
- HRSA Bureau of Health Workforce HPSA primary care bulk file ([data.hrsa.gov](https://data.hrsa.gov/DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv))

## Running the code

Each track is a standalone script. Run them in any order from the `R/` directory:

```r
source("R/track1_historical_burden.R")
source("R/track2_outbreak_anatomy.R")
source("R/track3_hpsa_capture.R")
```

All figures save to the working directory by default. Change `output_dir` at the top of each script to redirect output.

Track 3 requires an internet connection to download the HRSA HPSA file (~50 MB). Tracks 1 and 2 run entirely offline.

## Key parameters

| Parameter | Value | Source |
|---|---|---|
| Hearing loss rate (low) | 0.5% of infections | Cohen et al. 2014 |
| Hearing loss rate (mid) | 0.85% of infections | Cohen et al. 2014 |
| Hearing loss rate (high) | 1.3% of infections | Cohen et al. 2014 |
| Pre-vaccine undercount factor | 6.5x reported cases | CDC |
| Urban capture probability | ~18% | Model estimate |
| VA system benchmark | 5.28% | Wander et al. 2023 |
| Maximum-shortage capture | <1% | Model estimate |

## Important methodological notes

All hearing loss projections are **modeled estimates**, not measured outcomes. The complication rate of 0.5%–1.3% encompasses both the otitis media pathway and the direct cochlear damage pathway. The surveillance funnel (Track 2) and capture probability curve (Track 3) are **conceptual models** fitted to empirical anchors rather than derived from observational surveillance data. They are presented with uncertainty bands to reflect that distinction.

The capture probability model was calibrated using long COVID sequela coding rates from the VA health system (Wander et al. 2023, JAMA Network Open) as an independent benchmark for the coding linkage step. The VA's 5.28% sequela coding rate at 12 months represents the best-case scenario for a fully integrated EHR system with a dedicated purpose-built ICD-10 code.

HPSA scores for outbreak epicenter counties are assigned from HRSA Area Health Resources Files and county-level provider data, not from the geographic HPSA designation file. Many isolated rural counties lack formal HPSA designation because the application process requires administrative infrastructure they do not have. Absence from the shortage list is not evidence of adequate care.

## Data sources

1. Cohen BE, Durstenfeld A, Roehm PC. Viral causes of hearing loss: a review for hearing health professionals. *Trends Hear.* 2014;18:2331216514541361. [doi:10.1177/2331216514541361](https://doi.org/10.1177/2331216514541361)
2. Mathis AD, Raines K, Filardo TD, et al. Measles update — United States, January 1–April 17, 2025. *MMWR.* 2025;74(14):232-238. [doi:10.15585/mmwr.mm7414a1](https://doi.org/10.15585/mmwr.mm7414a1)
3. Garuccio J, et al. Using supply and demand to identify shortages in the hearing health care professional workforce. *JAMA Otolaryngol Head Neck Surg.* 2025;151(9):868-873. [doi:10.1001/jamaoto.2025.2112](https://doi.org/10.1001/jamaoto.2025.2112)
4. Kingsbury S, et al. Barriers to equity in pediatric hearing health care. *Perspect ASHA Spec Interest Groups.* 2022;7(4):1060-1071. [doi:10.1044/2021_PERSP-21-00188](https://doi.org/10.1044/2021_PERSP-21-00188)
5. Wander PL, et al. Rates of ICD-10 code U09.9 documentation and clinical characteristics of VA patients with post-COVID-19 condition. *JAMA Netw Open.* 2023;6(12):e2346783. [doi:10.1001/jamanetworkopen.2023.46783](https://doi.org/10.1001/jamanetworkopen.2023.46783)
6. Elzinga HBE, et al. Relation between otitis media and sensorineural hearing loss: a systematic review. *BMJ Open.* 2021;11(8):e050108. [doi:10.1136/bmjopen-2021-050108](https://doi.org/10.1136/bmjopen-2021-050108)
7. Drösler SE, Weber S, Chute CG. New ICD-11 features for coding late sequelae. *BMC Med Inform Decis Mak.* 2025;25(1):318. [doi:10.1186/s12911-025-03121-5](https://doi.org/10.1186/s12911-025-03121-5)
8. CDC historical measles case series via [Our World in Data](https://ourworldindata.org/measles) and MMWR Annual Summary 1993 Vol. 42 No. 53
9. Texas DSHS Measles Outbreak Investigation: Final Report, August 18, 2025
10. PAHO/WHO Disease Outbreak News, April 17, 2025
11. HRSA Bureau of Health Workforce [HPSA data](https://data.hrsa.gov/topics/health-workforce/shortage-areas) and [Area Health Resources Files](https://data.hrsa.gov/topics/health-workforce/ahrf)

## Article figure mapping

Five of the 13 figures appear in the published article:

| Article figure | Description | File |
|---|---|---|
| Figure 1 | Reported cases, 1950–2025 | `track1_fig1a_reported_cases.png` |
| Figure 2 | Projected HL cases, 1950–2025 | `track1_fig1b_projected_hl.png` |
| Figure 3 | Geographic concentration | `track2_fig2b_geography.png` |
| Figure 4 | Surveillance funnel | `track2_fig2c_funnel.png` |
| Figure 5 | Capture probability curve | `track3_fig3b_capture_curve.png` |

The remaining 8 figures provide supplementary context and are available from the author on request or by running the code.

## License

This work is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). You are free to share and adapt the material with appropriate attribution.

## Author

Andrew — [Notes from the Abstract](https://notesfromtheabstract.substack.com/)
