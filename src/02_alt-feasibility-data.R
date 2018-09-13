# feasibility data for QI project looking at heparin dosing in trauma patients

library(tidyverse)
library(edwr)

dir_raw <- "data/raw/mpp"

# run MBO query
#   * Patients - by Order - Location
#       - Facility (Curr): HH HERMANN
#       - Admit Date: 8/1/18 - 9/1/18
#       - Mnemonic (Primary Generic) FILTER ON: CDM Heparin Weight Based Orders Deep Vei;CDM Anti-Xa-Heparin Weight Based DVT and
#       - Nurse Unit (Order): HH STIC;HH S1MU

pts <- read_data(dir_raw, "patients", FALSE) %>%
    as.patients()

mbo_id <- concat_encounters(pts$millennium.id)

# run MBO queries
#   * Labs - Coags
#   * Medications - Inpatient - Prompt
#       - Medication (Generic): heparin

drips <- read_data(dir_raw, "meds-inpt", FALSE) %>%
    as.meds_inpt() %>%
    filter(
        route != "SUB-Q"
        # med.location == "HH STIC"
    ) %>%
    # filter(!is.na(event.tag)) %>%
    arrange(millennium.id, med.datetime)

fixed <- drips %>%
    filter(med.rate.units == "unit/hr") %>%
    distinct(millennium.id)

include <- drips %>%
    distinct(millennium.id) %>%
    anti_join(fixed, by = "millennium.id")

data_bolus <- drips %>%
    filter(is.na(event.tag))

labs <- read_data(dir_raw, "labs", FALSE) %>%
    as.labs() %>%
    tidy_data() %>%
    semi_join(include, by = "millennium.id")

heparin <- drips %>%
    semi_join(include, by = "millennium.id") %>%
    calc_runtime() %>%
    summarize_data()

first_rate <- drips %>%
    semi_join(include, by = "millennium.id") %>%
    arrange(millennium.id, med.datetime) %>%
    filter(!is.na(med.rate.units)) %>%
    distinct(millennium.id, .keep_all = TRUE)

data_ptt <- labs %>%
    filter(lab == "ptt") %>%
    left_join(
        heparin[c("millennium.id", "start.datetime", "stop.datetime")],
        by = "millennium.id"
    ) %>%
    filter(
        lab.datetime >= start.datetime,
        lab.datetime <= stop.datetime
    ) %>%
    mutate(time.hr = difftime(lab.datetime, start.datetime, units = "hours"))

data_rates <- drips %>%
    semi_join(include, by = "millennium.id") %>%
    filter(!is.na(med.rate.units))

data_heparin <- data_rates %>%
    calc_runtime() %>%
    summarize_data()

data_patients <- pts %>%
    semi_join(include, by = "millennium.id")

dirr::save_rds("data/tidy/mpp", "data_")
