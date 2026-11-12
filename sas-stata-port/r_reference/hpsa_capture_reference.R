# Outbreak-county HPSA capture summary.
# Reproduces the rounded table printed by track3_hpsa_capture.R
# from data/outbreak_counties.csv.
#
#   capture_prob         = 0.18 * exp(-0.145 * hpsa_score)
#   expected_hl_raw      = cases * 0.0085
#   expected_hl_captured = expected_hl_raw * capture_prob
#
# Values are rounded to 3 decimals with base::round, the same call
# the original script uses. The file r_output.txt is the comparison
# text for the SAS log and the Stata log.
#
# Run from any directory:
#   Rscript sas-stata-port/r_reference/hpsa_capture_reference.R

script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) != 1) {
    stop("Run this file with Rscript so the output path can be resolved.")
  }
  dirname(normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE))
}

# Integer thousandths from the R 4.3 fround rule: pick the nearer
# thousandth, and on an exact tie keep the even thousandth.
# SAS and Stata use this same rule. It is checked against base::round
# on these rows before the table is written.
r_round_thousandths <- function(x) {
  pow10 <- 1000
  x10 <- x * pow10
  i10 <- floor(x10)
  xd <- i10 / pow10
  xu <- ceiling(x10) / pow10
  du <- xu - x
  dd <- x - xd
  take_up <- (du < dd) | ((i10 %% 2) == 1 & (du == dd))
  ifelse(take_up, ceiling(x10), i10)
}

format_thousandths <- function(thou, width) {
  piece <- sprintf("%d.%03d", thou %/% 1000, thou %% 1000)
  sprintf(paste0("%", width, "s"), piece)
}

here <- script_dir()
csv_path <- file.path(here, "..", "data", "outbreak_counties.csv")
out_path <- file.path(here, "r_output.txt")

counties <- read.csv(csv_path, stringsAsFactors = FALSE)
needed <- c("state_abbr", "county_clean", "cases", "hpsa_score")
missing <- setdiff(needed, names(counties))
if (length(missing) > 0) {
  stop("CSV is missing columns: ", paste(missing, collapse = ", "))
}
if (nrow(counties) != 20) {
  stop("Expected 20 counties, found ", nrow(counties), ".")
}

# Same order as arrange(desc(cases)) on the original table:
# tied case counts keep the CSV order.
counties <- counties[order(-counties$cases, seq_len(nrow(counties))), ]
counties$capture_prob <- 0.18 * exp(-0.145 * counties$hpsa_score)
counties$expected_hl_raw <- counties$cases * 0.0085
counties$expected_hl_captured <- counties$expected_hl_raw * counties$capture_prob

rounded <- list(
  capture_prob = round(counties$capture_prob, 3),
  expected_hl_raw = round(counties$expected_hl_raw, 3),
  expected_hl_captured = round(counties$expected_hl_captured, 3)
)
for (nm in names(rounded)) {
  from_rule <- format_thousandths(r_round_thousandths(counties[[nm]]), 1)
  from_round <- sprintf("%.3f", rounded[[nm]])
  if (!identical(from_rule, from_round)) {
    stop("R round and the shared thousandths rule disagree for ", nm, ".")
  }
}

header <- sprintf(
  "%-10s %-5s %5s %10s %12s %15s %20s",
  "county", "state", "cases", "hpsa_score",
  "capture_prob", "expected_hl_raw", "expected_hl_captured"
)
rows <- sprintf(
  "%-10s %-5s %5d %10d %12.3f %15.3f %20.3f",
  counties$county_clean,
  counties$state_abbr,
  counties$cases,
  counties$hpsa_score,
  rounded$capture_prob,
  rounded$expected_hl_raw,
  rounded$expected_hl_captured
)

gaines_line <- "GAINES     TX      393         20        0.010           3.340                0.033"
if (!identical(rows[1], gaines_line)) {
  stop("Gaines row changed:\n", rows[1])
}
if (length(unique(nchar(c(header, rows)))) != 1) {
  stop("Table rows are not a single fixed width.")
}

lines <- c(
  "BEGIN_HPSA_CAPTURE_TABLE",
  "Outbreak county HPSA summary (v2 recalibrated)",
  header,
  rows,
  "END_HPSA_CAPTURE_TABLE"
)
writeLines(lines, out_path, useBytes = TRUE)
message("Wrote ", normalizePath(out_path))
cat(paste(lines, collapse = "\n"), "\n", sep = "")
