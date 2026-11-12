# ============================================================
# NOTES FROM THE ABSTRACTS
# Track 2: 2025 Outbreak Anatomy & The Double Invisibility Problem
#
# Sources:
#   - MMWR 74(14), April 24, 2025 (Mathis et al.)
#     DOI: 10.15585/mmwr.mm7414a1
#   - PAHO/WHO Disease Outbreak News, April 17, 2025
#   - Texas DSHS final outbreak report, August 18, 2025
#   - CDC Measles Cases and Outbreaks 2025
#   - PMC12135429 (Measles outbreaks in the US, 2025)
#   - Garuccio et al. (2025) JAMA Otolaryngol Head Neck Surg
#     DOI: 10.1001/jamaoto.2025.2112
#   - Cohen, Durstenfeld & Roehm (2014) Trends in Hearing
#     DOI: 10.1177/2331216514541361
#   - Kingsbury et al. (2022) Perspectives ASHA Spec Interest Groups
#     DOI: 10.1044/2021_PERSP-21-00188
#   - Elzinga et al. (2021) BMJ Open — OM/SNHL systematic review
#     DOI: 10.1136/bmjopen-2021-050108
#   - Rosenfeld et al. (2016) AAO-HNSF OME Clinical Practice Guideline
#     DOI: 10.1177/0194599815623467
#   - Wander et al. (2023) JAMA Netw Open — VA U09.9 coding rates
#     DOI: 10.1001/jamanetworkopen.2023.46783
#   - Pfaff et al. (2023) BMC Medicine — Long COVID ICD-10 coding
#     DOI: 10.1186/s12916-023-02737-6
# ============================================================

required_packages <- c("tidyverse", "scales", "patchwork", "ggtext")

install.packages(
  setdiff(required_packages, rownames(installed.packages())),
  repos = "https://cran.rstudio.com/"
)

library(tidyverse)
library(scales)
library(ggtext)
library(patchwork)

# ── Custom theme ────────────────────────────────────────────
theme_1950s <- function() {
  theme_minimal(base_family = "Arial", base_size = 14) +
    theme(
      plot.background  = element_rect(fill = "#FAF5E9", color = NA),
      panel.background = element_rect(fill = "#FAF5E9", color = NA),
      panel.grid.major = element_line(color = "#E6DECA", linewidth = 0.6),
      panel.grid.minor = element_blank(),
      axis.title       = element_text(face = "bold", color = "#3A3A3A"),
      axis.text        = element_text(color = "#4A4A4A"),
      plot.title       = element_text(face = "bold", size = 20, color = "#3A3A3A"),
      plot.subtitle    = element_text(size = 13, color = "#5A5A5A"),
      plot.margin      = margin(15, 15, 15, 15),
      legend.position  = "none"
    )
}

# ============================================================
# 1. DATA
# ============================================================

# ── Age distribution of 2025 outbreak cases ────────────────
# Source: PAHO/WHO Disease Outbreak News, April 17, 2025
# Based on 800 confirmed cases as of April 17, 2025
age_data <- tribble(
  ~age_group, ~pct, ~n,
  "Under 5",  31,   249,
  "5-19",     38,   304,
  "20+",      29,   231,
  "Unknown",   2,    16
) %>%
  mutate(
    age_group = factor(age_group,
      levels = c("Under 5", "5-19", "20+", "Unknown")),
    bar_color = c("#C9392C", "#E8874A", "#5B8DB8", "#AAAAAA")
  )

# ── Geographic concentration of full-year 2025 cases ───────
# Sources: Texas DSHS final report (Aug 18, 2025); MMWR 74(14);
# CDC Measles Cases and Outbreaks 2025; PMC12135429
# Full-year total: 2,281 confirmed cases
# Gaines County (393) from PMC12135429, recorded as of ~April 24
# Texas final total: 762 (DSHS); NM: ~65; OK: ~37; KS: ~57 (linked)
# Remaining cases distributed across 39 other jurisdictions
geo_data <- tribble(
  ~location,                        ~cases, ~bar_color,
  "All other states",               1360,   "#AAAAAA",
  "Kansas (linked)",                  57,   "#AAAAAA",
  "Oklahoma",                         37,   "#4A9E6B",
  "New Mexico (4 counties)",          65,   "#5B8DB8",
  "Other West TX (23 counties)",     369,   "#E8874A",
  "Gaines Co., TX (epicenter)",      393,   "#C9392C"
) %>%
  mutate(location = factor(location, levels = location))

