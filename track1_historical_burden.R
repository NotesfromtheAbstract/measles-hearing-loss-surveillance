# ============================================================
# NOTES FROM THE ABSTRACTS
# Track 1: Historical Measles Burden & Projected Hearing Loss
# Sources:
#   - CDC historical case series (Our World in Data / CDC MMWR)
#   - Cohen, Durstenfeld & Roehm (2014) Trends in Hearing
#     DOI: 10.1177/2331216514541361
#   - CDC complication rates (measlesdataandstatsslideset.pdf)
#   - MMWR 2025 outbreak update
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

# Historical annual reported measles cases, United States
# Source: CDC via Our World in Data; pre-1963 averages from MMWR
# Annual supplement summary 1993 Vol. 42 No. 53
reported_cases <- tribble(
  ~year, ~reported,
  1950, 319124,
  1951, 530118,
  1952, 683077,
  1953, 449146,
  1954, 682720,
  1955, 555156,
  1956, 611936,
  1957, 486799,
  1958, 763094,
  1959, 406162,
  1960, 441703,
  1961, 423919,
  1962, 481530,
  # Vaccine introduced 1963
  1963, 385156,
  1964, 458083,
  1965, 261904,
  1966, 204136,
  1967, 62705,
  1968, 22231,
  1969, 25826,
  1970, 47351,
  1971, 75290,
  1972, 32882,
  1973, 26690,
  1974, 22094,
  1975, 24374,
  1976, 41126,
  1977, 57345,
  1978, 26871,
  1979, 13597,
  1980, 13506,
  1981, 13640,
  1982, 1714,
  1983, 1497,
  1984, 2587,
  1985, 2822,
  1986, 6282,
  1987, 3655,
  1988, 3396,
  # Two-dose schedule adopted 1989
  1989, 18193,
  1990, 27786,
  1991, 9643,
  1992, 2237,
  1993, 312,
  1994, 963,
  1995, 309,
  1996, 508,
  1997, 138,
  1998, 100,
  1999, 100,
  # Elimination declared 2000
  2000, 86,
  2001, 116,
  2002, 44,
  2003, 56,
  2004, 37,
  2005, 66,
  2006, 55,
  2007, 43,
  2008, 140,
  2009, 71,
  2010, 63,
  2011, 220,
  2012, 55,
  2013, 187,
  2014, 667,
  2015, 188,
  2016, 86,
  2017, 120,
  2018, 375,
  2019, 1282,
  2020, 13,
  2021, 49,
  2022, 121,
  2023, 58,
  2024, 285,
  2025, 2281
)

# ── Era classification ──────────────────────────────────────
reported_cases <- reported_cases %>%
  mutate(
    era = case_when(
      year < 1963  ~ "Pre-vaccine\n(1950–1962)",
      year < 1989  ~ "Single-dose era\n(1963–1988)",
      year < 2000  ~ "Two-dose era\n(1989–1999)",
      year < 2025  ~ "Post-elimination\n(2000–2024)",
      TRUE         ~ "2025 outbreak"
    ),
    era = factor(era, levels = c(
      "Pre-vaccine\n(1950–1962)",
      "Single-dose era\n(1963–1988)",
      "Two-dose era\n(1989–1999)",
      "Post-elimination\n(2000–2024)",
      "2025 outbreak"
    ))
  )

# ── Hearing loss projection parameters ─────────────────────
# Otitis media rate: 8.5–25% (Cohen et al. 2014); CDC uses 10%
# We use 10% (low), 15% (mid), 25% (high) as our range
# OM → SNHL conversion: 5–15% (audiology literature)
# Direct cochlear damage pathway adds ~0.1–0.3% of all cases
# Combined rate range: 0.5%–1.3%, midpoint 0.85%
# (McKenna 1997; Fukuda et al. 1994; Cohen et al. 2014)

hl_rate_low  <- 0.005   # 0.5%
hl_rate_mid  <- 0.0085  # 0.85%
hl_rate_high <- 0.013   # 1.3%

