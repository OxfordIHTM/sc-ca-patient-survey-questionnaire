#'
#' Create unique patient identifiers
#'
#' Generates a vector of unique patient identifiers composed of a specified 
#' pattern and with the option of adding either a prefix or a suffix.
#'
#' @param n Integer. Number of patient IDs to generate.
#' @param pattern Character. Pattern to use for ID generation. Can be one of 
#'   `"alphanumeric"`, `"alpha"`, or `"numeric"`. Defaults to `"alphanumeric"`.
#' @param sequential Logical. If `pattern` is `"numeric"`, should numbers be
#'   generated in sequential order or in random? Default to FALSE.
#' @param prefix Character value to prefix the identifiers with.
#' @param suffix Character value to suffix the identifiers with.
#'
#' @returns A character vector of unique patient identifiers in the format
#'   `"PREFIX-ID-SUFFIX"`, where `ID` is a 6-character string generated based
#'   on the selected pattern.
#'
#' @examples
#' create_patient_id(n = 20)
#' create_patient_id(n = 10, pattern = "alpha", prefix = "2023")
#' create_patient_id(n = 5, pattern = "numeric", sequential = TRUE)
#'
#' @export
#' 

create_patient_id <- function(n,
                              pattern = c("alphanumeric", "alpha", "numeric"),
                              sequential = FALSE,
                              prefix = NULL, suffix = NULL) {
  ## Detect pattern ----
  pattern <- match.arg(pattern)

  ## Check prefix and suffix ----
  if (!is.null(prefix)) {
    if (!is.vector(prefix)) {
      stop("`prefix` should be a character value. Try again.")
    }

    if (length(prefix) > 1) {
      warning(
        "`prefix` has length > 1. Only first value will be used as prefix."
      )

      prefix <- prefix[1]
    }
  }

  if (!is.null(suffix)) {
    if (!is.vector(suffix)) {
      stop("`suffix` should be a character value. Try again.")
    }

    if (length(suffix) > 1) {
      warning(
        "`suffix` has length > 1. Only first value will be used as suffix."
      )

      suffix <- suffix[1]
    }
  }

  ## Generate unique identifier ----

  if (pattern == "numeric" & sequential) {
    uid <- seq(from = 1, to = n, by = 1) |>
      stringi::stri_pad_left(width = 6, pad = "0")
  } else {
    uid <- stringi::stri_rand_strings(
      n = n, length = 6, 
      pattern = switch(
        EXPR = pattern,
        "alphanumeric" = "[A-Z0-9]",
        "alpha" = "[A-Z]",
        "numeric" = "[0-9]"
      )
    )
  }

  ## Add prefix and suffix ----
  if (!is.null(prefix)) uid <- paste(prefix, uid, sep = "-")
  if (!is.null(suffix)) uid <- paste(uid, suffix, sep = "-")

  ## Return uid ----
  uid
}


#'
#' Create a data.frame of patient identifiers for ODK external select
#' 
#' Constructs a patient list data frame using provided IDs and optional labels, 
#' language-specific labeling, and filtering columns.
#'
#' @param ids Character vector. Unique patient IDs. Usually created using
#'   [create_patient_id()]
#' @param language Character (optional). Language for the alternate label, 
#'   specified in the format `"Language Name (xx)"`, where `xx` is the two- or 
#'   three-letter language code (e.g., `"French (fr)"`).
#' @param label Character vector (optional). Primary labels to display for each
#'   ID. Must be the same length as `ids`. Defaults to using `ids` as the label.
#' @param label_other Character vector (optional). Translated labels in the 
#'   language specified by `language`. Must be the same length as `ids`. If not 
#'   specified, defaults to `label`.
#' @param name_key Logical. Should the list be created with a name key? Set to
#'   FALSE (default) if creating an external select list using ODK's
#'   *select from file approach* which is supported in newer versions of ODK
#'   Collect. Set to TRUE if creating an external select list using ODK's
#'   *search from file approach* which is compatible with older versions of ODK
#'   Collect.
#' @param choice_filter Character vector (optional). A vector of filter values
#'   for each ID. Must be the same length as `ids`.
#' @param choice_filter_label Character (optional). Column name to use for the 
#'   `choice_filter` column. Required if `choice_filter` is provided.
#'
#' @returns A `data.frame` or `tibble` containing the patient ID list with 
#'   associated labels and optional filter column(s).
#'
#' @examples
#' create_patient_list(
#'   ids, language = "Creole (cpf)", label_other = NULL, 
#'   choice_filter = c(
#'     rep("NURSE01", 50), rep("NURSE02", 50),
#'     rep("NURSE03", 50), rep("NURSE04", 50),
#'     rep("NURSE05", 50), rep("NURSE06", 50),
#'     rep("NURSE07", 50), rep("NURSE08", 50)
#'   ), 
#'   choice_filter_label = "island"
#' )
#'
#' @export
#' 

