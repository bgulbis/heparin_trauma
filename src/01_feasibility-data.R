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
