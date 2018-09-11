# feasibility data for QI project looking at heparin dosing in trauma patients

library(tidyverse)
library(edwr)

dir_raw <- "data/raw"

# run MBO query
#   * Patients - by Medication (Generic) - Location
#       - Facility (Curr): HH HERMANN
#       - Admit Date: 8/1/18 - 9/1/18
#       - Medication (Generic): heparin
#       - Nurse Unit (Med): HH STIC

pts <- read_data(dir_raw, "patients", FALSE) %>%
    as.patients()

mbo_id <- concat_encounters(pts$millennium.id)

# run MBO queries
#   * Labs - Coags
#   * Medications - Inpatient - Prompt
#       - Medication (Generic): heparin

drips <- read_data(dir_raw, "meds-inpt", FALSE) %>%
    as.meds_inpt() %>%
    filter(!is.na(event.tag))

fixed <- drips %>%
    filter(med.rate.units == "unit/hr") %>%
    distinct(millennium.id)

include <- drips %>%
    distinct(millennium.id) %>%
    anti_join(fixed, by = "millennium.id")

labs <- read_data(dir_raw, "labs", FALSE) %>%
    as.labs() %>%
    tidy_data() %>%
    semi_join(include, by = "millennium.id")

data_heparin <- drips %>%
    semi_join(include, by = "millennium.id") %>%
    calc_runtime() %>%
    summarize_data()

data_ptt <- labs %>%
    filter(lab == "ptt") %>%
    left_join(
        data_heparin[c("millennium.id", "start.datetime", "stop.datetime")],
        by = "millennium.id"
    ) %>%
    filter(
        lab.datetime >= start.datetime,
        lab.datetime <= stop.datetime
    )

data_rates <- drips %>%
    semi_join(include, by = "millennium.id") %>%
    filter(!is.na(med.rate.units))

data_patients <- pts %>%
    semi_join(include, by = "millennium.id")

dirr::save_rds("data/tidy", "data_")
