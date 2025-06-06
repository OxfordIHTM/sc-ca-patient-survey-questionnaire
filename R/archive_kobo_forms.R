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

#'
#' Get KoboToolbox form version URLs
#'
#' Extracts and names URLs of deployed versions of Kobo assets from a provided
#' asset version list.
#'
#' @param asset_version_list A data frame containing Kobo asset version
#'   metadata. Usually produced through a call to
#'   [robotoolbox::kobo_asset_version_list()]
#'
#' @returns A named list of URLs of deployed asset versions, ordered from
#'   latest to earliest. The names follow the pattern `"vX"` where X is the
#'   version number in reverse order (e.g., `"v3"`, `"v2"`, `"v1"` for three 
#'   versions).
#'
#' @examples
#' \dontrun{
#'   asset_version <- robotoolbox::kobo_asset_version("a7EvYpoaFipKbXXfQfQXCx")
#'   asset_version_list <- robotoolbox::kobo_asset_version_list(asset_version)
#'   kobo_get_version_urls(asset_version_list)
#' }
#'
#' @export
#' 

kobo_get_version_urls <- function(asset_version_list) {
  asset_version_list <- asset_version_list |>
    dplyr::filter(deployed)
  
  asset_version_urls <- asset_version_list |>
    dplyr::pull(url) |>
    split(f = 1:nrow(asset_version_list)) |>
    stats::setNames(
      nm = paste0(
        "v", seq(from = nrow(asset_version_list), to = 1, by = -1)
      )
    )

  ## Return urls ----
  asset_version_urls
}

#'
#' Retrieve KoboToolbox form versions
#'
#' Downloads and saves a specific deployed version of a KoboToolbox form in
#' XLSForm standard.
#'
#' @param form_version_url A named list of length 1, where the name indicates
#'   the version (e.g., `"v1"`) and the value is the URL to fetch the form JSON.
#' @param form_title Optional. A character string used as the form title in the 
#'   output. Defaults to `NULL`.
#' @param directory Directory path where the versioned form should be saved.
#'   Default is `"forms/archive"`.
#' @param file_name The file name for the archived XLSForm file
#'   (e.g., `"form_v1.xlsx"`).
#' @param token KoboToolbox API token used for authentication. Defaults to the
#'   environment variable `"KOBOTOOLBOX_TOKEN"`.
#'
#' @returns The file path of the saved Excel workbook containing the form
#'   version.
#'
#' @examples
#' \dontrun{
#'   url_list <- list("v1" = "https://kc.kobotoolbox.org/api/v2/assets/xyz/versions/1/")
#'   kobo_archive_form_versions(
#'     form_version_url = url_list,
#'     form_title = "My Survey Form",
#'     file_name = "survey_v1.xlsx"
#'   )
#' }
#'
#' @export
#' 

kobo_archive_form_versions <- function(form_version_url,
                                       form_title = NULL,
                                       directory = "forms/archive",
                                       file_name,
                                       token = Sys.getenv("KOBOTOOLBOX_TOKEN")) {
  ## Get version number ----
  version <- names(form_version_url)

  ## Create directory path ----
  dir_path <- file.path(directory, version)

  ## Create version folder in directory ----
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)

  ## Create file path ----
  file_path <- file.path(dir_path, file_name)

  ## Create version as needed ----
  if (!file.exists(file_path)) {
    req <- httr2::request(form_version_url[[1]]) |>
      httr2::req_headers(Authorization = paste0("Token ", token))
  
    resp <- req |>
      httr2::req_perform()
  
    form_json <- resp |>
      httr2::resp_body_json(simplifyVector = TRUE)

    survey <- form_json$content$survey |>
      dplyr::mutate(
        type = ifelse(
          grepl("select_", type), paste(type, select_from_list_name), type
        ),
        `label::English (en)` = unlist(label)[2],
        `label::Creole (cpf)` = unlist(label)[1],
        `hint::English (en)` = unlist(hint)[2],
        `hint::Creole (cpf)` = unlist(hint)[1]
      ) |>
      dplyr::select(
        -`$kuid`, -`$xpath`, -`$autoname`, -select_from_list_name,
        -label, -hint,
      )
    
    if ("constraint_message" %in% names(survey)) {
      survey <- survey |>
        dplyr::mutate(
          `constraint_message::English (en)` = unlist(constraint_message)[2],
          `constraint_message::Creole (cpf)` = unlist(constraint_message)[1]
        ) |>
        dplyr::select(-constraint_message) |>
        dplyr::relocate(
          `constraint_message::English (en)`, `constraint_message::Creole (cpf)`,
          .before = relevant
        )
    }

    survey <- survey |>
      dplyr::relocate(type, .before = name) |>
      dplyr::relocate(
        `label::English (en)`, `label::Creole (cpf)`, 
        `hint::English (en)`, `hint::Creole (cpf)`,
        .before = required
      )

    choices <- form_json$content$choices |>
      dplyr::mutate(
        `label::English (en)` = unlist(label)[2],
        `label::Creole (cpf)` = unlist(label)[1]
      ) |>
      dplyr::relocate(list_name, .before = name) |>
      dplyr::select(-`$kuid`, -`$autovalue`, -label)

    if ("media::image" %in% names(choices)) {
      choices <- choices |>
        dplyr::mutate(
          `media::image::English (en)` = unlist(`media::image`)[2],
          `media::image::Creole (cpf)` = unlist(`media::image`)[1]
        ) |>
        dplyr::select(-`media::image`)
    }

    settings <- form_json$content$settings |>
      dplyr::bind_cols() |>
      dplyr::mutate(form_title = form_title, .before = style) |>
      dplyr::rename(form_id = id_string) |>
      dplyr::relocate(form_id, .before = style)
  
    wb <- openxlsx::createWorkbook()

    Map(
      f = openxlsx::addWorksheet,
      wb = list(wb, wb, wb),
      sheetName = c("survey", "choices", "settings")
    )

    Map(
      f = openxlsx::writeData,
      wb = list(wb, wb, wb),
      sheet = list("survey", "choices", "settings"),
      x = list(survey, choices, settings)
    )

    openxlsx::saveWorkbook(wb, file = file_path)
  }

  ## Return file path ----
  file_path
}

