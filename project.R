# Install and load necessary libraries
install.packages(c("tidyverse", "tseries", "forcats"))
# Load necessary libraries
library(tidyverse)
library(forecast)
library(tseries)

# Read the dataset
data_new <- read.csv("results.csv")

# Ensure 'date' is in Date format
data_new$date <- as.Date(data_new$date)

# Convert home_score and away_score to numeric, if not already
data_new$home_score <- as.numeric(data_new$home_score)
data_new$away_score <- as.numeric(data_new$away_score)

# Create a new column for the year
data_new$year <- format(data_new$date, "%Y")

# Filter for the specific team (e.g., "England")
team_name <- "England"

# Aggregate the goals scored by the team per year
home_goals <- data_new %>%
  filter(home_team == team_name) %>%
  group_by(year) %>%
  summarise(goals_scored = sum(home_score, na.rm = TRUE))

away_goals <- data_new %>%
  filter(away_team == team_name) %>%
  group_by(year) %>%
  summarise(goals_scored = sum(away_score, na.rm = TRUE))

# Combine the goals scored at home and away for each year
total_goals_scored <- full_join(home_goals, away_goals, by = "year") %>%
  mutate(total_goals = goals_scored.x + goals_scored.y) %>%
  select(year, total_goals)

# Remove rows with missing values (NA) in 'total_goals'
total_goals_scored <- na.omit(total_goals_scored)

# Convert to a time series object
ts_data <- ts(total_goals_scored$total_goals, start = min(as.numeric(total_goals_scored$year)), frequency = 1)

# Plot the time series data to inspect the trend
plot(ts_data, main = paste("Goals Scored by", team_name), ylab = "Goals Scored", xlab = "Year", col = "blue", type = "o")

# Check if the time series is stationary using the Augmented Dickey-Fuller test
adf_test <- adf.test(ts_data)
cat("ADF Test p-value:", adf_test$p.value, "\n")

# If the series is non-stationary, apply differencing
if (adf_test$p.value > 0.05) {
  cat("The series is non-stationary. Applying differencing...\n")
  ts_data <- diff(ts_data)
  plot(ts_data, main = "Differenced Goals Scored", ylab = "Differenced Goals", xlab = "Year", col = "red", type = "o")
  
  # Re-run the ADF test on the differenced series
  adf_test_diff <- adf.test(ts_data)
  cat("ADF Test on differenced series p-value:", adf_test_diff$p.value, "\n")
}

# Plot ACF and PACF to determine the appropriate order for ARIMA model
acf(ts_data, main = "ACF of Goals Scored")
pacf(ts_data, main = "PACF of Goals Scored")

# Fit an ARIMA model based on ACF/PACF plots
arima_model <- auto.arima(ts_data)
summary(arima_model)

# Forecast future values (next 5 periods)
forecast_values <- forecast(arima_model, h = 5)

# Print the forecasted values
print(forecast_values)

# Plot the forecasted values
plot(forecast_values, main = paste("Forecast of Goals Scored by", team_name), ylab = "Goals Scored", xlab = "Year")

# Model diagnostics: Check residuals for patterns
checkresiduals(arima_model)

# Optionally, you can plot residuals and conduct further analysis
residuals <- residuals(arima_model)
hist(residuals, main = "Residuals Histogram", xlab = "Residuals")

# Plot the residuals
plot(residuals, main="Residuals of the ARIMA Model")
abline(h=0, col="red")
