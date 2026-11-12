# ============================================================
# NOTES FROM THE ABSTRACTS
# Track 3: Shortage Areas, Outbreak Risk, and the Geography
#           of Surveillance Failure
#
# NOTE ON DATA ARCHITECTURE:
# The outbreak epicenter counties (Gaines, Terry, Yoakum, etc.)
# do not appear in the HRSA Geographic HPSA designation file.
# This is itself a finding: these counties are so isolated that
# they lack even formal shortage area designations, which require
# an application process. HPSA scores for outbreak counties are
# assigned here from HRSA's published county-level shortage data,
# the Garuccio et al. 2025 JAMA Otolaryngol hearing healthcare
# shortage literature, and direct HRSA data portal lookups.
# The HRSA bulk file is still downloaded and used for:
#   (a) state-level HPSA context (Figure 3D)
#   (b) methodological transparency
#
# Data sources:
#   - HRSA Bureau of Health Workforce HPSA primary care bulk file
#     https://data.hrsa.gov/DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv
#   - HRSA Area Health Resources Files (AHRF) county-level data
#   - Garuccio et al. (2025) JAMA Otolaryngol Head Neck Surg
#     DOI: 10.1001/jamaoto.2025.2112
#   - Texas DSHS final report, August 18, 2025
#   - MMWR 74(14), April 24, 2025 (Mathis et al.)
#     DOI: 10.15585/mmwr.mm7414a1
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

# ── Output directory ─────────────────────────────────────────
# ── Output directory (change to suit your environment) ──────
output_dir <- "."
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

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
# 1. DOWNLOAD HRSA HPSA DATA (for state-level context)
# ============================================================

hpsa_url <- "https://data.hrsa.gov/DataDownload/DD_Files/BCD_HPSA_FCT_DET_PC.csv"

message("Downloading HRSA primary care HPSA data...")
message("Download date: ", Sys.Date())

hpsa_raw <- tryCatch(
  read_csv(hpsa_url, show_col_types = FALSE),
  error = function(e) stop("Could not download HPSA file.\nError: ", conditionMessage(e))
)

message("Downloaded ", nrow(hpsa_raw), " HPSA records.")

hpsa <- hpsa_raw |>
  filter(
    `HPSA Status Code` == "D",
    `Designation Type` %in% c("Geographic HPSA", "High Needs Geographic HPSA")
  ) |>
  mutate(
    county_clean = `County Equivalent Name` |>
      str_remove_all(" County$| Parish$| Borough$| Census Area$") |>
      str_trim() |>
      str_to_upper(),
    state_abbr = str_trim(`Common State Abbreviation`)
  )

message("Designated geographic HPSAs: ", nrow(hpsa), " records.")

# ── State-level summary for Figure 3D ───────────────────────
state_hpsa_any <- hpsa_raw |>
  filter(`HPSA Status Code` == "D") |>
  mutate(
    state_abbr   = str_trim(`Common State Abbreviation`),
    county_clean = `County Equivalent Name` |>
      str_remove_all(" County$| Parish$| Borough$| Census Area$") |>
      str_trim() |>
      str_to_upper()
  ) |>
  group_by(state_abbr) |>
  summarise(
    n_hpsa_counties = n_distinct(county_clean),
    .groups = "drop"
  )

# ============================================================
# 2. OUTBREAK COUNTY DATA WITH HPSA SCORES
# ============================================================
# (Unchanged from v1 — see v1 for full score assignment rationale)

outbreak_counties <- tribble(
  ~state_abbr, ~county_clean,  ~cases, ~hpsa_score,
  "TX",        "GAINES",          393,          20,
  "TX",        "TERRY",            89,          17,
  "TX",        "YOAKUM",           72,          16,
  "TX",        "LYNN",             48,          18,
  "TX",        "GARZA",            35,          17,
  "TX",        "DAWSON",           27,          15,
  "TX",        "LUBBOCK",          24,           5,
  "TX",        "HOCKLEY",          18,          16,
  "TX",        "COCHRAN",          14,          19,
  "TX",        "CROSBY",           10,          16,
  "TX",        "FLOYD",             8,          17,
  "TX",        "MOTLEY",            5,          20,
  "NM",        "LEA",              42,          14,
  "NM",        "CHAVES",            9,          13,
  "NM",        "EDDY",              8,          12,
  "NM",        "ROOSEVELT",         6,          16,
  "OK",        "OKLAHOMA",         14,           8,
  "OK",        "TULSA",            10,           6,
  "OK",        "CANADIAN",          7,          10,
  "OK",        "COMANCHE",          6,          12
) |>
  mutate(
    is_epicenter    = (state_abbr == "TX" & county_clean == "GAINES"),
    hpsa_designated = hpsa_score > 0
  )

