suppressPackageStartupMessages({
  library(tidyverse)
  library(Hmsc)
  library(ape)
})

load("data/data.Rdata")
load("hmsc/model_env")

genomes_to_model <- m$spNames
samples <- rownames(m$Y)

animal_variables <- read_csv("data/animal_var.csv", show_col_types = FALSE)
location_variables <- read_csv("data/environment_var_r200.csv", show_col_types = FALSE)

predictors <- inner_join(animal_variables, location_variables, by = "id") %>%
  rename(sample = id) %>%
  filter(sample %in% samples)

StudyDesign <- predictors %>%
  select(sample, site) %>%
  mutate(animal = sample) %>%
  mutate(animal = factor(animal), site = factor(site)) %>%
  column_to_rownames("sample")

normalisation_factor <- genome_metadata %>%
  mutate(factor = median(length) / length) %>%
  pull(factor)

YData <- read_counts %>%
  mutate(across(where(is.numeric), ~ round(. * normalisation_factor, 0))) %>%
  mutate(across(where(is.numeric), ~ . + 1)) %>%
  mutate(across(where(is.numeric), ~ log(.))) %>%
  filter(genome %in% genomes_to_model) %>%
  column_to_rownames("genome") %>%
  select(all_of(row.names(StudyDesign))) %>%
  as.data.frame() %>%
  t()

XData <- predictors %>%
  select(sample, temperature, precipitation, diversity, density, devil) %>%
  mutate(logseqdepth = read_counts %>%
    select(all_of(row.names(StudyDesign))) %>%
    colSums() %>%
    log()) %>%
  column_to_rownames("sample")

PData <- genome_tree %>%
  keep.tip(tip = genomes_to_model)

XFormula <- ~ devil + temperature + diversity + logseqdepth + devil:temperature

rL.animal <- HmscRandomLevel(units = levels(StudyDesign$animal))
rL.site <- HmscRandomLevel(units = levels(StudyDesign$site))

m <- Hmsc(
  Y = YData,
  XData = XData,
  XFormula = XFormula,
  studyDesign = StudyDesign,
  phyloTree = PData,
  ranLevels = list("animal" = rL.animal, "site" = rL.site),
  distr = "normal",
  YScale = TRUE
)

cat("Rebuilt model_final:", length(m$spNames), "genomes,", nrow(m$Y), "samples\n")
cat("Covariates:", paste(m$covNames, collapse = ", "), "\n")

save(m, file = "hmsc/model_final")
