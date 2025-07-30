# create_gitignore.R
# This script writes a .gitignore to the project root that ignores GeoTIFFs, PNGs, and RStudio artifacts.

ignore_lines <- c(
  "# RStudio artifacts",
  ".Rproj.user",
  ".Rhistory",
  ".RData",
  ".Ruserdata",
  "",
  "# Ignore GeoTIFFs under data/",
  "data/aus",
  "data/pop1km",
  "data/**/aus_pd_2020_1km.tif",
  "",
  "# Ignore any high-res PNGs under data/",
  "data/**/*.png"
)

# Write .gitignore in the current working directory (project root)
writeLines(ignore_lines, ".gitignore")
message("Created .gitignore with RStudio artifacts, GeoTIFF and PNG ignore patterns.")