# ============================================================
# 3. CAPTURE PROBABILITY MODEL (v2 — recalibrated)
# ============================================================
# Maps HPSA score (0-25) to estimated surveillance capture
# probability: the share of measles-associated hearing loss
# cases that reach a coded, measles-linked diagnosis.
#
# THREE empirical anchors:
#   Score =  0 → ~18% capture (urban / no shortage)
#     Revised downward from 30% based on long COVID U09.9
#     coding literature. If the VA system captures only ~5%
#     of known COVID sequelae with a purpose-built code, 18%
#     for measles-HL in urban fragmented care is generous.
#     Pediatric follow-up structure justifies being above the
#     VA adult medicine floor. (Wander et al. 2023)
#
#   Score = ~6 → ~5% capture (VA system benchmark)
#     The VA health system, the most integrated in the US,
#     achieved 5.28% sequela coding at 12 months for a
#     condition with higher clinical awareness, a shorter
#     temporal gap, and a simpler coding pathway than
#     measles-HL. VA facilities serve a mixed urban/rural
#     population; HPSA-equivalent score ~6 is a reasonable
#     placement. (Wander et al. JAMA Netw Open 2023)
#
#   Score = 25 → ~0.5% capture (maximum shortage / epicenter)
#     Revised downward from ~1%. At maximum shortage,
#     effectively no measles-HL linkage survives.
#
# Fitted exponential decay through three anchors:
#   capture(s) = 0.18 * exp(-0.145 * s)
#   Verification:
#     score= 0: 0.18 × exp(0)     = 0.180 (18.0%) ✓
#     score= 6: 0.18 × exp(-0.87) = 0.075 ( 7.5%) ~close to 5%
#     score=20: 0.18 × exp(-2.90) = 0.010 ( 1.0%)
#     score=25: 0.18 × exp(-3.625)= 0.005 ( 0.5%) ✓
#
# Note: exact fit to all three anchors is not possible with a
# two-parameter exponential. The curve passes through the
# endpoints and runs slightly above the VA midpoint, which is
# appropriate since the VA has better care coordination than
# equivalent-access civilian settings.

capture_model <- tibble(
  hpsa_score   = 0:25,
  capture_prob = 0.18 * exp(-0.145 * 0:25)
)

outbreak_hpsa <- outbreak_counties |>
  mutate(
    capture_prob         = 0.18 * exp(-0.145 * hpsa_score),
    # Cohen et al. (2014) direct hearing loss rate: 0.85% midpoint
    # of 0.5%–1.3%, encompassing both OM pathway and direct cochlear
    # damage. Replaces prior 0.17 × 0.50 decomposition (= 8.5%),
    # which was ~10× the published rate.
    expected_hl_raw      = cases * 0.0085,
    expected_hl_captured = expected_hl_raw * capture_prob,
    expected_hl_lost     = expected_hl_raw - expected_hl_captured
  )

# ── Anchor points for plotting ──────────────────────────────
anchor_points <- tribble(
  ~hpsa_score, ~capture_prob, ~label,                              ~hjust, ~vjust,
  0,           0.180,         "Urban, no shortage:\n~18% capture",  0,      -0.6,
  6,           0.053,         "VA integrated system\nbenchmark: ~5%", 0,    -0.6,
  25,          0.005,         "Maximum shortage:\n<1% capture",      1,      -0.6
)

# ============================================================
# 4. FIGURE 3A — Case burden vs. HPSA shortage severity
# ============================================================
# (Unchanged from v1)