# ── Surveillance funnel: pathway from infection to coded HL ─
# Per 1,000 measles cases, modeled for two community types
#
# PARAMETER DOCUMENTATION (v3 — corrected HL rate):
#
# CRITICAL CHANGE FROM v2:
# v2 used a decomposition of 17% OM rate × 50% OM-to-HL rate,
# producing an effective hearing loss rate of 8.5%. This is
# approximately 10× the published complication rate from the
# primary source (Cohen et al. 2014: 0.5%–1.3%). The 50%
# OM-to-HL conversion figure was not supported by the audiology
# literature; Elzinga et al. (2021) found SNHL prevalence in
# COM populations ranges from ~9% to ~31% in ENT clinic settings
# (selected, sicker populations), and could not perform
# meta-analysis due to heterogeneity. For acute OM in children
# (which is what measles produces), permanent SNHL rates would
# be substantially lower.
#
# v3 uses Cohen et al.'s direct hearing loss rate of 0.85%
# (midpoint of 0.5%–1.3%), which already accounts for BOTH
# pathways: (a) OM → SNHL, and (b) direct cochlear damage.
# This produces ~9 HL cases per 1,000 infections.
#
# Step 1 (baseline): 1,000 cases in each community
#
# Step 2 (develop hearing loss): ~9 per 1,000 (0.85%)
#   Cohen et al. 2014 range: 0.5%–1.3% of measles infections
#   develop hearing loss through otitis media pathway (primary)
#   or direct cochlear damage (secondary). Midpoint 0.85% used.
#   Rate is biological and applied equally to both communities.
#
# Step 3 (reach audiologist for evaluation):
#   Urban/insured: ~6 of 9 (~67%)
#     AAO-HNSF OME guideline (Rosenfeld et al. 2016) recommends
#     watchful waiting for 3 months before hearing referral.
#     Even with good access, some families don't follow through,
#     mild high-frequency loss may not prompt referral, and the
#     guideline delay narrows the follow-up window.
#   Outbreak epicenter: ~3 of 9 (~33%)
#     No audiologist in Gaines County; nearest is 60+ miles away.
#     Insurance, transportation, language, and community trust
#     barriers compound the geographic distance.
#     (Garuccio et al. 2025; Kingsbury et al. 2022)
#
# Step 4 (hearing loss correctly identified & documented):
#   Urban: ~4 of 6 (~67%)
#   Epicenter: ~2 of 3 (~67%)
#     Applied equally. Elzinga et al. (2021) found OM-related
#     SNHL concentrates at higher frequencies (cochlear base
#     proximal to round window). Mild high-frequency SNHL is
#     masked by concurrent conductive loss from effusion. Even
#     with comprehensive audiometric evaluation, not all
#     measles-related SNHL will be identified.
#
# Step 5 (measles linkage preserved in ICD-10 coding):
#   Unchanged from v2. Calibrated against long COVID U09.9
#   sequela coding rates (Wander et al. 2023 JAMA Netw Open).
#   Urban: ~18% → 4 × 0.18 = 0.72, rounded to ~1
#   Epicenter: ~2% → 2 × 0.02 = 0.04, displayed as "<1"
#   (See v2 notes for full VA benchmark rationale)

funnel_data <- tribble(
  ~step, ~step_label,                              ~urban_n, ~epicenter_n,
  1,     "Measles cases\n(baseline)",              1000,     1000,
  2,     "Develop hearing loss\n(0.85% rate)",        9,        9,
  3,     "Reach audiologist\nfor evaluation",          6,        3,
  4,     "Hearing loss\ncorrectly identified",         4,        2,
  5,     "Measles linkage\npreserved in coding",     0.7,     0.04
) %>%
  mutate(step = factor(step, levels = 5:1))

# NOTE on Step 5 values:
#   Urban:     4 × 0.18 = 0.72
#   Epicenter: 2 × 0.02 = 0.04
#   Both display as "<1" in the figure.
#   This means that per 1,000 measles cases, neither community
#   reliably produces even ONE coded case linking hearing loss
#   to measles. The difference is one of degree: urban might
#   produce ~1 coded case per ~1,400 infections; the epicenter
#   might produce ~1 per ~25,000.

