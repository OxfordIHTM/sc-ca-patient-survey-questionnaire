#'
#' Download and read patient list from OneDrive
#' 

read_patient_list <- function(dest_dir = tempdir()) {
  onedrive <- Microsoft365R::get_business_onedrive()

  onedrive_patient_list <- "sc_onco_facility_study/Pilot/List of Cancer Patients on Chemotherapy March 2025_anonymised.xlsx"

  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)

  onedrive$download_file(
    src = onedrive_patient_list, 
    dest = file.path(dest_dir, "patient_list.xlsx"),
    overwrite = TRUE
  )

  patient_list_file <- file.path(dest_dir, "patient_list.xlsx")

  patient_list <- openxlsx::read.xlsx(
    xlsxFile = patient_list_file, sheet = 2, detectDates = TRUE
  ) |>
    dplyr::select(`ASSIGNED.TO.-.NURSE/ENUMERATOR`, `UNIQUE.PATIENT.ID`) |>
    stats::setNames(nm = c("enumerator", "id")) |>
    dplyr::mutate(enumerator = stringr::str_to_title(enumerator)) |>
    recode_nurse_names()

  unlink(file.path(dest_dir, "patient_list.xlsx"))

  patient_list
}


recode_nurse_names <- function(patient_list_raw) {
  x <- patient_list_raw |>
    dplyr::count(enumerator) |>
    dplyr::mutate(
      code = paste0("nurse", stringr::str_pad(1:8, width = 2, pad = "0")),
      code_exp = paste0("rep(x = '", code, "', times = ", n, ")")
    )
  
  nurse_code <- lapply(
    X = x$code_exp, FUN = function(x) eval(parse(text = x))
  ) |>
    unlist()

  patient_list_raw |>
    dplyr::arrange(enumerator) |>
    dplyr::mutate(enumerator_code = nurse_code) |>
    dplyr::arrange(id)
}