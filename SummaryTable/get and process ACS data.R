# ==================================================================================================================================================
# Dr. Michael Samuel and Jaspreet Kang, CDPH Fusion Center
# October 13, 2022
# For any questions, please email us at ccb@cdph.ca.gov

# About this script --------
# This script uses the `tidycensus` R package to extract American Community Survey data via the Census API.

## Requirements -------------
# 1. R packages (To install packages, execute `install.packages("PACKAGE_NAME")`. To load packages into session, execute `library(PACKAGE_NAME)`)
#     a) tidycensus
#     b) dplyr
# 2. Census API key (sign up for key here: https://api.census.gov/data/key_signup.html)

## Outputs ------------------
# 1. County population totals
# 2. Zip Code Tabulation Area (ZCTA) population totals
# 3. Census Tract population totals
# 4. County population by Race/Ethnicity

## About tidycensus ---------
# Tidycensus is a package built for R users to extract Census data at multiple geography levels.
# Getting Census data from tables requires knowing variable IDs, and there are multiple ways to search for these. One way is using the tidycensus `load_variables()` function. Execute `?load_variables` to view the documentation of this function.
# Link to tidycensus documentation: https://walker-data.com/tidycensus/

## ACS tables and variables pulled in this script -----------
# 1. Table B01001 - https://data.census.gov/cedsci/table?q=b01001&tid=ACSDT5Y2019.B01001
#     a) B01001_001 - Total population
# 2. Table B03002 - https://data.census.gov/cedsci/table?q=b03002&tid=ACSDT5Y2019.B03002
#     a) B03002_003 - White, Non-Hispanic
#     b) B03002_004 - Black, Non-Hispanic
#     c) B03002_005 - AI/AN, Non-Hispanic
#     d) B03002_006 - Asian, Non-Hispanic
#     e) B03002_007 - NH/PI, Non-Hispanic
#     f) B03002_008 - Other, Non-Hispanic
#     g) B03002_009 - Multi-Race, Non-Hispanic
#     h) B03002_012 - Hispanic

# ==================================================================================================================================================


# Load R Packages --------------------------------------------------------------------------------------------------------

library(tidycensus)
library(dplyr)

# Load Census API Key ----------------------------------------------------------------------------------------------------

census_api_key("INSERT CENSUS KEY HERE")
census_api_key("e7c1ee99540a164fe0ae8966b9ffcc3b64790aa7")

# Settings for pulling ACS data ------------------------------------------------------------------------------------------

ACS_SURVEY <- "acs5" # Survey to extract data from; acs5 = American Community Survey 5-Year
ACS_YEAR   <- 2019   # Year of survey; 2015-2019
ACS_STATE  <- 06     # California
ACS_MOE    <- 90     # Margin of error; Set to 90%

# Extract County population totals ------------------------------------------------------------------------------------------

countyPop <- get_acs(state = ACS_STATE, geography = "county", year = ACS_YEAR, survey = ACS_SURVEY, moe_level = ACS_MOE, 
                     variables = "B01001_001", summary_var = "B01001_001") # Note: this data frame will have two identical columns with the total population numbers

# Extract ZCTA population totals ------------------------------------------------------------------------------------------

# zip code data must be extracted for whole country, not a selected state
zctaPop <- get_acs(state = ACS_STATE, geography = "zcta", year = ACS_YEAR, survey = ACS_SURVEY, moe_level = ACS_MOE, 
                   variables = "B01001_001", summary_var = "B01001_001") # Note: this data frame will have two identical columns with the total population numbers

zctaPop <- zctaPop %>% 
              mutate(zip   = substring(GEOID,3,9)) 

# Extract Census Tract population totals ------------------------------------------------------------------------------------------

tractPop <- get_acs(state = ACS_STATE, geography = "tract", year = ACS_YEAR, survey = ACS_SURVEY, moe_level = ACS_MOE, 
                     variables = "B01001_001", summary_var = "B01001_001") # Note: this data frame will have two identical columns with the total population numbers

# Extract County population by Race/Ethnicity ------------------------------------------------------------------------------------------

# ACS Variable IDs for Race/Ethnicuty population data
raceIDs   <- c("B03002_003", "B03002_004", "B03002_005",                    "B03002_006", "B03002_007",                       "B03002_008", "B03002_009", "B03002_012")
raceNames <- c("White",      "Black",      "American Indian/Alaska Native", "Asian",      "Native Hawaiian/Pacific Islander", "Other",      "Multi-Race", "Latino")

# Creating a data frame that links the ACS variable IDs to Race/Ethnicity names
raceLink <- data.frame(raceID = raceIDs, raceName = raceNames, stringsAsFactors = FALSE)

# Pull county-level Race/Ethnicity population data
countyPop_RE <- get_acs(state = ACS_STATE, geography = "county", year = ACS_YEAR, survey = ACS_SURVEY, moe_level = ACS_MOE, 
                        variables = raceIDs, summary_var = "B03002_001") %>% 
  left_join(raceLink, by = c("variable" = "raceID")) # Bring in Race/Ethnicity names


# Save data ---------------------------------------------------------------------------------------------------------------------------

write.csv(countyPop,    file = "data_out/CA County Population.csv", row.names = FALSE)
write.csv(countyPop_RE, file = "data_out/CA County Race-Ethnicity Population.csv", row.names = FALSE)
write.csv(zctaPop,      file = "data_out/CA Zip Population.csv", row.names = FALSE)
write.csv(tractPop,     file = "data_out/CA Tract Population.csv", row.names = FALSE)
