# 02_AirSensor2_PAS recipes.R
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

# Check that the MazamaSpatialUtils package is recent enough
if ( packageVersion("MazamaSpatialUtils") < "0.8.6" ) {
  browseURL("https://github.com/MazamaScience/ASIC-2024/tree/main/R_workshop#spatial-data")
  stop("VERSION_ERROR:  Please upgrade to MazamaSpatialUtils 0.8.6 or later.")
}

# Check that the working directory is set properly
if ( !stringr::str_detect(getwd(), "R_workshop$") ) {
  stop("WD_ERROR:  Please set the working directory to 'R_workshop/'")
}

# Open reference docs in a web browser
browseURL("https://api.purpleair.com/#api-sensors-get-sensors-data")
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
PurpleAir_PAS_AVG_PM25_FIELDS

# Split up field names
PurpleAir_PAS_AVG_PM25_FIELDS %>%
  stringr::str_split(",") %>%
  print(width = 75)

# Metadata only field names
PurpleAir_PAS_MINIMAL_FIELDS  %>%
  stringr::str_split(",") %>%
  print(width = 75)

# Metadata only field names
PurpleAir_PAS_METADATA_FIELDS  %>%
  stringr::str_split(",") %>%
  print(width = 75)

# ----- Maps -------------------------------------------------------------------

if ( FALSE ) {

  # This is how example_pas_pm25 was created:
  example_pas_pm25 <-
    pas_createNew(
      api_key = PurpleAir_API_READ_KEY,
      fields = PurpleAir_PAS_AVG_PM25_FIELDS,
      countryCodes = "US",
      stateCodes = c("WA", "OR"),
      counties = NULL,
      lookbackDays = 1,
      location_type = 0
    )

}

pas <- example_pas_pm25

# It's a dataframe
class(pas)

# New fields have been added
pas %>%
  names() %>%
  print(width = 75)

# Some are empty
unique(pas$houseNumber)

# NOTE:  To add address information see:
# NOTE:    MazamaLocationUtils::location_getSingleAddress_Photon()

# Basic map
pas %>%
  pas_leaflet()

# * PM2.5 -----
pas %>%
  pas_leaflet(
    parameter = "pm2.5_24hour"
  )

# * humidity -----
pas %>%
  pas_leaflet(
    parameter = "humidity"
  )

# * other maps -----
pas %>%
  pas_leaflet(
    parameter = "confidence"
  )

pas %>%
  dplyr::mutate(
    lack_of_confidence = 100 - confidence
  ) %>%
  pas_leaflet(
    parameter = "lack_of_confidence"
  )

pas %>%
  dplyr::mutate(
    lifespan = as.numeric(difftime(last_seen, date_created, units = "days"))
  ) %>%
  pas_leaflet(
    parameter = "lifespan"
  )

# ----- Historical data --------------------------------------------------------

if ( FALSE ) {

  example_pas_historical <-
    pas_createNew(
      api_key = PurpleAir_API_READ_KEY,
      fields = PurpleAir_PAS_MINIMAL_FIELDS,
      countryCodes = "US",
      stateCodes = "WA",
      counties = "Okanogan",
      lookbackDays = 0,            # all years
      location_type = 0            # outdoor only
    )

}

pas <- example_pas_historical

# Fields
pas %>%
  names() %>%
  print(width = 75)

nrow(pas)

# Where are they?
pas %>%
  pas_leaflet()

# * lifespans -----

pas %>%
  pas_lifespanPlot()

# Review the names
pas %>%
  dplyr::pull(locationName) %>%
  sort()

# * MVCAA lifespans -----

# Look at Methow Valley Clean Air Ambassador sites
pas %>%
  dplyr::filter(stringr::str_detect(locationName, "bassador")) %>%
  pas_lifespanPlot(
    showSensor = TRUE,
    sensorIdentifier = "locationName",
    cex = 0.8,
    lwd = 2,
    moreSpace = .5
  )

# Arranged by lifespan
pas %>%
  dplyr::filter(stringr::str_detect(locationName, "bassador")) %>%
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

# Show the range of lifespans in months
pas %>%
  dplyr::mutate(
    lifespan = as.numeric(difftime(last_seen, date_created, units = "days")) / 30
  ) %>%
  dplyr::pull(lifespan) %>%
  hist(
    n = 20,
    las = 1,
    main = "Sensor Reporting Lifespans",
    ylab = "count of sensors",
    xlab = "Months"
  )

# ----- all Washington lifespan histogram --------------------------------------

# All sensors in Washington state (from pre-downloaded data)
wa <-
  get(load("./data/example_pas_wa.rda")) %>%
  dplyr::mutate(
    lifespan = as.numeric(difftime(last_seen, date_created, units = "days")) / 30,
    stillReporting = as.logical(last_seen >= (max(last_seen) - lubridate::ddays(30)))
  )

wa_dead <-
  wa %>%
  dplyr::filter(last_seen < (max(last_seen) - lubridate::ddays(30)))

wa_live <-
  wa %>%
  dplyr::filter(last_seen >= (max(last_seen) - lubridate::ddays(30)))

pctStillReportingList = list()
sensorCountTextList = list()
sensorPercentTextList = list()

for ( year in 2017:2024 ) {

  start <- sprintf("%d-01-01", year)
  end <- sprintf("%d-01-01", year + 1)

  deadCount <-
    wa_dead %>%
    pas_filterDate(start, end, timezone = "America/Los_Angeles") %>%
    nrow()

  liveCount <-
    wa_live %>%
    pas_filterDate(start, end, timezone = "America/Los_Angeles") %>%
    nrow()

  pctStillReportingList[[as.character(year)]] <- round(100 * liveCount / (deadCount + liveCount))

  sensorCountTextList[[as.character(year)]] <-
    sprintf("%d/%d", liveCount, (deadCount + liveCount))
  sensorPercentTextList[[as.character(year)]] <-
    sprintf("%d%%", round(100 * liveCount/ (deadCount + liveCount)))

}

pctStillReporting <- unlist(pctStillReportingList)
sensorCountText <- unlist(sensorCountTextList)
sensorPercentText <- unlist(sensorPercentTextList)

# NOTE:  barplot docs say 'space' defaults to 0.2
barplot(pctStillReporting, ylim = c(0, 110), las = 1, space = 0.2, xlab = "Deployment Year")

text(1:8 * 1.2 - 0.5, pctStillReporting, sensorPercentText, pos = 3, cex = 1.0)
text(1:8 * 1.2 - 0.5, pctStillReporting, sensorCountText, pos = 1, cex = 0.8)

mtext(sprintf("Percentage of Washington state PurpleAir Sensors still reporting"), line = 2, font = 2)

# ----- Metadata ---------------------------------------------------------------

if ( FALSE ) {

  example_pas_metadata <-
    pas_createNew(
      api_key = PurpleAir_API_READ_KEY,
      fields = PurpleAir_PAS_METADATA_FIELDS,
      countryCodes = "US",
      stateCodes = "WA",
      counties = "Okanogan",
      lookbackDays = 0,            # all years
      location_type = 0            # outdoor only
    )

}

pas <- example_pas_metadata

# Fields
pas %>%
  names() %>%
  print(width = 75)

nrow(pas)

# Where are they?
pas %>%
  pas_leaflet()

# Hardware info
pas %>%
  dplyr::pull(model) %>%
  table()

pas %>%
  dplyr::pull(position_rating) %>%
  table()

# From PurpleAir:
#   A 'star' rating of position accuracy. 0 stars is nowhere near the
#   claimed location whereas 5 stars is close to the map location as
#   indicated by the latitude and longitude values.