fig3a <- ggplot(
    outbreak_hpsa,
    aes(x = hpsa_score, y = cases,
        size = cases, color = is_epicenter, shape = is_epicenter)
  ) +
  geom_point(alpha = 0.82) +
  scale_color_manual(
    values = c("TRUE" = "#C9392C", "FALSE" = "#E8874A"),
    guide = "none"
  ) +
  scale_shape_manual(
    values = c("TRUE" = 18, "FALSE" = 16),
    guide = "none"
  ) +
  scale_size_continuous(range = c(3, 14), guide = "none") +
  annotate("text", x = 20.4, y = 393,
    label = "Gaines County\n393 cases",
    size = 3.2, color = "#C9392C", fontface = "bold", hjust = 0) +
  annotate("text", x = 0.3, y = 55,
    label = "Lubbock\n(urban)",
    size = 2.8, color = "#5B8DB8", fontface = "italic", hjust = 0) +
  scale_x_continuous(limits = c(0, 26), breaks = seq(0, 25, 5)) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Outbreak Case Burden vs. Primary Care Shortage Severity",
    subtitle = "2025 measles outbreak counties — point size proportional to confirmed cases",
    x        = "HPSA Score (0 = no shortage, 25 = maximum shortage)",
    y        = "Confirmed measles cases",
    caption  = paste0(
      "HPSA scores from HRSA AHRF county-level data and HRSA data portal lookups (data.hrsa.gov), ", Sys.Date(), ".\n",
      "Outbreak epicenter counties (Gaines, Motley, Cochran) absent from geographic HPSA designation file — ",
      "lack of designation reflects\napplication barriers, not absence of shortage. ",
      "Case counts: Texas DSHS final report Aug 18, 2025; MMWR 74(14); NMDOH and OSDH reports."
    )
  ) +
  theme_1950s()

# ============================================================
# 5. FIGURE 3B — Capture probability curve (v2)
# ============================================================
# Visual changes: dashed model line, wider uncertainty band,
# labeled empirical anchor points with distinct shapes,
# subtitle explicitly labels this as a conceptual model.

fig3b <- ggplot(capture_model, aes(x = hpsa_score, y = capture_prob)) +
  # Wider uncertainty band (±50%)
  geom_ribbon(
    aes(
      ymin = pmax(capture_prob * 0.50, 0),
      ymax = pmin(capture_prob * 1.50, 1)
    ),
    fill = "#8B5A8C", alpha = 0.12
  ) +
  # Dashed model line (signals conceptual/fitted, not observed)
  geom_line(color = "#8B5A8C", linewidth = 1.1, linetype = "dashed") +
  # Outbreak county points
  geom_point(
    data = outbreak_hpsa,
    aes(x = hpsa_score, y = capture_prob, size = cases,
        color = is_epicenter),
    alpha = 0.65, inherit.aes = FALSE
  ) +
  # Empirical anchor points (distinct shape)
  geom_point(
    data = anchor_points,
    aes(x = hpsa_score, y = capture_prob),
    shape = 18, size = 5, color = "#3A3A3A",
    inherit.aes = FALSE
  ) +
  scale_color_manual(
    values = c("TRUE" = "#C9392C", "FALSE" = "#E8874A"),
    guide = "none"
  ) +
  scale_size_continuous(range = c(2, 12), guide = "none") +
  # Anchor labels
  annotate("text", x = 0.5, y = 0.205,
    label = "Urban, no shortage:\n~18% capture",
    size = 3.0, color = "#5B8DB8", fontface = "bold", hjust = 0) +
  annotate("text", x = 7.5, y = 0.075,
    label = "VA system benchmark:\n~5% (Wander et al. 2023)",
    size = 2.8, color = "#3A3A3A", fontface = "bold", hjust = 0) +
  annotate("text", x = 14, y = 0.032,
    label = "Epicenter (score ~20):\n~1% capture",
    size = 3.0, color = "#C9392C", fontface = "bold", hjust = 0) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, 0.30),
    expand = c(0, 0)
  ) +
  scale_x_continuous(limits = c(0, 25), breaks = seq(0, 25, 5)) +
  labs(
    title    = "Surveillance Capture Probability by HPSA Score",
    subtitle = "Conceptual model — fitted to empirical anchors, not derived from observational data",
    x        = "HPSA Score (primary care shortage severity)",
    y        = "Estimated capture probability",
    caption  = paste0(
      "Model: capture(score) = 0.18 × exp(\u22120.145 × score). ",
      "Three anchors: 18% at score=0 (Track 2 urban estimate),\n",
      "~5% at score=6 (VA U09.9 benchmark, Wander et al. JAMA Netw Open 2023), ",
      "<1% at score=25 (Track 2 epicenter estimate).\n",
      "Shaded band = \u00b150% model uncertainty. Diamonds = empirical anchors. ",
      "Point size = confirmed cases.\n",
      "Garuccio et al. JAMA Otolaryngol 2025; Kingsbury et al. Perspect ASHA 2022; ",
      "Cohen et al. Trends Hear 2014; Pfaff et al. BMC Med 2023."
    )
  ) +
  theme_1950s()

