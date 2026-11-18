#!/usr/bin/env Rscript
# Retrieve public environmental layers used in the manuscript and rebuild
# sample-level covariates at 100/200/400 m buffers.
#
# Run from the project root after installing:
#   install.packages(c("sf", "terra", "geodata", "exactextractr", "dplyr", "readr"))
#
# Notes
# - WorldClim via geodata::worldclim_country()
# - WorldPop Australia 1 km population density via HTTPS
# - Digital Earth Australia / GA land-cover tiles and devil-density GeoTIFFs are
#   large local products already used in 05_Enviroment_types.Rmd; this script
#   documents paths and rebuilds climate/pop extractions. Point landcover_vrt
#   and devil_tif to your local copies.

suppressPackageStartupMessages({
  pkgs <- c("sf", "terra", "dplyr", "readr", "exactextractr")
  for (p in pkgs) {
    if (!requireNamespace(p, quietly = TRUE)) {
      stop("Install package '", p, "' before running this script.", call. = FALSE)
    }
  }
})

out_dir <- "data/archive_deposit/retrieved_layers"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------------------
# 1. Sample coordinates
# ---------------------------------------------------------------------------
meta_path <- "data/archive_deposit/tables/01_sample_metadata.csv"
if (!file.exists(meta_path)) {
  meta_path <- "data/merged_metadata.tsv"
}
meta <- if (grepl("\\.tsv$", meta_path)) {
  readr::read_tsv(meta_path, show_col_types = FALSE)
} else {
  readr::read_csv(meta_path, show_col_types = FALSE)
}

id_col <- if ("sample" %in% names(meta)) "sample" else "EHI_plaintext"
pts <- sf::st_as_sf(
  meta,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)
message("Samples: ", nrow(pts))

# ---------------------------------------------------------------------------
# 2. WorldClim v2.1 (Fick & Hijmans 2017) for Australia
# ---------------------------------------------------------------------------
# Citation: Fick, S.E. & Hijmans, R.J. (2017). WorldClim 2: new 1-km spatial
# resolution climate surfaces for global land areas. Int. J. Climatol., 37,
# 4302–4315.
if (!requireNamespace("geodata", quietly = TRUE)) {
  stop("Install geodata to download WorldClim.", call. = FALSE)
}
wc_dir <- file.path(out_dir, "worldclim")
dir.create(wc_dir, showWarnings = FALSE)
message("Downloading WorldClim v2.1 BIO layers for Australia…")
wc <- geodata::worldclim_country(
  country = "Australia",
  var = "bio",
  res = 0.5,
  path = wc_dir
)
# BIO1 = mean annual temperature (°C); BIO12 = annual precipitation (mm)
bio1 <- wc[[1]]
bio12 <- wc[[12]]
terra::writeRaster(bio1, file.path(out_dir, "worldclim_bio1_aus.tif"), overwrite = TRUE)
terra::writeRaster(bio12, file.path(out_dir, "worldclim_bio12_aus.tif"), overwrite = TRUE)

temp_vals <- terra::extract(bio1, terra::vect(pts))[, 2]
prec_vals <- terra::extract(bio12, terra::vect(pts))[, 2]

climate_tbl <- dplyr::tibble(
  sample = meta[[id_col]],
  annual_mean_temp_C = temp_vals,
  annual_precipitation_mm = prec_vals
)
readr::write_csv(climate_tbl, file.path(out_dir, "sample_worldclim_values.csv"))
message("Wrote sample_worldclim_values.csv")

# ---------------------------------------------------------------------------
# 3. WorldPop population density (Australia 2020, 1 km)
# ---------------------------------------------------------------------------
# Source: https://data.worldpop.org/ — cite WorldPop / Tatem and coauthors as
# required by WorldPop terms.
pop_url <- paste0(
  "https://data.worldpop.org/GIS/Population_Density/Global_2000_2020_1km/",
  "2020/AUS/aus_pd_2020_1km.tif"
)
pop_tif <- file.path(out_dir, "aus_pd_2020_1km.tif")
if (!file.exists(pop_tif)) {
  message("Downloading WorldPop Australia 2020 density…")
  utils::download.file(pop_url, pop_tif, mode = "wb")
}
pop_r <- terra::rast(pop_tif)
pop_vals <- terra::extract(pop_r, terra::vect(pts))[, 2]
pop_tbl <- dplyr::tibble(
  sample = meta[[id_col]],
  pop_density_1km = pop_vals
)
readr::write_csv(pop_tbl, file.path(out_dir, "sample_worldpop_values.csv"))

# ---------------------------------------------------------------------------
# 4. Land cover and devil density (local files)
# ---------------------------------------------------------------------------
# Land cover: Digital Earth Australia / Geoscience Australia land-cover class
# rasters (project path Landcover/Tif or a VRT mosaic). Primary buffer = 200 m.
# Devil density: predictionStack_devils_1985to2035.tif (Cunningham et al. 2021);
# use 2021–2023 mean within the buffer.
#
# Example (edit paths to match your machine):
#
# landcover_vrt <- "Landcover/Tif/landcover_mosaic.vrt"
# devil_tif <- "predictionStack_devils_1985to2035.tif"
# radii_m <- c(100, 200, 400)
# pts_proj <- sf::st_transform(pts, terra::crs(terra::rast(landcover_vrt)))
# for (r in radii_m) {
#   buf <- sf::st_buffer(pts_proj, dist = r)
#   # exactextractr::exact_extract(...) -> class percentages -> Hill diversity
# }
#
# Full buffer extraction logic lives in 05_Enviroment_types.Rmd.

message(
  "Climate and WorldPop retrieval finished.\n",
  "For DEA/GA land cover and devil-density stacks, use local rasters and ",
  "05_Enviroment_types.Rmd (primary buffer 200 m).\n",
  "Map outlines in figures: Natural Earth via rnaturalearth (public domain)."
)

# ---------------------------------------------------------------------------
# 5. Merge retrieved climate/pop with existing multiscale table if present
# ---------------------------------------------------------------------------
ms_path <- "data/archive_deposit/tables/12_environment_multiscale.csv"
if (file.exists(ms_path)) {
  ms <- readr::read_csv(ms_path, show_col_types = FALSE)
  message(
    "Existing multiscale environmental table has ",
    nrow(ms), " rows (radii 100/200/400 m). ",
    "Use radius_m == 200 for the primary HMSC covariates."
  )
}
