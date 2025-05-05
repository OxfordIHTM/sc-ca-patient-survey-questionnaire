#'
#' Deploy forms to KoboToolbox
#' 
#' 


kobo_deploy_form <- function(base_url = "https://eu.kobotoolbox.org",
                             project_id,
                             file,
                             token = Sys.getenv("KOBOTOOLBOX_TOKEN")) {
  req <- httr2::request(base_url) |>
    httr2::req_url_path("api/v2/imports") |>
    httr2::req_body_file(
      path = file,
      type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ) |>
    # httr2::req_body_multipart(
    #   file = curl::form_file(
    #     file, 
    #     type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    #     name = basename(file)
    #   ),
    #   #file = file,
    #   #destination = file.path(base_url, "api/v2/assets", project_id),
    #   library = "false"
    # ) |>
    httr2::req_headers(Authorization = paste0("Token ", token))

  resp <- httr2::req_perform(req)
}

