#'
#' Retrieve KoboToolbox forms
#' 
#' 

kobo_retrieve_forms <- function(form_id, form_type = c("xls", "xml"),
                                base_url = Sys.getenv("KOBOTOOLBOX_URL"),
                                token = Sys.getenv("KOBOTOOLBOX_TOKEN")) {
  req <- httr2::request(base_url)

  req <- req |>
    httr2::req_url_path_append(
      "api/v2/assets", paste0(form_id, ".", form_type)
    )

  req <- req |>
    httr2::req_headers(
      Authorization = paste0("Token ", token)
    )

  resp <- req |>
    httr2::req_perform()

  ## Check types ----


  auth_handle <- curl::new_handle() |>
    curl::handle_setheaders(
      Authorization = paste0("Token ", token)
    )
  
  curl::curl_download(
    url = req$url,
    destfile = "forms/onco_patient_survey.xls",
    handle = auth_handle
  )
}


#'
#' Get KoboToolbox form unique identifier by form name
#'
#' This function retrieves the UID (unique identifier) of a KoboToolbox form 
#' given its form name from an asset list.
#'
#' @param asset_list A data frame or tibble containing KoboToolbox assets. This
#'   is usually produced through a call to [robotoolbox::kobo_asset_list()].
#' @param form_name A character string specifying the name of the form 
#'   whose UID is to be retrieved.
#'
#' @return A character string representing the UID of the specified form. 
#'   If the form is not found, a warning is issued and an empty string is
#'   returned.
#'
#' @examples
#' \dontrun{
#'   asset_list <- robotoolbox::kobo_asset_list()
#' 
#'   kobo_get_uid(asset_list, "Form A")
#'   kobo_get_uid(asset_list, "Form C")
#' }
#'
#' @export
#' 

kobo_get_uid <- function(asset_list, form_name) {
  if (!form_name %in% asset_list$name)
    warning(
      "Form with name ", form_name, " not found. ",
      "Returning empty `uid` string."
    )
    
  ## Get uid ----
  uid <- asset_list$uid[asset_list$name == form_name]

  ## Return uid ----
  uid
}