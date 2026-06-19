GOAL: Shorten and optimize R code; make it functional + readable.

STYLE:
- Prefer tidyverse (dplyr/tidyr/purrr)
- Use native pipe |> (or %>% if preferred)
- Avoid duplicated code; extract reusable functions
- Use consistent naming: snake_case for variables, descriptive names

CODE SIMPLIFICATION RULES:
- Simplify and slim code whenever possible
- Combine multiple mutate() calls into a single mutate() with multiple transformations
- Replace deprecated functions (mutate_at, select_if) with modern alternatives (across, where)
- Eliminate redundant operations (e.g., multiple select() calls, unnecessary variable assignments)
- Extract repeated code patterns into reusable helper functions
- Remove intermediate variables that are only used once
- Use more concise tidyverse syntax where applicable

DEBUGGING RULES:
- Always check for typos in variable names, function names, and column names
- Verify that all referenced columns exist in the dataframes
- Check for redundancies: duplicate computations, repeated code blocks, unnecessary operations
- Ensure consistent use of join methods (prefer left_join() with join_by() over merge())
- Validate that filter conditions are necessary and not redundant
- Remove commented-out code that is no longer needed
- Check for inconsistent naming conventions across the codebase

TESTING RULES:
- ALWAYS create and run a test script when changing more than 5 lines of code
- Test script must verify that refactored code produces identical results to original code
- Use identical() or all.equal() to compare outputs before and after changes
- Test with actual project data, not just sample data
- If results don't match, fix the code before proceeding
- Clean up temporary test files after verification
- Document any intentional changes to output format

FUNCTION DESIGN RULES:
- Function parameters should not duplicate automatic behavior
  * If a function automatically adds a parameter to grouping, don't include it in group_vars
  * Example: prepare_taxonomy_data() adds tax_level to group_by, so don't include tax_level in group_vars
- Column names with spaces should be converted to underscores for consistency
  * Use str_replace_all(val, " ", "_") when creating column names from group values
  * Ensure select() statements match the actual column names created
- Function outputs should match what downstream code expects
  * Verify column names in helper functions match their usage in select() calls

JOIN RULES:
- Joins must not inflate rows; check uniqueness of join keys before joining
- Use explicit join_by() syntax for clarity
- Always verify join keys exist in both dataframes

DATA QUALITY RULES:
- Keep outputs identical unless explicitly requested to change
- Filter out invalid samples early in the pipeline

GROUPING RULES:
- Don't include the same variable twice in group_by()
  * Check if helper functions automatically add grouping variables
  * Remove duplicates from group_vars parameter
- Use across() with all_of() for programmatic column selection
- Always use .groups = "drop" in summarise() unless explicitly needed

COLUMN NAMING RULES:
- Convert spaces to underscores in column names for consistency
- Match column names between function creation and selection
- Use descriptive names that indicate the transformation (e.g., "_mean", "_sd")

COLOR CONSISTENCY RULES:
- Publication figures: see `VISUALIZATION_GUIDE.md` for theme, spotlight palettes, and export standards
- BASELINE: EHI Taxonomy Colour Profile is the authoritative source for all taxonomy color coding
- Maintain consistent color palettes across the entire project
- Use predefined color objects from data.Rdata: phylum_colors, treatment_colors, gift_colors
- If not hardcoded, use the EHI colours
- Never hardcode phylum colors; always reference the EHI Taxonomy Colour Profile baseline
- treatment_colors: defined as c("#f56042","#429ef5", "#42f58d", "#b142f5","#f5e642") for environments
- gift_colors: loaded from data/gift_colors.tsv for functional annotations
- Ensure color assignments match across all plots for the same categories (e.g., same phylum = same color everywhere)

COMMON TASKS:
- Join sample_metadata(sample) to r200_h1(id)
- Add Site column when needed
- Split into Tasmania vs Australia by island
- Normalize counts using mutate(across(-genome, ~ . / sum(.)))
- Join metadata using helper function join_metadata()

CODE REVIEW CHECKLIST:
- [ ] No duplicate grouping variables
- [ ] Column names match between creation and selection
- [ ] Helper functions don't duplicate parameters
- [ ] Joins don't inflate rows
- [ ] All filters applied consistently
- [ ] Output matches expected format
- [ ] Colors use predefined palettes (phylum_colors, treatment_colors, gift_colors)
- [ ] phylum_colors loaded from EHI Taxonomy Colour Profile baseline source
- [ ] Color assignments are consistent across plots for same categories
- [ ] Code simplified and slimmed (no redundant operations, combined mutate calls)
- [ ] No typos in variable/function/column names
- [ ] No redundancies (duplicate code, unnecessary operations)
- [ ] Test script created and run for changes > 5 lines
- [ ] Test results verified (identical outputs before/after)

