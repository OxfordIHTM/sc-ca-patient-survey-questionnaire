# Workflow for Open Data Kit form deployment -----------------------------------

## Load libraries and custom functions ----
suppressPackageStartupMessages(source("packages.R"))
for (f in list.files(here::here("R"), full.names = TRUE)) source (f)


## Set build options ----

### Set seed ----
set.seed(1977)

### Connect to One Drive ----
#onedrive <- Microsoft365R::get_business_onedrive()


## Create targets and list targets objects ----

### Data targets ----
data_targets <- tar_plan(
  patient_ids = create_patient_id(
    n = 400, pattern = "numeric", sequential = TRUE, 
    prefix = format(Sys.Date(), format = "%Y")
  ),
  tar_target(
    name = patient_list,
    command = create_patient_list(
      ids = patient_ids, language = "Creole (cpf)", 
      choice_filter = c(
        rep("nurse01", 50), rep("nurse02", 50), 
        rep("nurse03", 50), rep("nurse04", 50),
        rep("nurse05", 50), rep("nurse6", 50), 
        rep("nurse07", 50), rep("nurse08", 50)
      ),
      choice_filter_label = "enumerator"
    )
  ),
  tar_target(
    name = patient_list_search,
    command = create_patient_list(
      ids = patient_ids, language = "Creole (cpf)",
      choice_filter = c(
        rep("nurse01", 50), rep("nurse02", 50), 
        rep("nurse03", 50), rep("nurse04", 50),
        rep("nurse05", 50), rep("nurse06", 50), 
        rep("nurse07", 50), rep("nurse08", 50)
      ),
      name_key = TRUE,
      choice_filter_label = "enumerator"
    )
  )
)

### KoboToolbox forms targets ----
form_targets <- tar_plan(
  ## Specify One Drive directories for forms ----
  onedrive_forms_directory = "sc_onco_facility_study/questionnaire/xlsform",
  onedrive_patient_form_file = file.path(
    onedrive_forms_directory, "onco_patient_questionnaire.xlsx"
  ),
  onedrive_hcw_form_file = file.path(
    onedrive_forms_directory, "onco_hcw_questionnaire.xlsx"
  ),
  onedrive_media_form_directory = file.path(onedrive_forms_directory, "media"),
  
  ## KoboToolbox forms ----
  kobo_form_list = kobo_asset_list(),
  
  ### KoboToolbox patient forms ----
  kobo_patient_form_id = kobo_get_uid(
    asset_list = kobo_form_list, form_name = "Oncology Unit Patient Survey 2025"
  ),
  tar_target(
    name = kobo_patient_form_version_list,
    command = robotoolbox::kobo_asset(kobo_patient_form_id) |>
      robotoolbox::kobo_asset_version_list(),
    cue = tar_cue("always")
  ),
  tar_target(
    name = kobo_patient_form_version_urls,
    command = kobo_get_version_urls(kobo_patient_form_version_list),
    cue = tar_cue("always")
  ),

  ### KoboTooblox healthcare worker forms ----
  kobo_hcw_form_id = kobo_get_uid(
    asset_list = kobo_form_list, 
    form_name = "Oncology Unit Patient Survey 2025 - Part B"
  ),
  tar_target(
    name = kobo_hcw_form_version_list,
    command = robotoolbox::kobo_asset(kobo_hcw_form_id) |>
      robotoolbox::kobo_asset_version_list(),
    cue = tar_cue("always")
  ),
  tar_target(
    name = kobo_hcw_form_version_urls,
    command = kobo_get_version_urls(kobo_hcw_form_version_list),
    cue = tar_cue("always")
  )
)


### Processing targets
processing_targets <- tar_plan(
  
)


### Analysis targets
analysis_targets <- tar_plan(
  
)


### Output targets
output_targets <- tar_plan(
  ## CSV file of patient list ----
  tar_target(
    name = patient_list_csv,
    command = write_patient_list(patient_list_search),
    format = "file"
  ),

  ## Archive of Kobotoolbox patient form versions ----
  tar_target(
    name = kobo_patient_form_version_xls,
    command = kobo_archive_form_versions(
      kobo_patient_form_version_urls, 
      form_title = "Oncology Unit Patient Survey 2025",
      directory = "forms/archive/patient",
      file_name = "onco_patient_questionnaire.xls"
    ),
    pattern = map(kobo_patient_form_version_urls),
    format = "file"
  ),

  ## Archive of Kobotoolbox healthcare worker form versions ----
  tar_target(
    name = kobo_hcw_form_version_xls,
    command = kobo_archive_form_versions(
      kobo_hcw_form_version_urls, 
      form_title = "Oncology Unit Patient Survey 2025 - Part B",
      directory = "forms/archive/hcw",
      file_name = "onco_hcw_questionnaire.xls"
    ),
    pattern = map(kobo_hcw_form_version_urls),
    format = "file"
  )
)


### Reporting targets
report_targets <- tar_plan(
  
)


### Deploy targets
deploy_targets <- tar_plan(
  
)


## List targets
all_targets()
