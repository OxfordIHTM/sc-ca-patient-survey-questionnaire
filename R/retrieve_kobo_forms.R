#'
#' Retrieve KoboToolbox forms from One Drive 
#' 
#' 

retrieve_kobo_form <- function(onedrive_form_file,
                               dest_dir = "forms/release") {
  onedrive <- Microsoft365R::get_business_onedrive()

  if (!dir.exists(dest_dir)) dir.create(dest_dir)

  onedrive$download_file(
    src = onedrive_form_file, 
    dest = file.path(dest_dir, basename(onedrive_form_file)),
    overwrite = TRUE
  )

  file.path(dest_dir, basename(onedrive_form_file))
}


retrieve_kobo_media <- function(media_form_directory,
                                dest_dir = "forms/release") {
  onedrive <- Microsoft365R::get_business_onedrive()

  dest_dir <- file.path(dest_dir, basename(media_form_directory))

  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)

  onedrive$download_folder(
    src = media_form_directory, 
    dest = dest_dir, 
    overwrite = TRUE, recursive = TRUE
  )

  file.path(dest_dir, list.files(dest_dir))
}