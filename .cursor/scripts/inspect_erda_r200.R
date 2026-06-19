suppressPackageStartupMessages(library(Hmsc))
tmp <- tempfile(fileext = ".rds")
download.file(
  "https://sid.erda.dk/share_redirect/Gh0WbM42c4/Hmsc_model_r200.rds",
  tmp, mode = "wb", quiet = TRUE
)
hpc <- readRDS(tmp)
unlink(tmp)
post <- hpc$list[[1]][[1]]
cat("Beta dim:", paste(dim(post$Beta), collapse = "x"), "\n")
for (nm in names(post)) {
  obj <- post[[nm]]
  if (is.matrix(obj) || is.array(obj)) {
    cat(nm, "dim:", paste(dim(obj), collapse = "x"),
        "rn:", length(rownames(obj)), "cn:", length(colnames(obj)), "\n")
  }
}
# Try import with local model to see error
load("hmsc/model_r200")
tryCatch({
  fit <- importPosteriorFromHPC(m, hpc$list[1:4], 10, 1000, 10000)
  cat("import OK, sp:", length(fit$spNames), "\n")
}, error = function(e) cat("import error:", conditionMessage(e), "\n"))
