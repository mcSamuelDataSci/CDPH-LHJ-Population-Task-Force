# Documentation ===================================================================================================

# About: This file create relationship data frames which link Census Decennial table IDs (that have sex by age by race/ethnicity) 
# to their corresponding strata. Relationship data frames are created for 2000, 2010, and 2020 Census Decennial.

# Machine and R specs:
# R version 4.0.4 (2021-02-15)
# Platform: x86_64-pc-linz-gnu (64-bit)
# RStudio Workbench Version 1.4.1717-3: "Juliet Rose" (23fd1677, 2021-05-27) for CentOS 8

# Author: Jaspreet Kang, CDPH Office of Policy and Planning
# Date created: April 3rd, 2024
# Last modified: April 3rd, 2024

# Setup =================================================================

# Package versions:
# openxlsx - 4.2.5
# dplyr - 1.1.3
# tidycensus - 1.5

## Load packages 
library(openxlsx) # Write xlsx files
library(dplyr) # Data manipulation
library(tidycensus) # For interacting with Census API

# Census API Key: Set your API key here, which can be obtained from
# https://api.census.gov/data/key_signup.html
.ckey <- read_file("Standards/census.api.key.txt") 


# Pull Table IDs ========================================================

# From 2000, 2010, 2020 Census Decennial, pull table IDs for each Sex By Age by Race/Ethnicity strata
# - 2000 Census Decennial summary file 1 (sf1)
# - 2010 Census Decennial summary file  (sf1)
# - 2020 Census Decennial demographic and housing characteristcs (dhc)

## 2000
censusVars2000 <- tidycensus::load_variables(year = 2000, dataset = "sf1")

censusVars2000_total <- censusVars2000 %>% 
  filter(name == "P001001")

censusVars2000_race <- censusVars2000 %>% 
  filter(grepl("SEX BY AGE", concept)) %>% 
  filter(grepl("HISPANIC OR LATINO", concept)) %>% 
  filter(grepl("209", concept)) %>% 
  mutate(tableID = substr(name, 1, 7))

## 2010
censusVars2010 <- tidycensus::load_variables(year = 2010, dataset = "sf1")

censusVars2010_total <- censusVars2010 %>% 
  filter(name == "P001001")

censusVars2010_race <- censusVars2010 %>% 
  filter(grepl("SEX BY AGE [(]", concept)) %>% 
  filter(grepl("HISPANIC OR LATINO", concept)) %>% 
  filter(grepl("PCT", name)) %>% 
  mutate(tableID = substr(name, 1, 7))

## 2020
censusVars2020 <- tidycensus::load_variables(year = 2020, dataset = "dhc") 

censusVars2020_total <- censusVars2020 %>% 
  filter(name == "P1_001N")

censusVars2020_race <- censusVars2020 %>% 
  filter(grepl("SEX BY SINGLE-YEAR AGE [(]", concept)) %>% 
  filter(grepl("HISPANIC OR LATINO", concept)) %>% 
  mutate(tableID = substr(name, 1, 6))

# Custom Function to create a relationship data frame which links a table ID to its corresponding strata (sex by age by race/ethnicity) ==================================
createCensusLink <- function(myData) {
  
  tDat <- myData %>% 
    mutate(raceEth = case_when(grepl("WHITE", concept) ~ "White", 
                               grepl("BLACK", concept) ~ "Black", 
                               grepl("ALASKA", concept) ~ "AI/AN", 
                               grepl("ASIAN", concept) ~ "Asian", 
                               grepl("HAWAIIAN", concept) ~ "NH/PI", 
                               grepl("OTHER", concept) ~ "Other", 
                               grepl("TWO", concept) ~ "Multi-Race", 
                               TRUE ~ "Latino"), 
           sex = case_when(grepl("Female", label) ~ "Female", 
                           grepl("Male", label) ~ "Male", 
                           TRUE ~ "Total"))
  
  if (substr(tDat$label[1], 2, 2) == "!") {
    tDat <- tDat %>% 
      mutate(label = sub(".* [!][!]", "", label), 
             label = gsub("[:]", "", label))
  }
  
  tDat %>% 
    mutate(age = case_when(grepl("Under", label) ~ "0",
                           label %in% c("Total", "Total!!Male", "Total!!Female") ~ "Total", 
                           TRUE ~ gsub(".*ale[!][!](.+) year.*", "\\1", label)), 
           age = case_when(age %in% c("100 to 104", "105 to 109", "110") ~ "100+",
                           TRUE ~ age)) %>% 
    select(tableID, name, sex, age, raceEth)
  
  
}

# Call function createCensusLink() to create relationship data frames which links a table ID to its corresponding strata (sex by age by race/ethnicity) --------------------------------------------------------
census2000_link <- createCensusLink(censusVars2000_race)
census2010_link <- createCensusLink(censusVars2010_race)
census2020_link <- createCensusLink(censusVars2020_race) 

# Save ============================================================
wb <- createWorkbook()
addWorksheet(wb, sheetName = "2000 ARS")
addWorksheet(wb, sheetName = "2010 ARS")
addWorksheet(wb, sheetName = "2020 ARS")

writeData(wb, sheet = 1, x = census2000_link, colNames = TRUE, rowNames = FALSE)
writeData(wb, sheet = 2, x = census2010_link, colNames = TRUE, rowNames = FALSE)
writeData(wb, sheet = 3, x = census2020_link, colNames = TRUE, rowNames = FALSE)

saveWorkbook(wb, "Standards/decennialLink.xlsx", overwrite = FALSE) ## save to working directory