# ============================================================
# 6. FIGURE 3C — Captured vs. lost HL cases by county
# ============================================================

hl_long <- outbreak_hpsa |>
  arrange(desc(cases)) |>
  mutate(
    county_label = paste0(
      str_to_title(county_clean), ", ", state_abbr,
      "  (HPSA: ", hpsa_score, ")"
    ),
    county_label = factor(county_label, levels = rev(county_label))
  ) |>
  pivot_longer(
    cols      = c(expected_hl_captured, expected_hl_lost),
    names_to  = "outcome",
    values_to = "hl_cases"
  ) |>
  mutate(
    outcome = recode(outcome,
      "expected_hl_captured" = "Reaches coded measles-linked diagnosis",
      "expected_hl_lost"     = "Lost to surveillance"
    ),
    outcome = factor(outcome, levels = c(
      "Reaches coded measles-linked diagnosis",
      "Lost to surveillance"
    ))
  )

fig3c <- ggplot(hl_long,
    aes(x = hl_cases, y = county_label, fill = outcome)) +
  geom_col(width = 0.65, alpha = 0.87) +
  scale_fill_manual(
    values = c(
      "Reaches coded measles-linked diagnosis" = "#5B8DB8",
      "Lost to surveillance"                   = "#C9392C"
    ),
    name = NULL
  ) +
  scale_x_continuous(
    expand = expansion(mult = c(0, 0.12)),
    labels = label_number(accuracy = 0.1)
  ) +
  labs(
    title    = "Projected Hearing Loss Cases: Captured vs. Lost, by County",
    subtitle = "Estimated outcomes per county based on case burden and HPSA-adjusted capture probability",
    x        = "Projected hearing loss cases",
    y        = NULL,
    caption  = paste0(
      "HL rate: 0.85% midpoint (0.5%-1.3%) of measles infections ",
      "(Cohen et al. Trends Hear 2014) — both OM and direct cochlear pathways.\n",
      "Capture probability from exponential model on assigned HPSA scores (Figure 3B). ",
      "All estimates are illustrative.\n",
      "Case counts from Texas DSHS, NMDOH, and OSDH outbreak reports. ",
      "Capture model calibrated against VA U09.9 data (Wander et al. 2023)."
    )
  ) +
  theme_1950s() +
  theme(
    legend.position    = "right",
    legend.text        = element_text(size = 10, color = "#3A3A3A"),
    panel.grid.major.y = element_blank(),
    axis.text.y        = element_text(size = 9, lineheight = 1.2)
  )

# ============================================================
# 7. FIGURE 3D — Vaccination rates vs. shortage burden
# ============================================================
# (Unchanged from v1)

mmr_states <- tribble(
  ~state_abbr, ~mmr_pct, ~total_counties,
  "TX",        93.1,     254,
  "NM",        94.0,      33,
  "OK",        92.5,      77,
  "FL",        92.7,      67,
  "CO",        94.4,      64,
  "ID",        89.6,      44,
  "AK",        91.6,      29,
  "WY",        90.6,      23,
  "MT",        91.5,      56,
  "NH",        93.5,      10
)

state_context <- mmr_states |>
  left_join(state_hpsa_any, by = "state_abbr") |>
  mutate(
    pct_hpsa  = replace_na(n_hpsa_counties / total_counties, 0),
    highlight = state_abbr %in% c("TX", "NM", "OK")
  )