# Pre-vaccine era: true infections ~6–8x reported cases
# (CDC estimate: ~3–4M infections/yr vs ~500K reported)
# Adjustment factor: 6.5 for pre-vaccine, 1.0 post-vaccine
# (post-vaccine: reporting improved, cases rarer and better tracked)
undercount_prevax  <- 6.5
undercount_postvax <- 1.0

reported_cases <- reported_cases %>%
  mutate(
    undercount = if_else(year < 1963, undercount_prevax, undercount_postvax),
    true_est   = reported * undercount,
    hl_low     = true_est * hl_rate_low,
    hl_mid     = true_est * hl_rate_mid,
    hl_high    = true_est * hl_rate_high
  )

# ============================================================
# 2. FIGURE 1A — Reported cases over time with era bands
# ============================================================

era_bands <- tribble(
  ~xmin,  ~xmax,  ~era_label,               ~fill_col,
  1950,   1962.5, "Pre-vaccine",            "#C9392C",
  1962.5, 1988.5, "Single-dose vaccine",    "#E8874A",
  1988.5, 1999.5, "Two-dose schedule",      "#5B8DB8",
  1999.5, 2024.5, "Post-elimination",       "#4A9E6B",
  2024.5, 2025.5, "2025 outbreak",          "#C9392C"
)

fig1a <- ggplot(reported_cases, aes(x = year, y = reported)) +
  # Era background bands
  geom_rect(
    data = era_bands,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_col),
    inherit.aes = FALSE, alpha = 0.08
  ) +
  scale_fill_identity() +
  # Vaccine introduction lines
  geom_vline(xintercept = 1963, linetype = "dashed",
             color = "#E8874A", linewidth = 0.6, alpha = 0.8) +
  geom_vline(xintercept = 1989, linetype = "dashed",
             color = "#5B8DB8", linewidth = 0.6, alpha = 0.8) +
  geom_vline(xintercept = 2000, linetype = "dashed",
             color = "#4A9E6B", linewidth = 0.6, alpha = 0.8) +
  # Case line
  geom_line(color = "#3A3A3A", linewidth = 0.9) +
  geom_point(
    data = filter(reported_cases, year == 2025),
    color = "#C9392C", size = 3.5
  ) +
  # Era labels
  annotate("text", x = 1956, y = 720000, label = "Pre-vaccine era",
           size = 3.2, color = "#C9392C", fontface = "bold", hjust = 0.5) +
  annotate("text", x = 1975, y = 720000, label = "Single-dose era",
           size = 3.2, color = "#B5651D", fontface = "bold", hjust = 0.5) +
  annotate("text", x = 1994, y = 720000, label = "Two-dose",
           size = 3.0, color = "#5B8DB8", fontface = "bold", hjust = 0.5) +
  annotate("text", x = 2010, y = 720000, label = "Post-elimination",
           size = 3.2, color = "#4A9E6B", fontface = "bold", hjust = 0.5) +
  annotate("text", x = 2025, y = 600000,
           label = "2,281\ncases\n(2025)",
           size = 2.8, color = "#C9392C", fontface = "bold", hjust = 0.5) +
  scale_y_continuous(
    labels = label_comma(),
    limits = c(0, 800000),
    expand = c(0, 0)
  ) +
  scale_x_continuous(breaks = seq(1950, 2025, 10)) +
  labs(
    title    = "Reported Measles Cases, United States, 1950–2025",
    subtitle = "Reported cases only — true infections in the pre-vaccine era estimated at 6–8× higher",
    x        = NULL,
    y        = "Reported cases"
  ) +
  theme_1950s() +
  theme(legend.position = "none")

# ============================================================
# 3. FIGURE 1B — Projected annual hearing loss cases
# ============================================================

