# Build data/hill.Rdata from landcover_wide.csv (ch05 export).
# Schema: hill_long with columns (id, q, value) for chapters 10–12.
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
})

lc_path <- "landcover_wide.csv"
if (!file.exists(lc_path)) {
  stop("Missing ", lc_path, ". Knit chapter 5 or place landcover_wide.csv in project root.", call. = FALSE)
}

landcover_wide <- read_csv(lc_path, show_col_types = FALSE)
numeric_cols <- setdiff(
  names(landcover_wide)[vapply(landcover_wide, is.numeric, logical(1))],
  "EnvGradient_PC1"
)

prop_matrix <- landcover_wide %>%
  dplyr::select(dplyr::all_of(numeric_cols)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ . / 100)) %>%
  as.matrix()
prop_matrix[is.na(prop_matrix)] <- 0

h0 <- rowSums(prop_matrix > 0)
H <- -rowSums(ifelse(prop_matrix > 0, prop_matrix * log(prop_matrix), 0))
h1 <- exp(H)
h2 <- 1 / rowSums(prop_matrix^2)

hill_df_full <- data.frame(
  id = landcover_wide$id,
  h0 = h0,
  h1 = h1,
  h2 = h2
)

hill_long <- hill_df_full %>%
  tidyr::pivot_longer(cols = h0:h2, names_to = "q", values_to = "value") %>%
  dplyr::arrange(id, q) %>%
  dplyr::select(id, q, value)

dir.create("data", showWarnings = FALSE, recursive = TRUE)
save(hill_long, file = "data/hill.Rdata")
message("Saved data/hill.Rdata (", nrow(hill_long), " rows, ", n_distinct(hill_long$id), " samples)")
