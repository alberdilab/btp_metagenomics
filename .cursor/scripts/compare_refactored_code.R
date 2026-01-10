# Reusable function to compare original vs refactored code results
# Usage: compare_results(original_result, refactored_result, test_name = "Test")

compare_results <- function(original, refactored, test_name = "Comparison Test") {
  cat("\n=== ", test_name, " ===\n")
  
  # Check dimensions
  orig_dims <- dim(original)
  ref_dims <- dim(refactored)
  
  cat("Original dimensions:", paste(orig_dims, collapse = " x "), "\n")
  cat("Refactored dimensions:", paste(ref_dims, collapse = " x "), "\n")
  
  if (!identical(orig_dims, ref_dims)) {
    cat("❌ FAIL: Dimensions don't match!\n")
    return(FALSE)
  }
  
  # Check column names
  orig_cols <- names(original)
  ref_cols <- names(refactored)
  
  cat("Original columns:", paste(orig_cols, collapse = ", "), "\n")
  cat("Refactored columns:", paste(ref_cols, collapse = ", "), "\n")
  
  if (!identical(orig_cols, ref_cols)) {
    cat("❌ FAIL: Column names don't match!\n")
    return(FALSE)
  }
  
  # Check if results are identical
  if (identical(original, refactored)) {
    cat("✅ PASS: Results are identical!\n")
    return(TRUE)
  } else {
    cat("❌ FAIL: Results don't match exactly\n")
    
    # Show first few rows for comparison
    cat("\nFirst 3 rows - ORIGINAL:\n")
    print(head(original, 3))
    cat("\nFirst 3 rows - REFACTORED:\n")
    print(head(refactored, 3))
    
    # Try sorting and comparing (in case only order differs)
    if (ncol(original) > 0) {
      sort_col <- names(original)[1]
      orig_sorted <- original %>% arrange(across(all_of(sort_col)))
      ref_sorted <- refactored %>% arrange(across(all_of(sort_col)))
      
      if (identical(orig_sorted, ref_sorted)) {
        cat("\n⚠️  WARNING: Results match when sorted (only order differs)\n")
        return(TRUE)
      }
    }
    
    return(FALSE)
  }
}

# Helper function to run comparison test suite
run_refactoring_tests <- function(test_list) {
  cat("Running refactoring comparison tests...\n")
  cat(strrep("=", 60), "\n\n")
  
  all_passed <- TRUE
  
  for (i in seq_along(test_list)) {
    test <- test_list[[i]]
    result <- compare_results(
      test$original,
      test$refactored,
      test$name
    )
    
    if (!result) {
      all_passed <- FALSE
    }
    cat("\n")
  }
  
  cat(strrep("=", 60), "\n")
  if (all_passed) {
    cat("✅ ALL TESTS PASSED\n")
  } else {
    cat("❌ SOME TESTS FAILED\n")
  }
  
  return(all_passed)
}