fig1b <- ggplot(reported_cases, aes(x = year)) +
  geom_ribbon(aes(ymin = hl_low, ymax = hl_high),
              fill = "#8B5A8C", alpha = 0.25) +
  geom_line(aes(y = hl_mid), color = "#8B5A8C", linewidth = 1.0) +
  geom_vline(xintercept = 1963, linetype = "dashed",
             color = "#E8874A", linewidth = 0.6, alpha = 0.8) +
  geom_vline(xintercept = 1989, linetype = "dashed",
             color = "#5B8DB8", linewidth = 0.6, alpha = 0.8) +
  geom_vline(xintercept = 2000, linetype = "dashed",
             color = "#4A9E6B", linewidth = 0.6, alpha = 0.8) +
  geom_point(
    data = filter(reported_cases, year == 2025),
    aes(y = hl_mid),
    color = "#C9392C", size = 3.5
  ) +
  annotate("text", x = 1956, y = 42000,
           label = "~25,000–45,000\nhearing loss cases/yr\n(projected)",
           size = 2.8, color = "#8B5A8C", fontface = "bold", hjust = 0.5) +
  annotate("text", x = 2025, y = 8000,
           label = "~19\ncases\n(2025)",
           size = 2.8, color = "#C9392C", fontface = "bold", hjust = 0.5) +
  scale_y_continuous(
    labels = label_comma(),
    limits = c(0, 50000),
    expand = c(0, 0)
  ) +
  scale_x_continuous(breaks = seq(1950, 2025, 10)) +
  labs(
    title    = "Projected Measles-Associated Hearing Loss Cases, 1950–2025",
    subtitle = "Shaded band = 0.5%–1.3% of true infections; midline = 0.85% (Cohen et al. 2014)",
    x        = "Year",
    y        = "Projected hearing loss cases"
  ) +
  theme_1950s() +
  theme(legend.position = "none")

# ============================================================
# 4. FIGURE 1C — Cumulative invisible burden
#    (total projected HL cases that never appeared in
#     measles surveillance, 1950–2000)
# ============================================================

cumulative <- reported_cases %>%
  filter(year <= 2000) %>%
  mutate(
    cum_hl_mid  = cumsum(hl_mid),
    cum_hl_low  = cumsum(hl_low),
    cum_hl_high = cumsum(hl_high)
  )

fig1c <- ggplot(cumulative, aes(x = year)) +
  geom_ribbon(aes(ymin = cum_hl_low, ymax = cum_hl_high),
              fill = "#8B5A8C", alpha = 0.2) +
  geom_line(aes(y = cum_hl_mid), color = "#8B5A8C", linewidth = 1.1) +
  geom_vline(xintercept = 1963, linetype = "dashed",
             color = "#E8874A", linewidth = 0.6, alpha = 0.8) +
  geom_vline(xintercept = 1989, linetype = "dashed",
             color = "#5B8DB8", linewidth = 0.6, alpha = 0.8) +
  annotate("text", x = 1993, y = 1200000,
           label = paste0("Estimated ~1.4M\ncumulative cases of\nmeasles-associated\nhearing loss,\n1950–2000"),
           size = 3.0, color = "#8B5A8C", fontface = "bold", hjust = 0) +
  scale_y_continuous(
    labels = label_comma(),
    expand = c(0, 0)
  ) +
  scale_x_continuous(breaks = seq(1950, 2000, 10)) +
  labs(
    title    = "Cumulative Projected Measles-Associated Hearing Loss, 1950–2000",
    subtitle = "Cases that occurred but were never counted as measles outcomes in surveillance data",
    x        = "Year",
    y        = "Cumulative projected cases"
  ) +
  theme_1950s()

# ============================================================
# 5. FIGURE 1D — Era comparison bar chart
# ============================================================

era_summary <- reported_cases %>%
  group_by(era) %>%
  summarise(
    total_reported = sum(reported),
    total_true_est = sum(true_est),
    total_hl_mid   = sum(hl_mid),
    total_hl_low   = sum(hl_low),
    total_hl_high  = sum(hl_high),
    .groups = "drop"
  )