funnel_long <- funnel_data %>%
  pivot_longer(
    cols      = c(urban_n, epicenter_n),
    names_to  = "community",
    values_to = "n"
  ) %>%
  mutate(
    community = recode(community,
      "urban_n"     = "Urban / insured",
      "epicenter_n" = "Outbreak epicenter\n(rural, low-income)"
    ),
    community = factor(community, levels = c(
      "Outbreak epicenter\n(rural, low-income)",
      "Urban / insured"
    ))
  )

# ── Audiologist access by location ─────────────────────────
# (Unchanged from v2)
access_data <- tribble(
  ~location,                          ~aud_per_100k, ~category,
  "National average",                  4.0,          "benchmark",
  "Urban benchmark\n(Lubbock, TX)",    5.8,          "benchmark",
  "Texas rural average\n(est.)",       1.2,          "shortage",
  "West TX outbreak\ncounties (est.)", 0.4,          "shortage",
  "Gaines County\n(epicenter)",        0.0,          "epicenter"
) %>%
  mutate(
    location  = factor(location, levels = rev(location)),
    bar_color = case_when(
      category == "benchmark" ~ "#5B8DB8",
      category == "shortage"  ~ "#E8874A",
      TRUE                    ~ "#C9392C"
    )
  )

# ============================================================
# 2. FIGURE 2A — Age distribution
# ============================================================

fig2a <- ggplot(age_data, aes(x = age_group, y = pct, fill = bar_color)) +
  geom_col(width = 0.62, alpha = 0.88) +
  geom_text(
    aes(label = paste0(pct, "%\n(n=", n, ")")),
    vjust = -0.4, size = 3.8, fontface = "bold", color = "#3A3A3A"
  ) +
  scale_fill_identity() +
  scale_y_continuous(
    limits = c(0, 50),
    expand = c(0, 0),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "2025 U.S. Measles Outbreak: Age Distribution",
    subtitle = "Children under 20 accounted for 69% of confirmed cases",
    x        = "Age group",
    y        = "Share of cases",
    caption  = paste0(
      "Source: PAHO/WHO Disease Outbreak News, April 17, 2025; ",
      "MMWR 74(14), April 24, 2025.\n",
      "Based on 800 confirmed cases as of April 17, 2025. ",
      "Full-year 2025 total: 2,281 confirmed cases."
    )
  ) +
  theme_1950s()

# ============================================================
# 3. FIGURE 2B — Geographic concentration
# ============================================================

fig2b <- ggplot(geo_data,
    aes(x = cases, y = location, fill = bar_color)) +
  geom_col(width = 0.62, alpha = 0.88) +
  geom_text(
    aes(label = label_comma()(cases)),
    hjust = -0.15, size = 3.8, fontface = "bold", color = "#3A3A3A"
  ) +
  scale_fill_identity() +
  scale_x_continuous(
    limits = c(0, 1750),
    expand = c(0, 0),
    labels = label_comma()
  ) +
  labs(
    title    = "2025 U.S. Measles Outbreak: Geographic Concentration",
    subtitle = "One county in West Texas had more confirmed cases than any other state in the country",
    x        = "Confirmed cases",
    y        = NULL,
    caption  = paste0(
      "Sources: Texas DSHS final outbreak report, August 18, 2025; ",
      "MMWR 74(14); CDC Measles Cases and Outbreaks 2025.\n",
      "Gaines County case count from PMC12135429. ",
      "Full-year 2025 total: 2,281 confirmed cases."
    )
  ) +
  theme_1950s() +
  theme(panel.grid.major.y = element_blank())

# ============================================================
# 4. FIGURE 2C — Surveillance funnel
# ============================================================

