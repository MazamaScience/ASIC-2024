# 02_AirSensor2_recipes.R
#
# This script contains small chunks of R code (aka "recipes") that demonstrate
# how to work with the AirSensor2 package to access, manipulate and display
# sensor data available through the PurpleAir API.
#
# This script assumes that you have already installed the following packages:
#  - AirMonitor
#  - AirSensor2

# Check that the AirMonitor package is recent enough
if ( packageVersion("AirMonitor") < "0.4.0" ) {
  stop("VERSION_ERROR:  Please upgrade to AirMonitor 0.4.0 or later.")
}

# Check that the Sensor2 package is recent enough
if ( packageVersion("AirSensor2") < "0.5.0" ) {
  stop("VERSION_ERROR:  Please upgrade to AirSensor2 0.5.0 or later.")
}

# Check that the working directory is set properly
if ( !stringr::str_detect(getwd(), "ASIC-2024/R_workshop$") ) {
  stop("WD_ERROR:  Please set the working directory to 'ASIC-2024/R_workshop/'")
}

# Open reference docs in a web browser
browseURL("http://mazamascience.com/presentations/2022/ASIC_Universal_Data_Structures.pdf")
browseURL("https://mazamascience.github.io/AirSensor2/reference/index.html")

library(AirSensor2)

# Set up spatial data from default directories
initializeMazamaSpatialUtils()

# ----- API Keys ---------------------------------------------------------------

# Read in secret PurpleAir_API_READ_KEY
source("global_vars.R")

# Check the key
PurpleAir_checkAPIKey(PurpleAir_API_READ_KEY)

# ----- PurpleAir Synoptic (PAS) -----------------------------------------------

# We need to access and enhance sensor metadata before we download the
# timeseries data needed to make a 'monitor' object.

# Metadata and current data (many fields)
PurpleAir_DATA_AVG_PM25_FIELDS

# Split up field names
PurpleAir_DATA_AVG_PM25_FIELDS %>%
  stringr::str_split(",") %>%
  print(width = 75)

# Metadata only field names
PurpleAir_SENSOR_METADATA_FIELDS  %>%
  stringr::str_split(",") %>%
  print(width = 75)

# * pas_createNew() -----

# Create a metadata only PAS for identifying historical sensors
pas <-
  pas_createNew(
    api_key = PurpleAir_API_READ_KEY,
    fields = PurpleAir_SENSOR_METADATA_FIELDS,
    countryCodes = "US",
    stateCodes = "WA",
    counties = "Okanogan",
    lookbackDays = 365 * 10,     # 10 years
    location_type = 0            # Outdoor only
  )

# New fields have been added
print(names(pas), width = 75)

# Some are empty
unique(pas$elevation)

# NOTE:  To add address and elevation information see:
# NOTE:  - MazamaLocationUtils::location_getSingleAddress_Photon()
# NOTE:  - MazamaLocationUtils::location_getSingleElevation_USGS()

# * lifespanPlot() -----

pas %>%
  pas_lifespanPlot()

# Review the names
pas %>%
  dplyr::pull(locationName) %>%
  sort()

# * MVCAA lifespans -----

# Look at Methow Valley Clean Air Ambassador sites
pas %>%
  dplyr::filter(stringr::str_detect(locationName, "Ambassador")) %>%
  pas_lifespanPlot(
    showSensor = TRUE,
    sensorIdentifier = "locationName",
    cex = 0.8,
    lwd = 2,
    moreSpace = .5
  )

# Arranged by lifespan
pas %>%
  dplyr::filter(stringr::str_detect(locationName, "Ambassador")) %>%
  dplyr::mutate(lifespan = last_seen - date_created) %>%
  dplyr::arrange(lifespan) %>%
  pas_lifespanPlot(
    showSensor = TRUE,
    sensorIdentifier = "locationName",
    cex = 0.8,
    lwd = 2,
    moreSpace = .5
  )

# * lifespan histogram -----

# For dead sensors, show the range of lifespans in months
pas %>%
  dplyr::filter(last_seen < (max(last_seen) - lubridate::ddays(30))) %>%
  dplyr::mutate(
    lifespan = as.numeric(difftime(last_seen, date_created, units = "days")) / 30
  ) %>%
  dplyr::pull(lifespan) %>%
  hist(
    n = 20,
    las = 1,
    main = "Dead Sensor Reporting Lifespans",
    ylab = "count of sensors",
    xlab = "Months"
  )

# * all Washington pas -----

# All sensors in Washington state (from pre-downloaded data)
pas_wa <- get(load("./data/example_pas_wa.rda"))

# Interactive map
pas_wa %>% pas_leaflet()

# All Washington histogram of dead sensor lifespans
pas_wa %>%
  dplyr::filter(last_seen < (max(last_seen) - lubridate::ddays(30))) %>%
  dplyr::mutate(
    lifespan = as.numeric(difftime(last_seen, date_created, units = "days")) / 30
  ) %>%
  dplyr::pull(lifespan) %>%
  hist(
    n = 20,
    las = 1,
    main = "Washington Dead Sensor Reporting Lifespans",
    ylab = "count of sensors",
    xlab = "Months"
  )

# ----- PurpleAir Timeseries (PAT) ---------------------------------------------

