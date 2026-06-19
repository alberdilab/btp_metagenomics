# Knit-order data dependencies (see _bookdown.yml, chapters 01–15).

ensure_hill_rdata <- function(
    hill_path = "data/hill.Rdata",
    landcover_path = "landcover_wide.csv",
    build_script = ".cursor/scripts/build_hill_rdata.R") {
  if (file.exists(hill_path)) {
    return(invisible(hill_path))
  }
  if (!file.exists(landcover_path)) {
    stop(
      "Missing ", hill_path, " and ", landcover_path, ". ",
      "Knit chapter 5 (Environment types) before this chapter.",
      call. = FALSE
    )
  }
  if (!file.exists(build_script)) {
    stop("Missing build script: ", build_script, call. = FALSE)
  }
  status <- system2("Rscript", build_script)
  if (!identical(status, 0L) || !file.exists(hill_path)) {
    stop(
      "Failed to build ", hill_path, " from ", landcover_path, ".",
      call. = FALSE
    )
  }
  invisible(hill_path)
}

ensure_hmsc_env_csvs <- function(
    animal_path = "data/animal_var.csv",
    env_path = "data/environment_var_r200.csv") {
  missing <- c(animal_path, env_path)[!file.exists(c(animal_path, env_path))]
  if (length(missing) == 0L) {
    return(invisible(TRUE))
  }
  stop(
    "Missing HMSC input file(s): ", paste(missing, collapse = ", "), ". ",
    "Knit chapter 5 (Environment types) before chapter 13.",
    call. = FALSE
  )
}

ensure_gift_db <- function() {
  if (exists("GIFT_db", envir = .GlobalEnv, inherits = FALSE)) {
    return(invisible(get("GIFT_db", envir = .GlobalEnv)))
  }
  if (!requireNamespace("distillR", quietly = TRUE)) {
    stop("Package distillR is required for GIFT_db.", call. = FALSE)
  }
  suppressPackageStartupMessages(library(distillR))
  invisible(get("GIFT_db", envir = .GlobalEnv))
}
