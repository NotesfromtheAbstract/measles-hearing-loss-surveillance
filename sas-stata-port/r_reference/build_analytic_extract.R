# Write the outbreak-county extract that the capture table reads.
# The rows are the outbreak_counties table in track3_hpsa_capture.R:
# confirmed cases and the HPSA scores assigned in that script.
# Run from any directory:
#   Rscript sas-stata-port/r_reference/build_analytic_extract.R

script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) != 1) {
    stop("Run this file with Rscript so the source path can be resolved.")
  }
  dirname(normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE))
}

here <- script_dir()
source_path <- normalizePath(
  file.path(here, "..", "..", "track3_hpsa_capture.R"),
  mustWork = TRUE
)
out_path <- file.path(here, "..", "data", "outbreak_counties.csv")

src <- readLines(source_path, warn = FALSE)
start <- grep("^outbreak_counties <- tribble\\(", src)
if (length(start) != 1) {
  stop("Could not find the outbreak_counties table in ", source_path)
}
end_candidates <- which(grepl("^\\) \\|>", src) & seq_along(src) > start)
if (length(end_candidates) < 1) {
  stop("Could not find the end of the outbreak_counties table.")
}
block <- src[(start + 1):(end_candidates[1] - 1)]
block <- block[!grepl("^\\s*~", block)]
block <- block[nzchar(trimws(block))]

pat <- '^\\s*"([A-Z]{2})"\\s*,\\s*"([A-Z]+)"\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,?\\s*$'
matched <- grepl(pat, block)
if (!all(matched)) {
  stop(
    "Unparsed outbreak county row:\n",
    paste(block[!matched], collapse = "\n")
  )
}

extract <- data.frame(
  state_abbr = sub(pat, "\\1", block),
  county_clean = sub(pat, "\\2", block),
  cases = as.integer(sub(pat, "\\3", block)),
  hpsa_score = as.integer(sub(pat, "\\4", block)),
  stringsAsFactors = FALSE
)

if (nrow(extract) != 20) {
  stop("Expected 20 outbreak counties, parsed ", nrow(extract), ".")
}
gaines <- extract$state_abbr == "TX" & extract$county_clean == "GAINES"
if (sum(gaines) != 1 || extract$cases[gaines] != 393 || extract$hpsa_score[gaines] != 20) {
  stop("Gaines County row is not the 393 cases / HPSA 20 row from the R script.")
}

dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write.table(
  extract,
  out_path,
  sep = ",",
  row.names = FALSE,
  quote = FALSE,
  eol = "\n"
)

message("Wrote ", normalizePath(out_path), " (", nrow(extract), " counties).")
