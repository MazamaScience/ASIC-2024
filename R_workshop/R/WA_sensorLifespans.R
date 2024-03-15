# Washginton state PA lifespans

library(AirSensor2)

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

# -----

layout(matrix(seq(3)))

# -----

wa_dead %>%
  dplyr::pull(lifespan) %>%
  hist(
    breaks = seq(0,84,3),
    main = "",
    ylab = "# of sensors",
    xlab = "Months",
    axes = FALSE
  )

mtext(sprintf("Lifespan of %d \"dead\" PurpleAir Sensors in Washington state", nrow(wa_dead)), line = 2, font = 2)
mtext(sprintf("(sensors that stopped reporting more than 30 days ago)"), line = 0)

axis(1, at = seq(0, 84, 12))
axis(2, las = 1)

# -----

wa_live %>%
  dplyr::pull(lifespan) %>%
  hist(
    breaks = seq(0, 84, 3),
    main = "",
    ylab = "# of sensors",
    xlab = "Months",
    axes = FALSE
  )

mtext(sprintf("Age of %d \"still-reporting\" PurpleAir Sensors in Washington state", nrow(wa_live)), line = 2, font = 2)
mtext(sprintf("(sensors that reported with the last 30 days)"), line = 0)

axis(1, at = seq(0, 84, 12))
axis(2, las = 1)

# -----

wa %>%
  dplyr::pull(lifespan) %>%
  hist(
    breaks = seq(0,84,3),
    main = "",
    ylab = "# of sensors",
    xlab = "Months",
    axes = FALSE
  )

mtext(sprintf("Lifespan/Age for all %d PurpleAir Sensors in Washington state", nrow(wa)), line = 2, font = 2)
mtext(sprintf("(includes \"dead\" and \"still-reporting\" sensors)"), line = 0)

axis(1, at = seq(0, 84, 12))
axis(2, las = 1)


layout(1)

# ==============================================================================

# Timeseries plot of % still reporting for each age class

pctStillReportingList = list()
sensorCountTextList = list()

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

}

pctStillReporting <- unlist(pctStillReportingList)
sensorCountText <- unlist(sensorCountTextList)

# NOTE:  barplot docs say 'space' defaults to 0.2
barplot(pctStillReporting, ylim = c(0, 110), las = 1, space = 0.2)

text(1:8 * 1.2 - 0.5, pctStillReporting, sensorCountText, pos = 3, cex = 0.8)

mtext(sprintf("Percentage of Washington state PurpleAir Sensors still reporting"), line = 2, font = 2)


