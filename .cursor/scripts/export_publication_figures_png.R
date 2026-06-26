#!/usr/bin/env Rscript
# Rasterise all publication figure PDFs in figures/ to PNG at publication DPI.

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop(
    "Package 'pdftools' is required. Install with install.packages('pdftools').",
    call. = FALSE
  )
}

source("R/plot_helpers.R")

fig_dir <- "figures"
dpi <- publication_figure_defaults()$dpi

pdf_files <- sort(list.files(
  fig_dir,
  pattern = "^fig_.*\\.pdf$",
  full.names = TRUE
))

if (length(pdf_files) == 0) {
  stop("No fig_*.pdf files found in ", fig_dir, call. = FALSE)
}

for (pdf_path in pdf_files) {
  png_path <- sub("\\.pdf$", ".png", pdf_path)
  pdftools::pdf_convert(
    pdf = pdf_path,
    format = "png",
    pages = 1,
    dpi = dpi,
    filenames = png_path
  )
  cat("Wrote ", basename(png_path), " (", dpi, " dpi)\n", sep = "")
}

cat("Exported ", length(pdf_files), " PNGs to ", fig_dir, "/ at ", dpi, " dpi\n", sep = "")
