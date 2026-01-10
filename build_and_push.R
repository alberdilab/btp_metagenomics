# Build and Push Script for Bookdown
# This script renders the bookdown webbook and pushes changes to git
# Run this script from the project root directory
#
# Usage:
#   source("build_and_push.R")
#   OR
#   Rscript build_and_push.R

# Load required libraries
if (!requireNamespace("bookdown", quietly = TRUE)) {
  stop("Please install bookdown: install.packages('bookdown')")
}

# Set working directory to project root (if not already there)
if (!file.exists("_bookdown.yml")) {
  # Try to find the project root by looking for _bookdown.yml
  if (file.exists(file.path("..", "_bookdown.yml"))) {
    setwd("..")
    message("Changed to project root directory")
  } else {
    stop("Please run this script from the project root directory (where _bookdown.yml is located)")
  }
}

message(paste(rep("=", 60), collapse = ""))
message("Building Bookdown Webbook")
message(paste(rep("=", 60), collapse = ""))

# Step 1: Render the book
message("\n[1/3] Rendering bookdown...")
tryCatch({
  bookdown::render_book("index.Rmd", output_dir = "docs")
  message("✓ Book rendered successfully!")
}, error = function(e) {
  stop("Error rendering book: ", e$message)
})

# Step 2: Git operations
message("\n[2/3] Staging changes for git...")

# Check if git is available
git_path <- Sys.which("git")
if (git_path == "") {
  warning("Git not found in PATH. Skipping git operations.")
  message("\n[3/3] Skipped - Git not available")
  message("You can manually commit and push with:")
  message('  git add -A')
  message('  git commit -m "Update webbook"')
  message('  git push')
} else {
  # Stage all changes
  message("Staging all changes...")
  add_result <- system("git add -A", intern = FALSE)
  
  # Check if there are changes to commit
  status_output <- system("git status --porcelain", intern = TRUE)
  if (length(status_output) == 0 || all(status_output == "")) {
    message("✓ No changes to commit")
  } else {
    message("\n[3/3] Committing and pushing to git...")
    
    # Get commit message (use default if running non-interactively)
    if (interactive()) {
      commit_message <- readline(prompt = "Enter commit message (or press Enter for default): ")
    } else {
      commit_message <- ""
    }
    
    if (commit_message == "") {
      commit_message <- paste0("Update webbook - ", Sys.Date())
    }
    
    # Commit changes (escape quotes for Windows)
    commit_cmd <- paste0('git commit -m "', gsub('"', '\\"', commit_message), '"')
    commit_result <- system(commit_cmd, intern = FALSE)
    
    commit_status <- attr(commit_result, "status")
    if (is.null(commit_status) || commit_status == 0) {
      message("✓ Changes committed successfully")
      
      # Ask if user wants to push (only if interactive)
      if (interactive()) {
        push_confirm <- readline(prompt = "Push to remote? (y/n): ")
        if (tolower(push_confirm) %in% c("y", "yes")) {
          push_result <- system("git push", intern = FALSE)
          push_status <- attr(push_result, "status")
          if (is.null(push_status) || push_status == 0) {
            message("✓ Changes pushed to remote successfully!")
          } else {
            warning("Error pushing to remote. You may need to push manually.")
          }
        } else {
          message("Skipped push. You can push manually with: git push")
        }
      } else {
        message("Non-interactive mode: Skipping push. Run 'git push' manually if needed.")
      }
    } else {
      warning("Error committing changes. You may need to commit manually.")
    }
  }
}

message("\n", paste(rep("=", 60), collapse = ""))
message("Build and push complete!")
message(paste(rep("=", 60), collapse = ""))

