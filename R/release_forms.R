#'
#' Create a new GitHub release gag
#'
#' Generates a new release tag for a GitHub repository. If no `repo` is
#' specified, the repository name is retrieved from a helper function. The tag 
#' is created based on the current date and the structure of the latest release.
#'
#' The tag format is typically: `YYYY.MM.NN` where:
#' * `YYYY` is the current year;
#' * `MM` is the current month; and,
#' * `NN` is a release counter that increments if multiple releases occur in the
#'   same year and month.
#'
#' If no prior releases exist, the tag is initialized using `release_start` as
#' the start of the release counter `NN`.
#'
#' @param repo Character. Optional. The GitHub repository in the format
#'   `"owner/repo"`. If `NULL`, the repository is retrieved using
#'   [get_github_repository()].
#' @param release_start Integer. Used as a seed when generating the release tag,
#'   if no previous releases exist. Defaults to `1`.
#'
#' @returns A character string representing the newly generated release tag.
#'
#' @examples
#' \dontrun{
#'   github_create_release_tag(release_start = 1)
#'   github_create_release_tag(repo = "owner/repo", release_start = 1)
#' }
#'
#' @export
#' 


github_create_release_tag <- function(repo = NULL, release_start = 1) {
  ## Get repo name if repo is NULL ----
  if (is.null(repo)) repo <- get_github_repository()

  ## Create new release tag ----
  releases <- gh::gh(file.path("/repos", repo, "releases"))

  if (length(release) == 0) {
    tag <- lapply(
      X = c("%Y", "%m"), FUN = function(x) format(Sys.Date(), format = x)
    ) |>
      paste(collapse = ".") |>
      paste(release_start, sep = ".")
  } else {
    ## Get current release ----
    latest_tag_split <- gh::gh(
      file.path("/repos", repo, "releases/latest")
    )$tag_name |>
      stringr::str_split(pattern = "\\.") |>
      unlist()

    current_year <- format(Sys.Date(), format = "%Y")
    current_month <- format(Sys.Date(), format = "%m")

    if (latest_tag_split[1] != current_year) {
      tag <- paste(current_year, current_month, "01", sep = ".")
    } else {
      if (latest_tag_split[2] != current_month) {
        tag <- paste(latest_tag_split[1], current_month, "01", sep = ".")
      } else {
        tag <- paste(
          current_year, current_month,
          (as.numeric(latest_tag_split[3]) + 1) |>
            stringr::str_pad(width = 2, side = "left", pad = "0"),
          sep = "."
        )
      }
    }
  }

  ## Return tag ----
  tag
}


#' 
#' Create a new GitHub release
#'
#' Creates a new GitHub release for a specified repository. If no repository is
#' provided, it is inferred using the [get_github_repository()] helper. A
#' release tag is generated using [github_create_release_tag()] and the release
#' is created via the [piggyback::pb_release_create()] function.
#'
#' @param repo Character. Optional. The GitHub repository in the format
#'   `"owner/repo"`. If `NULL`, the repository is retrieved using 
#'   [get_github_repository()].
#' @param body Text describing the contents of the tag. Default text is
#'   "Form release".
#' @param release_start Integer. Used as a seed when generating the release tag,
#'   if no previous releases exist. Defaults to `1`.
#'
#' @return A character string representing the created release tag.
#'
#' @examples
#' \dontrun{
#'   github_create_release()
#'   github_create_release(repo = "owner/repo")
#' }
#'
#' @export
#' 

github_create_release <- function(repo = NULL,
                                  body = "Form release",
                                  release_start = 1) {
  ## Get repo name if repo is NULL ----
  if (is.null(repo)) repo <- get_github_repository()
  
  ## Create tag ----
  tag <- github_create_release_tag(repo = repo, release_start = release_start)

  ## Create release ----
  piggyback::pb_release_create(repo = repo, tag = tag, body = body)

  ## Return tag ----
  tag
}


#'
#' Create data upload to GitHub
#'

github_upload_release <- function(repo = NULL, tag) {
  ## zip media files ----
  zip("forms/release/media.zip", files = "forms/release/media", flags = "-r -j")

  lapply(
    X = list.files("forms/release", full.names = TRUE, pattern = "xlsx|zip"),
    FUN = piggyback::pb_upload,
    tag = tag
  )

  file.remove("forms/release/media.zip")
}

