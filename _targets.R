# Workflow for Open Data Kit form deployment -----------------------------------

## Load libraries and custom functions ----
suppressPackageStartupMessages(source("packages.R"))
for (f in list.files(here::here("R"), full.names = TRUE)) source (f)


## Set build options ----

### Set seed ----
set.seed(1977)

### Connect to One Drive ----
onedrive <- Microsoft365R::get_business_onedrive()


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
  onedrive_patient_form_path = "sc_onco_facility_study/questionnaire/xlsform/onco_patient_questionnaire.xlsx",
  onedrive_hcw_form_path = "sc_onco_facility_study/questionnaire/xlsform/onco_hcw_questionnaire.xlsx",
  onedrive_media_form_path = "sc_onco_facility_study/questionnaire/xlsform/media"
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
