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
library(AirMonitorPlots)

# ----- Examine 'mts_monitor' object -------------------------------------------

# Recipe to load most recent 10 days of hourly PM2.5 data
latest <-
  airnow_loadLatest()

# This is a compact data format. The Environment tab shows it at ~5 MB

# This object is an R list containing 2 dataframes: 'meta' and 'data'
class(latest)
names(latest)

# 'meta' contains N metadata records (device-deployments) with 54 fields
dim(latest$meta)

dplyr::glimpse(latest$meta, width = 75)

# 'data' contains hourly records for N device-deployments + the 'datetime' field
dim(latest$data)

dplyr::glimpse(latest$data[1:5,1:10])

# 'data' columns match 'meta' rows
all(names(latest$data) == c('datetime', latest$meta$deviceDeploymentID))

# NOTE:  Compact data format relies on separating data and metadata

# ----- Maps and filtering -----------------------------------------------------

# All sites
latest %>%
  monitor_leaflet()

# CONUS
latest %>%
  monitor_filter(stateCode %in% CONUS) %>%       # filter by state
  monitor_leaflet()

# California
latest %>%
  monitor_filter(stateCode == "CA") %>%
  monitor_leaflet()

# Which counties have monitors?
latest %>%
  monitor_filter(stateCode == "CA") %>%          # filter by state
  monitor_getMeta() %>%                          # get 'meta' dataframe
  dplyr::pull(countyName) %>%                    # pull 'countyName'
  ###monitor_pull(countyName) %>%                   # pull 'countyName'
  table() %>%
  sort(decreasing = TRUE)

# Riverside County
latest %>%
  monitor_filter(stateCode == "CA") %>%
  monitor_filter(countyName == "Riverside") %>%
  monitor_leaflet()

# ----- Time series ------------------------------------------------------------

# All monitors in Riverside County
riverside <-
  latest %>%
  monitor_filter(stateCode == "CA") %>%
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

# Timeseries plot
rubidoux %>%
  monitor_timeseriesPlot(
    shadedNight = TRUE,
    addAQI = TRUE,
    type = 'b',
    pch = 16
  )


