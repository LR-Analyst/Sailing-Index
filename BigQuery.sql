/*
Source: NOAA GSOD Data
Prerequisite queries:
  1. Filtered weather stations by state to find appropriate station ID. 
  2. Combined trailing 30 years via Union All.
*/

WITH weather_metrics AS (
SELECT 
  concat(mo,'/',da) AS date, #Combine month and day from separate columns
  max_temp AS temp_F,
  CAST(mxpsd AS float64) AS max_wind_knots,
  (CASE WHEN rain_drizzle = '1' OR snow_ice_pellets = '1' OR hail = '1' OR thunder = '1' #Create new col signifying clement weather (1 is true)
    THEN 0 ELSE 1 END) AS clement_weather,
  (CASE WHEN CAST(mxpsd AS float64) <=16
    THEN -.015625 * POWER(CAST(mxpsd AS float64),2) + .25*CAST(mxpsd AS float64) ELSE 0 END) AS wind_index, #2nd-order function for wind desirability (scale of 0-1)
  (CASE WHEN (-.0025 * POWER(max_temp, 2) + .375 * max_temp -13) > 0
    THEN (-.0025 * POWER(max_temp, 2) + .375 * max_temp -13) ELSE 0 END) AS temp_index, #2nd-order func. for temp desirability (scale of 0-1)
  
FROM `sail-away-453618.Philadelphia_Airport_Weather.Weather_1995_to_2024`
)

SELECT
  date,
  AVG(temp_F) AS temp_F_avg,
  AVG(max_wind_knots) AS max_wind_kts_avg,
  AVG(clement_weather) AS clement_weather_index_avg,
  AVG(wind_index) AS wind_index_avg,
  AVG(temp_index) AS temp_index_avg,
  AVG(clement_weather * wind_index * temp_index) AS sailing_index,
FROM weather_metrics
GROUP BY date
ORDER BY date