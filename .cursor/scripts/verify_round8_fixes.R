# Verify round-8 critical/high bug fixes.
# Usage: Rscript .cursor/scripts/verify_round8_fixes.R

stopifnot <- function(...) {
  ok <- ...
  if (!ok) stop("Verification failed", call. = FALSE)
}

check <- function(label, ok) {
  status <- if (isTRUE(ok)) "PASS" else "FAIL"
  cat(sprintf("[%s] %s\n", status, label))
  invisible(isTRUE(ok))
}

all_ok <- TRUE
fail <- function(ok) { all_ok <<- all_ok && isTRUE(ok); ok }

# R7-001: ch07 ggplot chain (beta diversity)
ch07_txt <- readLines("07_Functional_diffrences.Rmd")
gp_line <- which(grepl("geom_point\\(size = point_size", ch07_txt))[1]
after_gp <- paste(ch07_txt[gp_line:min(gp_line + 5, length(ch07_txt))], collapse = "\n")
fail(check(
  "R7-001 ch07 ggplot chain",
  grepl("env_nmds_labels <-", paste(ch07_txt, collapse = "\n"), fixed = TRUE) &&
    grepl("scale_color_manual", after_gp, fixed = TRUE) &&
    !grepl("env_nmds_labels <-", after_gp, fixed = TRUE)
))

# HMSC-001: model_tasmania rebuilt
e <- new.env()
load("hmsc/model_tasmania", envir = e)
m <- get("m", e)
fail(check(
  "HMSC-001 model_tasmania scope",
  nrow(m$XData) == 55 &&
    ncol(m$Y) == 901 &&
    tools::md5sum("hmsc/model_tasmania") != tools::md5sum("hmsc/model_r400")
))

# R7-002: ch06 functional alpha alignment
fail(check(
  "R7-002 ch06 row order before hilldiv",
  grepl(
    "arrange\\(match\\(genome, rownames\\(dist\\)\\)\\)",
    paste(readLines("06_alpha_diversity.Rmd"), collapse = "\n"),
    perl = TRUE
  )
))
fail(check(
  "R7-002 plot_helpers matches ch06 functional alpha",
  grepl(
    "arrange\\(match\\(genome, rownames\\(dist\\)\\)\\)",
    paste(readLines("R/plot_helpers.R"), collapse = "\n"),
    perl = TRUE
  ) &&
    grepl(
      "filter\\(!is\\.nan\\(functional\\), !is\\.na\\(functional\\)\\)",
      paste(readLines("R/plot_helpers.R"), collapse = "\n"),
      perl = TRUE
    ) &&
    !grepl(
      "if_else\\(is\\.nan\\(functional\\), 1, functional\\)",
      paste(readLines("R/plot_helpers.R"), collapse = "\n"),
      perl = TRUE
    )
))

# BUG-038: ch05 hill_long schema preserved
ch05_lines <- readLines("05_Enviroment_types.Rmd")
fail(check(
  "BUG-038 ch05 hill_long_viz separation",
  sum(grepl("hill_long_viz", ch05_lines, fixed = TRUE)) >= 5 &&
    !any(grepl("ggplot\\(hill_long,", ch05_lines, perl = TRUE))
))

# R7-028: hill.Rdata available
if (!file.exists("data/hill.Rdata")) {
  system("Rscript .cursor/scripts/build_hill_rdata.R")
}
if (file.exists("data/hill.Rdata")) {
  load("data/hill.Rdata")
  fail(check("R7-028 hill.Rdata schema", all(c("id", "q", "value") %in% names(hill_long))))
} else {
  fail(check("R7-028 hill.Rdata exists", FALSE))
}

# BUG-011 / BUG-024
ch08_txt <- paste(readLines("08_microbiota_abundance_analysis_sex.Rmd"), collapse = "\n")
fail(check(
  "BUG-011 ch08 ANCOM struct12 phyloseq",
  grepl("ancom_rand_struct12[\\s\\S]*data = physeq_genome_filtered", ch08_txt, perl = TRUE)
))
fail(check(
  "BUG-024 F5 congruence prop scaling",
  grepl('value_var = "prop"', paste(readLines("15_publication_figures.Rmd"), collapse = "\n"), fixed = TRUE)
))

if (!all_ok) {
  stop("One or more verification checks failed.", call. = FALSE)
}
cat("All round-8 fix checks passed.\n")
