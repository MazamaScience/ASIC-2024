# AirMonitor_recipes.R
#
# This script contains small chunks of R code (aka "recipes") that demonstrate
# how to work with the AirMonitor package to access, manipulate and display
# regulatory monitoring data from the USFS maintained archives of pre-processed
# AirNow monitoring data.
#
# This script assumes that you have already installed the following packages:
#  - AirMonitor
#  - AirMonitorPlots

library(AirMonitor)

# Open reference docs in a web browser
browseURL("https://mazamascience.github.io/AirMonitor/reference/index.html")

# ----- Examine 'mts_monitor' object -------------------------------------------

# Recipe to load most recent 10 days of hourly PM2.5 data

# To make a "monitor" object:
monitor <-
  # Step 1) load data
  airnow_loadLatest()

# This is a compact data format. The Environment tab shows it at ~5 MB

# This object is an R list containing 2 dataframes: 'meta' and 'data'
class(monitor)
names(monitor)

# 'meta' contains N metadata records (device-deployments) with 54 fields
dim(monitor$meta)

dplyr::glimpse(monitor$meta, width = 75)

View(monitor$data)

# 'data' contains hourly records for N device-deployments + the 'datetime' field
dim(monitor$data)

dplyr::glimpse(monitor$data[1:5,1:10])

# 'data' columns match 'meta' rows
all(names(monitor$data) == c('datetime', monitor$meta$deviceDeploymentID))

# IMPORTANT:  Compact data format relies on separating data and metadata

# ----- Maps and filtering -----------------------------------------------------

# All sites
# start with the monitor object
monitor %>%
  # Step 1) create a leaflet map
  monitor_leaflet()

# CONUS
# start with the monitor object
monitor %>%
  # Step 1) filter by state
  monitor_filter(stateCode %in% CONUS) %>%
  # Step 2) create a leaflet map
  monitor_leaflet()

# California
monitor %>%
  monitor_filter(stateCode == "CA") %>%
  monitor_leaflet()

# Which counties have monitors?
monitor %>%
  monitor_filter(stateCode == "CA") %>%          # filter by state
  monitor_getMeta() %>%                          # get 'meta' dataframe
  dplyr::pull(countyName) %>%                    # pull 'countyName'
  ###monitor_pull(countyName) %>%                   # pull 'countyName'
  table() %>%
  sort(decreasing = TRUE)

# Riverside County
monitor %>%
  monitor_filter(stateCode == "CA") %>%
  monitor_filter(countyName == "Riverside") %>%
  monitor_leaflet()

# ----- Time series ------------------------------------------------------------

# All monitors in Riverside County
# To make the "riverside" object
riverside <-
  # Step 1) start with the "monitor" object
  monitor %>%
  # Step 2) filter by state
  monitor_filter(stateCode == "CA") %>%
  # Step 3) filter by county
  monitor_filter(countyName == "Riverside")

nrow(riverside$meta)

# Riverside time series plot
riverside %>%
  monitor_timeseriesPlot()

# Timeseries plot with extras
riverside %>%
  monitor_timeseriesPlot(
    shadedNight = TRUE,
    addAQI = TRUE
  )

# Select a single monitor
riverside %>%
  monitor_leaflet()

# Click on map to get the deviceDeploymentID

# Single monitor
rubidoux <-
  riverside %>%
  monitor_select("c7cc2b21d9f11f15_840060658001")

# ----- Fancy timeseries plot --------------------------------------------------

rubidoux %>%
  monitor_timeseriesPlot(
    shadedNight = TRUE,
    addAQI = TRUE,
    pch = 16,
    col = 'gray70',
    main = "Air Quality at Rubidoux"
  )

# Add NowCast
rubidoux %>%
  monitor_nowcast(
    includeShortTerm = TRUE
  ) %>%
  monitor_timeseriesPlot(
    add = TRUE,
    type = 'l',
    lwd = 2,
    col = "gray10"
  )

# Add a legend
legend(
  "topleft",
  legend = c("Hourly PM2.5", "NowCast"),
  col = c("gray70", "gray10"),
  pch = c(16, NA),
  lwd = c(NA, 2)
)

# ----- Annual data ------------------------------------------------------------

# Load all of 2020 for all monitors
monitor <-
  airnow_loadAnnual(2020)

# NOTE:  ~160 MB for an entire year!

monitor %>%
  monitor_timeRange()

# Map
monitor %>%
  monitor_leaflet()

# Washington state during fire season
wa <-
  monitor %>%
  monitor_filter(stateCode == "WA") %>%
  monitor_filterDate("2020-07-01", "2020-11-01")

# Timeseries
wa %>%
  monitor_timeseriesPlot()

# Narrow down to mid September

# Mid-September
wa <-
  wa %>%
  monitor_filterDate(
    startdate = "2020-09-07",
    enddate = "2020-09-21",
    timezone = "America/Los_Angeles"
  )

wa %>%
  monitor_timeseriesPlot(
    shadedNight = TRUE,
    addAQI = TRUE
  )
addAQILegend()


# ----- Advanced recipes -------------------------------------------------------

# Where was HAZARDOUS encountered?

# Check US_AQI object
US_AQI$names_eng
US_AQI$breaks_PM2.5

# Hazardous starts at 250.5 ug/m3
threshold <- US_AQI$breaks_PM2.5[6]

# Map of locations that experienced HAZARDOUS
wa %>%
  monitor_selectWhere(
    function(x) { any(x >= threshold, na.rm = TRUE) }
  ) %>%
  monitor_leaflet()

# THE ENTIRE STATE!

# Let's look at Omak

omak <-
  wa %>%
  monitor_select("e5d75388f0cfcbf6_530470013")

# Plot time series for Omak
omak %>%
  monitor_timeseriesPlot(
    shadedNight = TRUE,
    addAQI = TRUE,
    type = 'b'
  )
addAQILegend(
  "topright",
  title = "PM2.5 (\u00b5g/m3)"                   # Unicode 00b5 is the "micro sign"
)

# Plot daily averages for Omak
omak %>%
  monitor_dailyBarplot(
    minHours = 18,
    dayBoundary = "LST"
  )
addAQILegend("topright")

# Print daily max for Omak
omak %>%
  monitor_dailyStatistic(
    FUN = max,
    minHours = 18,
    dayBoundary = "LST"
  ) %>%
  monitor_getData() %>%
  print()

# Washington state daily averages
wa %>%
  monitor_collapse(
    FUN = mean
  ) %>%
  monitor_dailyBarplot(
    main = "Washington State daily average PM2.5"
  )


