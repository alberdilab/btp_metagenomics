# Agent Allowlist and Behavior Rules

## Direct Command Execution
- **Rule 1**: Any direct command from the user chat should be executed immediately without asking for permission
- When the user provides explicit instructions, execute them directly
- Do not request confirmation for commands that are clearly stated by the user

## Testing and Validation
- **Rule 2**: When working in agent mode, testing if new/refactored code is functional should run without extra permission
- This includes:
  - Running test scripts to verify function correctness
  - Executing R code chunks to validate changes
  - Running syntax checks
  - Comparing outputs before/after refactoring
  - Any validation needed to ensure code works as expected
- Testing is considered part of the development workflow and should proceed automatically

## Automatic Comparison Testing for Refactoring
- **Rule 3**: When refactoring code, ALWAYS automatically test that refactored code produces identical results to the original
- **Required Steps**:
  1. Before refactoring: Note the original code pattern
  2. After refactoring: Create comparison test script
  3. Run both original and refactored code with same data
  4. Use `identical()` to verify exact match
  5. Report results: ✅ PASS if identical, ❌ FAIL if different
  6. If results don't match: Fix refactored code before proceeding
- **Test Requirements**:
  - Results must be identical (same rows, columns, values, types, ordering)
  - Test with actual data from the project
  - Clean up test files after verification
- **Failure Handling**: If results don't match, stop and fix the refactored code

## Code Execution Permissions
- **Allowed without permission**:
  - Running test scripts (R, Python, shell scripts)
  - Executing code to verify functionality
  - Running linters and syntax checkers
  - Creating temporary test files (clean up after)
  - Running git commands for verification (status, diff, log)
  
- **Requires explicit permission**:
  - Committing changes to git
  - Pushing to remote repositories
  - Deleting files outside of temporary test files
  - Modifying system settings or configurations

## Workflow
1. User provides instruction → Execute directly
2. Code changes made → Test automatically
3. **If refactoring**: Run comparison test (original vs refactored)
4. Test results → Report to user
5. Clean up temporary files → Automatic

## Refactoring Workflow (Detailed)
1. **Before refactoring**: Note/capture original code pattern and expected output
2. **Refactor code**: Create helper functions or simplify code
3. **Create comparison test**: Test both original and refactored code with same data
4. **Run comparison**: Use `identical()` to verify exact match
5. **Report results**: 
   - ✅ PASS: Results identical → Proceed
   - ❌ FAIL: Results differ → Fix refactored code, retest
6. **Clean up**: Remove temporary test files

