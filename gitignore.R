# create_gitignore.R
# This script writes a .gitignore to the project root that ignores GeoTIFFs, PNGs, and RStudio artifacts.

ignore_lines <- c(
  "# RStudio artifacts",
  ".Rproj.user",
  ".Rhistory",
  ".RData",
  ".Ruserdata",
  "",
  "# Ignore any GeoTIFFs under data/",
  "data/**/*.tif",
  "",
  "# Ignore any high-res PNGs under data/",
  "data/**/*.png"
)

# Write .gitignore in the current working directory (project root)
writeLines(ignore_lines, ".gitignore")
message("Created .gitignore with RStudio artifacts, GeoTIFF and PNG ignore patterns.")