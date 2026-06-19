# PROJ database path for sf/terra/GDAL (required on macOS CRAN R)
local({
  if (nzchar(Sys.getenv("PROJ_LIB"))) return()
  sf_pkg <- tryCatch(find.package("sf", quiet = TRUE), error = function(e) character())
  if (!length(sf_pkg)) return()
  proj_lib <- file.path(sf_pkg, "proj")
  if (file.exists(file.path(proj_lib, "proj.db"))) {
    Sys.setenv(PROJ_LIB = proj_lib)
  }
})