create_patient_list <- function(ids,
                                language = NULL, 
                                label = NULL,
                                label_other = NULL,
                                name_key = FALSE,
                                choice_filter = NULL,
                                choice_filter_label = NULL) {
  name <- ids

  id_df <- data.frame(name = name)

  if (is.null(label)) {
    label <- name
  } else {
    ## Check length of label ----
    if (length(label) != length(ids))
      stop("`label` should be of same length as `ids`. Try again.")
  }

  if (is.null(language)) {
    id_df <- data.frame(id_df, label = label)
  } else {
    ## Check that label spec is correct ----
    if (!grepl(pattern = "\\([a-z]{2,3}\\)", x = language)) {
      stop(
        "Language specification is not in correct format.",
        "Format should be language name, followed by the ",
        "two letter language code in parentheses. Try again."
      )
    }
    
    ## Check that label_other is specified ----
    if (is.null(label_other)) label_other <- label 
    
    ## Check that label_other is of correct length ----
    if (length(label_other) != length(ids)) {
      stop("`label_other` should be of same length as `ids`. Try again.")
    } else {
      label_en <- "label::English (en)"
      label_other_lang <- paste0("label::", language)
    }
    
    id_df <- tibble::tibble(
      id_df, label_en = label, label_other_lang = label_other
    ) |>
      stats::setNames(nm = c("name", label_en, label_other_lang))
  }

  if (!is.null(choice_filter)) {
    ## Check length of choice_filter -----
    if (length(choice_filter) != length(ids)) {
      stop("`choice_filter` should be of same length as `ids`. Try again.")
    }

    ## Check that choice_filter_label is specified ----
    if (is.null(choice_filter_label)) {
      stop(
        "`choice_filter_label` is required if `choice_filter` is specified). ",
        "Try again."
      )
    } else {
      id_df <- tibble::tibble(id_df, choice_filter)

      names(id_df)[ncol(id_df)] <- choice_filter_label
    }
  }

  if (name_key) {
    id_df <- tibble::tibble(name_key = name, id_df)
  }

  ## Return id_df ----
  id_df
}


#' 
#' Write patient list to CSV for ODK external select
#'
#' Saves a patient list data frame to a CSV file in a specified directory.
#' If the directory does not exist, it will be created.
#'
#' @param patient_list A `data.frame` or `tibble` containing the patient list, 
#'   typically created using [create_patient_list()].
#' @param directory Character. The directory where the CSV file should be saved. 
#'   Defaults to `"forms/media"`.
#'
#' @returns The full file path to the saved CSV file as a character string.
#'
#' @details The file is saved with the name `patient_list.csv`. If the specified 
#'   directory does not exist, it will be created automatically.
#'
#' @examples
#' \dontrun{
#'   patient_list <- create_patient_list(ids = c("P001", "P002"))
#'   write_patient_list(patient_list)
#' }
#'
#' @export
#' 

write_patient_list <- function(patient_list, directory = "forms/release/media") {
  ## Create directory if needed ----
  if (!dir.exists(directory)) {
    message(
      "Directory `", directory, "` doesn't exist. ",
      "Creating directory."
    )

    ## Create directory ----
    dir.create(directory)
  }

  ## Create file_path ----
  file_path <- file.path(directory, "patient_list.csv")

  ## Write patient list to file_path ----
  write.csv(patient_list, file = file_path, row.names = FALSE)

  ## Return file_path ----
  file_path
}