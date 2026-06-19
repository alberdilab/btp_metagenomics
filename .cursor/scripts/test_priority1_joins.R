# Test script for Priority 1: Join Rules fixes
# Verifies that replacing merge() with left_join() and fixing join_by() syntax
# produces identical results

library(dplyr)
library(tibble)

# Load data
suppressPackageStartupMessages(library(distillR))

load("data/data.Rdata")

# Filter sample as done in the chapter
sample_metadata <- sample_metadata %>% dplyr::filter(sample != "EHI01340")
valid_samples <- sample_metadata$sample

if (file.exists("data/gift_community.Rdata")) {
  load("data/gift_community.Rdata")
} else {
  cat("Building GIFT community matrices (knit chapter 08 or save data/gift_community.Rdata)...\n")
  genome_counts_filt <- genome_counts_filt[
    genome_counts_filt$genome %in% rownames(genome_gifts),
  ]
  GIFTs_elements <- distillR::to.elements(genome_gifts, GIFT_db)
  GIFTs_elements_filtered <- GIFTs_elements[
    rownames(GIFTs_elements) %in% genome_counts_filt$genome,
  ]
  GIFTs_elements_filtered <- as.data.frame(GIFTs_elements_filtered) %>%
    dplyr::select(where(~ !is.numeric(.) || sum(.) != 0))
  GIFTs_functions <- distillR::to.functions(GIFTs_elements_filtered, GIFT_db)
  GIFTs_domains <- distillR::to.domains(GIFTs_functions, GIFT_db)
  genome_counts_row <- genome_counts_filt %>%
    dplyr::mutate(dplyr::across(-genome, ~ .x / sum(.x))) %>%
    tibble::column_to_rownames("genome")
  GIFTs_elements_community <- distillR::to.community(GIFTs_elements_filtered, genome_counts_row, GIFT_db)
  GIFTs_functions_community <- distillR::to.community(GIFTs_functions, genome_counts_row, GIFT_db)
  GIFTs_domains_community <- distillR::to.community(GIFTs_domains, genome_counts_row, GIFT_db)
}

# Filter GIFT community data
GIFTs_elements_community <- GIFTs_elements_community[rownames(GIFTs_elements_community) %in% valid_samples, , drop = FALSE]
GIFTs_functions_community <- GIFTs_functions_community[rownames(GIFTs_functions_community) %in% valid_samples, , drop = FALSE]
GIFTs_domains_community <- GIFTs_domains_community[rownames(GIFTs_domains_community) %in% valid_samples, , drop = FALSE]

cat("Testing Priority 1 Join Rules fixes...\n\n")

# Test 1: Fix redundant join_by syntax in comunity_elem
cat("Test 1: Fixing join_by syntax in comunity_elem...\n")
element_gift_original <- GIFTs_elements_community %>% 
  as.data.frame() %>% 
  rownames_to_column(., "sample") %>% 
  left_join(sample_metadata %>% select(sample,sex, broad_environment), by=join_by("sample"=="sample"))

element_gift_fixed <- GIFTs_elements_community %>% 
  as.data.frame() %>% 
  rownames_to_column(., "sample") %>% 
  left_join(sample_metadata %>% select(sample,sex, broad_environment), by=join_by(sample))

test1_result <- identical(element_gift_original, element_gift_fixed)
cat(sprintf("  Result: %s\n", if(test1_result) "✅ PASS" else "❌ FAIL"))
if(!test1_result) {
  cat("  Differences found in element_gift\n")
  print(all.equal(element_gift_original, element_gift_fixed))
}

# Test 2: Replace merge() with left_join() in comunity_func_gut
cat("\nTest 2: Replacing merge() with left_join() in comunity_func_gut...\n")
function_gift_original <- GIFTs_functions_community %>% 
  as.data.frame() %>% 
  rownames_to_column(., "sample") %>% 
  merge(., sample_metadata %>% select(sample,sex,broad_environment), by="sample")

function_gift_fixed <- GIFTs_functions_community %>% 
  as.data.frame() %>% 
  rownames_to_column(., "sample") %>% 
  left_join(sample_metadata %>% select(sample,sex,broad_environment), by=join_by(sample))

# Note: merge() may reorder rows, so we need to sort before comparing
function_gift_original_sorted <- function_gift_original %>% arrange(sample)
function_gift_fixed_sorted <- function_gift_fixed %>% arrange(sample)

test2_result <- identical(function_gift_original_sorted, function_gift_fixed_sorted)
cat(sprintf("  Result: %s\n", if(test2_result) "✅ PASS" else "❌ FAIL"))
if(!test2_result) {
  cat("  Differences found in function_gift\n")
  cat("  Original rows:", nrow(function_gift_original), "\n")
  cat("  Fixed rows:", nrow(function_gift_fixed), "\n")
  cat("  Column names match:", identical(names(function_gift_original), names(function_gift_fixed)), "\n")
  print(all.equal(function_gift_original_sorted, function_gift_fixed_sorted))
}

# Test 3: Replace merge() with left_join() in comunity_dom_gut
cat("\nTest 3: Replacing merge() with left_join() in comunity_dom_gut...\n")
domain_gift_original <- GIFTs_domains_community %>% 
  as.data.frame() %>% 
  rownames_to_column(., "sample") %>% 
  merge(sample_metadata %>% select(sample,sex), by="sample")

domain_gift_fixed <- GIFTs_domains_community %>% 
  as.data.frame() %>% 
  rownames_to_column(., "sample") %>% 
  left_join(sample_metadata %>% select(sample,sex), by=join_by(sample))

# Sort before comparing
domain_gift_original_sorted <- domain_gift_original %>% arrange(sample)
domain_gift_fixed_sorted <- domain_gift_fixed %>% arrange(sample)

test3_result <- identical(domain_gift_original_sorted, domain_gift_fixed_sorted)
cat(sprintf("  Result: %s\n", if(test3_result) "✅ PASS" else "❌ FAIL"))
if(!test3_result) {
  cat("  Differences found in domain_gift\n")
  cat("  Original rows:", nrow(domain_gift_original), "\n")
  cat("  Fixed rows:", nrow(domain_gift_fixed), "\n")
  cat("  Column names match:", identical(names(domain_gift_original), names(domain_gift_fixed)), "\n")
  print(all.equal(domain_gift_original_sorted, domain_gift_fixed_sorted))
}

# Summary
cat("\n" , rep("=", 50), "\n", sep="")
cat("SUMMARY:\n")
cat(sprintf("Test 1 (join_by syntax): %s\n", if(test1_result) "✅ PASS" else "❌ FAIL"))
cat(sprintf("Test 2 (merge -> left_join functions): %s\n", if(test2_result) "✅ PASS" else "❌ FAIL"))
cat(sprintf("Test 3 (merge -> left_join domains): %s\n", if(test3_result) "✅ PASS" else "❌ FAIL"))

all_passed <- test1_result && test2_result && test3_result
cat(sprintf("\nOverall: %s\n", if(all_passed) "✅ ALL TESTS PASSED" else "❌ SOME TESTS FAILED"))

if(all_passed) {
  cat("\nAll Priority 1 join rule fixes produce identical results!\n")
} else {
  cat("\n⚠️  Some tests failed. Review differences above.\n")
}

