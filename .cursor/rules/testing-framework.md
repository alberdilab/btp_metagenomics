# Automated Testing Framework for Refactoring

## Automatic Comparison Testing
When refactoring code, always verify that the refactored version produces identical results to the original code.

## Testing Workflow
1. **Before Refactoring**: Capture original code output/results
2. **After Refactoring**: Run refactored code
3. **Comparison**: Use `identical()` or equivalent to verify exact match
4. **Report**: Confirm results match or identify differences

## Test Script Template
Create temporary test scripts that:
- Load the same data setup as the Rmd file
- Run both original and refactored code patterns
- Compare results using `identical()` or value-by-value comparison
- Report any differences
- Clean up after testing

## When to Test
- **Always test** when:
  - Creating new helper functions
  - Refactoring repetitive code blocks
  - Changing data transformation logic
  - Modifying summary statistics calculations
  - Any code that affects output/results

## Test Requirements
- Results must be **identical** (not just similar)
- Same number of rows/columns
- Same values in all cells
- Same data types
- Same ordering (if applicable)

## Failure Handling
If results don't match:
- Stop and report the differences
- Do not proceed with refactoring until fixed
- Show side-by-side comparison of mismatches
- Fix the refactored code to match original output

