#' 
#' Collect all targets and lists of targets in the environment
#' 
#' 
all_targets <- function(env = parent.env(environment()), 
                        type = "tar_target", 
                        add_list_names = TRUE) {
  
  ## Function to determine if an object is a type (a target), 
  ## or a list on only that type
  rfn <- function(obj) 
    inherits(obj, type) || (is.list(obj) && all(vapply(obj, rfn, logical(1))))
  
  ## Get the names of everything in the environment 
  ## (e.g. sourced in the _targets.R file)
  objs <- ls(env)
  
  out <- list()
  for (o in objs) {
    obj <- get(o, envir = env)      ## Get each top-level object in turn
    if (rfn(obj)) {                 ## For targets and lists of targets
      out[[length(out) + 1]] <- obj ## Add them to the output
      
      ## If the object is a list of targets, add a vector of the target names 
      ## to the environment So that one can call `tar_make(list_name)` to make 
      ## all the targets in that list
      if (add_list_names && is.list(obj)) {
        target_names <- vapply(obj, \(x) x$settings$name, character(1))
        assign(o, target_names, envir = env)
      }
    }
  }
  return(out)
}


#'
#' Get current remote GitHub repository
#' 
#' @param full Logical. Should full GitHub remote URL be extracted? Default to
#'   FALSE.
#' 
#' @returns GitHub remote repository.
#' 
#' @examples
#' if (FALSE) get_github_repository()
#' 
#' @export
#' 

get_github_repository <- function(full = FALSE) {
  ## Check if current directory is a git directory ----
  git_status <- system("git -C . rev-parse 2>/dev/null; echo $?", intern = TRUE)

  ## Check if git directory ----
  if (git_status != 0) {
    cli::cli_abort(
      c(
        "Current working directory should be a git repository",
        "x" = "Current working directory is not a git repository"
      )
    )
  } else {
    git_repo <- system("git remote -v", intern = TRUE) |>
      grep(pattern = "push", x = _, value = TRUE) |>
      gsub(pattern = "origin\t| \\(push\\)", replacement = "", x = _)
  
    if (!full) {
      if (grepl(pattern = "@", x = git_repo)) {
        git_repo <- gsub(
          pattern = "git@github.com:|.git", replacement = "", x = git_repo
        )
      } else {
        git_repo <- gsub(
          pattern = "https://github.com/|.git", replacement = "", x = git_repo
        )
      }
    }
  }

  ## Return git_repo
  git_repo
}