fig2c <- ggplot(funnel_long,
    aes(x = n, y = step, fill = community)) +
  geom_col(
    position = position_dodge(width = 0.72),
    width = 0.65, alpha = 0.85
  ) +
  geom_text(
    aes(label = if_else(n < 1, "<1", as.character(round(n)))),
    position = position_dodge(width = 0.72),
    hjust = -0.2, size = 3.8, fontface = "bold", color = "#3A3A3A"
  ) +
  scale_fill_manual(values = c(
    "Urban / insured"                         = "#5B8DB8",
    "Outbreak epicenter\n(rural, low-income)" = "#C9392C"
  )) +
  scale_x_continuous(
    limits = c(0, 1280),
    expand = c(0, 0)
  ) +
  scale_y_discrete(labels = function(x) {
    funnel_data$step_label[match(as.integer(as.character(x)),
                                  funnel_data$step)]
  }) +
  labs(
    title    = "How Measles-Associated Hearing Loss Disappears from the Record",
    subtitle = "Per 1,000 measles cases — modeled pathway from infection to coded diagnosis, by community type",
    x        = "Cases remaining in pathway",
    y        = NULL,
    caption  = paste0(
      "Hearing loss rate: 0.85% midpoint (0.5%-1.3%), both pathways ",
      "(Cohen et al. Trends Hear 2014).\n",
      "Audiology access: Garuccio et al. JAMA Otolaryngol 2025; ",
      "Kingsbury et al. Perspect ASHA 2022; ",
      "AAO-HNSF OME guideline (Rosenfeld et al. 2016).\n",
      "Detection: Elzinga et al. BMJ Open 2021 (high-frequency SNHL masking). ",
      "Coding linkage calibrated against VA U09.9 rates ",
      "(Wander et al. JAMA Netw Open 2023)."
    )
  ) +
  theme_1950s() +
  theme(
    legend.position = "right",
    legend.title    = element_blank(),
    legend.text     = element_text(size = 11, color = "#3A3A3A"),
    panel.grid.major.y = element_blank()
  )

# ============================================================
# 5. FIGURE 2D — Audiologist access gap
# ============================================================

fig2d <- ggplot(access_data,
    aes(x = aud_per_100k, y = location, fill = bar_color)) +
  geom_col(width = 0.62, alpha = 0.87) +
  geom_vline(xintercept = 4.0, linetype = "dashed",
    color = "#5B8DB8", linewidth = 0.8) +
  annotate("text", x = 4.13, y = 5.45,
    label = "National average\n(4.0 per 100k)",
    size = 3.5, color = "#5B8DB8", fontface = "bold", hjust = 0) +
  geom_text(
    aes(label = if_else(
      aud_per_100k == 0,
      "None on record",
      paste0(aud_per_100k, " per 100k")
    )),
    hjust = -0.12, size = 3.8, fontface = "bold", color = "#3A3A3A"
  ) +
  scale_fill_identity() +
  scale_x_continuous(
    limits = c(0, 9),
    expand = c(0, 0)
  ) +
  labs(
    title    = "Audiologist Access in the 2025 Measles Outbreak Zone",
    subtitle = "The children who got sick lived farthest from the specialists who could document what happened to them",
    x        = "Audiologists per 100,000 population",
    y        = NULL,
    caption  = paste0(
      "Sources: Garuccio et al. (2025) JAMA Otolaryngol — 75% of US counties are ",
      "hearing healthcare shortage areas, disproportionately rural.\n",
      "ASHA national average 4 per 100,000. West TX and Gaines County estimates ",
      "based on NPPES provider data and rural TX county characteristics.\n",
      "Lubbock estimate from urban Texas benchmark range. ",
      "Verify Gaines County value via NPPES direct lookup before publication."
    )
  ) +
  theme_1950s() +
  theme(panel.grid.major.y = element_blank())

# ============================================================
# 6. SAVE INDIVIDUAL FIGURES
# ============================================================

# ── Output directory (change to suit your environment) ──────
output_dir <- "."
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

figures <- list(
  list(plot = fig2a, filename = file.path(output_dir, "track2_fig2a_age_distribution.png"),
       width = 10, height = 7),
  list(plot = fig2b, filename = file.path(output_dir, "track2_fig2b_geography.png"),
       width = 12, height = 7),
  list(plot = fig2c, filename = file.path(output_dir, "track2_fig2c_funnel.png"),
       width = 14, height = 8),
  list(plot = fig2d, filename = file.path(output_dir, "track2_fig2d_access.png"),
       width = 13, height = 7)
)

for (f in figures) {
  ggsave(
    f$filename,
    f$plot,
    width  = f$width,
    height = f$height,
    dpi    = 300,
    bg     = "#FAF5E9"
  )
  message("Saved: ", f$filename)
}

message("Track 2 v3 complete. Four PNGs saved to ", output_dir)