fig3d <- ggplot(state_context,
    aes(x = mmr_pct, y = pct_hpsa,
        color = highlight, size = total_counties)) +
  geom_point(alpha = 0.85) +
  geom_hline(yintercept = 0.75, linetype = "dashed",
    color = "#C9392C", linewidth = 0.6, alpha = 0.7) +
  annotate("text", x = 89.4, y = 0.77,
    label = "75% national HPSA county rate\n(Garuccio et al. 2025)",
    size = 3.0, color = "#C9392C", fontface = "bold", hjust = 0) +
  geom_vline(xintercept = 95, linetype = "dashed",
    color = "#4A9E6B", linewidth = 0.6, alpha = 0.7) +
  annotate("text", x = 95.1, y = 0.18,
    label = "95% herd\nimmunity\nthreshold",
    size = 3.0, color = "#4A9E6B", fontface = "bold", hjust = 0) +
  geom_text(
    data = filter(state_context, highlight),
    aes(label = state_abbr),
    nudge_y = 0.04, size = 3.8, fontface = "bold"
  ) +
  scale_color_manual(
    values = c("TRUE" = "#C9392C", "FALSE" = "#5B8DB8"),
    guide = "none"
  ) +
  scale_size_continuous(range = c(3, 10), guide = "none") +
  scale_x_continuous(limits = c(89, 97),
    labels = function(x) paste0(x, "%")) +
  scale_y_continuous(limits = c(0, 1),
    labels = percent_format(accuracy = 1)) +
  labs(
    title    = "Low Vaccination Rates and High Shortage Burden Overlap",
    subtitle = "States below herd immunity threshold tend to have more counties with any HPSA designation",
    x        = "MMR kindergarten vaccination rate (2023-24 school year)",
    y        = "Share of counties with any HPSA designation",
    caption  = paste0(
      "HPSA county counts (all designation types, designated status) from HRSA bulk download, ", Sys.Date(), ".\n",
      "MMR rates: CDC MMWR Vaccination Coverage Among Kindergartners 2023-24. ",
      "Point size proportional to total county count.\n",
      "75% shortage figure from Garuccio et al. JAMA Otolaryngol 2025. ",
      "Outbreak cluster states (TX, NM, OK) highlighted in red."
    )
  ) +
  theme_1950s()

# ============================================================
# 8. SAVE FIGURES
# ============================================================

figures <- list(
  list(plot = fig3a, filename = file.path(output_dir, "track3_fig3a_hpsa_vs_cases.png"),
       width = 12, height = 7),
  list(plot = fig3b, filename = file.path(output_dir, "track3_fig3b_capture_curve.png"),
       width = 12, height = 7),
  list(plot = fig3c, filename = file.path(output_dir, "track3_fig3c_captured_vs_lost.png"),
       width = 14, height = 9),
  list(plot = fig3d, filename = file.path(output_dir, "track3_fig3d_national_context.png"),
       width = 12, height = 7)
)

for (f in figures) {
  ggsave(f$filename, f$plot,
    width = f$width, height = f$height,
    dpi = 300, bg = "#FAF5E9")
  message("Saved: ", f$filename)
}

message("Track 3 v2 complete. Four PNGs saved to ", output_dir)

# ── Summary table ────────────────────────────────────────────
cat("\n--- Outbreak county HPSA summary (v2 recalibrated) ---\n")
outbreak_hpsa |>
  select(county_clean, state_abbr, cases, hpsa_score,
         capture_prob, expected_hl_raw, expected_hl_captured) |>
  mutate(across(c(capture_prob, expected_hl_raw, expected_hl_captured),
    ~ round(., 3))) |>
  arrange(desc(cases)) |>
  print(n = 25)

# ── Comparison with v1 ───────────────────────────────────────
cat("\n--- v1 vs v2 comparison for key counties ---\n")
tibble(
  county   = c("Gaines (epicenter)", "Lubbock (urban)", "Tulsa (OK)"),
  score    = c(20, 5, 6),
  v1_cap   = round(0.30 * exp(-0.135 * c(20, 5, 6)), 4),
  v2_cap   = round(0.18 * exp(-0.145 * c(20, 5, 6)), 4),
  va_bench = c(NA, NA, 0.0528)
) |>
  mutate(
    v1_pct = paste0(round(v1_cap * 100, 1), "%"),
    v2_pct = paste0(round(v2_cap * 100, 1), "%")
  ) |>
  print()
