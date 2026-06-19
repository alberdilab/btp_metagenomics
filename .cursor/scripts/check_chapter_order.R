# Verify _bookdown.yml chapter order satisfies data dependencies.
# Usage: Rscript .cursor/scripts/check_chapter_order.R

cfg <- yaml::read_yaml("_bookdown.yml")
chapters <- cfg$rmd_files
idx <- function(file) match(file, chapters)

deps <- list(
  "05_Enviroment_types.Rmd" = c("01_prepare_data.Rmd"),
  "07_Functional_diffrences.Rmd" = c(
    "01_prepare_data.Rmd",
    "05_Enviroment_types.Rmd"
  ),
  "10_enviromental_permanova.Rmd" = c(
    "05_Enviroment_types.Rmd",
    "07_Functional_diffrences.Rmd"
  ),
  "11_enviromental_abundance_analyses.Rmd" = c("05_Enviroment_types.Rmd"),
  "12_diversity_abundance_analysis.Rmd" = c("05_Enviroment_types.Rmd"),
  "13_hmsc_setup_final.Rmd" = c("05_Enviroment_types.Rmd"),
  "14_hmsc_analysis_final.Rmd" = c(
    "01_prepare_data.Rmd",
    "13_hmsc_setup_final.Rmd"
  ),
  "15_publication_figures.Rmd" = c(
    "05_Enviroment_types.Rmd",
    "07_Functional_diffrences.Rmd",
    "13_hmsc_setup_final.Rmd",
    "14_hmsc_analysis_final.Rmd"
  )
)

all_ok <- TRUE
for (chapter in names(deps)) {
  ch_idx <- idx(chapter)
  for (prereq in deps[[chapter]]) {
    pre_idx <- idx(prereq)
    ok <- !is.na(ch_idx) && !is.na(pre_idx) && pre_idx < ch_idx
    status <- if (ok) "PASS" else "FAIL"
    cat(sprintf("[%s] %s requires %s (idx %s < %s)\n", status, chapter, prereq, pre_idx, ch_idx))
    all_ok <- all_ok && ok
  }
}

# Sequential numbering: active chapters 01–15 match bookdown order (excluding index)
numbered <- grep("^[0-9]{2}_", chapters, value = TRUE)
expected_nums <- sprintf("%02d", seq_along(numbered))
actual_nums <- sub("_.*", "", numbered)
h_seq <- identical(actual_nums, expected_nums)
cat(sprintf("[%s] chapter files numbered 01–%02d in bookdown order\n",
            if (h_seq) "PASS" else "FAIL", length(numbered)))
all_ok <- all_ok && h_seq

h_env_alpha <- idx("05_Enviroment_types.Rmd") < idx("06_alpha_diversity.Rmd")
cat(sprintf("[%s] ch05 (environment) before ch06 (alpha diversity)\n", if (h_env_alpha) "PASS" else "FAIL"))
all_ok <- all_ok && h_env_alpha

ch05_txt <- paste(readLines("05_Enviroment_types.Rmd"), collapse = "\n")
h_no_cache <- !grepl("save_publication_base_cache_from_disk", ch05_txt, fixed = TRUE)
cat(sprintf("[%s] ch05 has no premature publication_base cache save\n", if (h_no_cache) "PASS" else "FAIL"))
all_ok <- all_ok && h_no_cache

h_helper <- file.exists("R/chapter_deps.R") &&
  any(grepl("ensure_hill_rdata", readLines("R/chapter_deps.R"), fixed = TRUE))
cat(sprintf("[%s] R/chapter_deps.R defines ensure_hill_rdata()\n", if (h_helper) "PASS" else "FAIL"))
all_ok <- all_ok && h_helper

if (!all_ok) {
  stop("Chapter order check failed.", call. = FALSE)
}

cat("\nAll chapter-order dependency checks passed.\n")