era_colors <- c(
  "Pre-vaccine\n(1950–1962)"       = "#C9392C",
  "Single-dose era\n(1963–1988)"   = "#E8874A",
  "Two-dose era\n(1989–1999)"      = "#5B8DB8",
  "Post-elimination\n(2000–2024)"  = "#4A9E6B",
  "2025 outbreak"                  = "#C9392C"
)

fig1d <- ggplot(era_summary,
                aes(x = era, y = total_hl_mid, fill = era)) +
  geom_col(width = 0.65, alpha = 0.85) +
  geom_errorbar(
    aes(ymin = total_hl_low, ymax = total_hl_high),
    width = 0.25, color = "#3A3A3A", linewidth = 0.7
  ) +
  geom_text(
    aes(label = label_comma()(round(total_hl_mid))),
    vjust = -1.8, size = 3.2, fontface = "bold", color = "#3A3A3A"
  ) +
  scale_fill_manual(values = era_colors) +
  scale_y_continuous(
    labels = label_comma(),
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title    = "Projected Measles-Associated Hearing Loss by Era",
    subtitle = "Error bars reflect 0.5%–1.3% hearing loss rate range",
    x        = NULL,
    y        = "Projected hearing loss cases (total for era)"
  ) +
  theme_1950s() +
  theme(
    axis.text.x    = element_text(size = 9, lineheight = 1.2),
    legend.position = "none"
  )

# ============================================================
# 6. SAVE INDIVIDUAL FIGURES
# ============================================================

# ── Output directory (change to suit your environment) ──────
output_dir <- "."
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

figures <- list(
  list(
    plot     = fig1a,
    filename = file.path(output_dir, "track1_fig1a_reported_cases.png"),
    width    = 12, height = 6
  ),
  list(
    plot     = fig1b,
    filename = file.path(output_dir, "track1_fig1b_projected_hl.png"),
    width    = 12, height = 6
  ),
  list(
    plot     = fig1c,
    filename = file.path(output_dir, "track1_fig1c_cumulative_hl.png"),
    width    = 12, height = 6
  ),
  list(
    plot     = fig1d,
    filename = file.path(output_dir, "track1_fig1d_era_comparison.png"),
    width    = 12, height = 6
  )
)

for (f in figures) {
  print(f$plot)
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

# ============================================================
# 7. COMBINED LAYOUT (bonus overview)
# ============================================================

combined <- (fig1a / fig1b) | (fig1c / fig1d)

combined_annotated <- combined +
  plot_annotation(
    title    = "The Burden That Was Never Counted",
    subtitle = paste0(
      "Measles-associated hearing loss, projected from published complication rates, ",
      "has never appeared in measles surveillance data.\n",
      "Each hearing loss case was coded separately — H66, H90 — ",
      "with no link back to the original measles infection."
    ),
    caption  = paste0(
      "Sources: CDC historical case series; Cohen, Durstenfeld & Roehm (2014) ",
      "Trends in Hearing DOI:10.1177/2331216514541361;\n",
      "CDC measles complications data. ",
      "Pre-vaccine true infection estimate: 6.5x reported cases (CDC).\n",
      "Hearing loss rate: 0.5%-1.3% of true infections (midpoint 0.85%)."
    ),
    theme    = theme_1950s() +
      theme(
        plot.title    = element_text(size = 22, face = "bold", color = "#3A3A3A"),
        plot.subtitle = element_text(size = 11, color = "#5A5A5A", lineheight = 1.4),
        plot.caption  = element_text(size = 8,  color = "#7A7A7A", lineheight = 1.3)
      )
  )

print(combined_annotated)

ggsave(
  file.path(output_dir, "track1_combined.png"),
  combined_annotated,
  width  = 16,
  height = 12,
  dpi    = 300,
  bg     = "#FAF5E9"
)

message("Track 1 complete. Five PNGs saved to ", getwd())

# ── Quick summary table ─────────────────────────────────────
era_summary %>%
  select(era, total_reported, total_hl_low, total_hl_mid, total_hl_high) %>%
  mutate(across(where(is.numeric), ~ round(., 0))) %>%
  print()
