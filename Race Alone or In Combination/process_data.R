options(scipen = 999)

# Load packages ==============================

library(dplyr)
library(ggplot2)
library(readr)
library(readxl)
library(scales)
library(stringr)
library(tidyr)

# Read data files ========================================================================

cv10 <- read_csv("data/raw/censusVintage_2010-2019.csv")
cv20 <- read_csv("data/raw/censusVintage_2020-2024.csv")

# Read linkage files ======================================================================

censusLink_raic <- read_excel("info/censusVintageLink.xlsx", sheet = "raicLink")
censusLink_age <- read_excel("info/censusVintageLink.xlsx", sheet = "ageLink")
censusLink_year10 <- read_excel("info/censusVintageLink.xlsx", sheet = "yearLink10")
censusLink_year20 <- read_excel("info/censusVintageLink.xlsx", sheet = "yearLink20")

# Process data ===========================================================================

## Function for processing data --------------------------------

# Filter on race group
# Pivot longer
# Aggregate

process_data <- function(myData, myRace) {
  
  c_link <- censusLink_raic %>% 
    filter(raceNameShort == myRace)
  
  t_dat <- myData %>% 
    select(county, year, ageGroup, all_of(c_link$census)) %>% 
    pivot_longer(-c("county", "year", "ageGroup"), names_to = "census", values_to = "population") %>% 
    left_join(c_link) %>% 
    bind_rows(mutate(., county = "CALIFORNIA"))
  
  if (myRace != "Total") {
    t_dat <- t_dat %>% 
      bind_rows(mutate(., sex = "Total"))
  }
  
  t_dat <- t_dat %>% 
    group_by(county, year, ageGroup, raceNameShort, sex, raic, hispanic) %>% 
    summarise(population = sum(population)) %>% 
    ungroup()
  
  return(t_dat)
  
}

# Get list of unique race groups
races <- unique(censusLink_raic$raceNameShort)

## Process 2020+ Data --------------------------

cv20_clean <- cv20 %>% 
  filter(YEAR %in% censusLink_year20$census) %>% 
  left_join(censusLink_year20, by = c("YEAR" = "census")) %>% 
  left_join(select(censusLink_age, census, ageStandard), by = c("AGEGRP" = "census")) %>% 
  select(county = CTYNAME, year, ageGroup = ageStandard, TOT_POP:HNAC_FEMALE)

race_pop20 <- lapply(races, function(race) {
  process_data(cv20_clean, race)
})

## Process 2010 Data --------------------------

cv10_clean <- cv10 %>% 
  filter(YEAR %in% censusLink_year10$census) %>% 
  left_join(censusLink_year10, by = c("YEAR" = "census")) %>% 
  left_join(select(censusLink_age, census, ageStandard), by = c("AGEGRP" = "census")) %>% 
  select(county = CTYNAME, year, ageGroup = ageStandard, TOT_POP:HNAC_FEMALE)

race_pop10 <- lapply(races, function(race) {
  process_data(cv10_clean, race)
})

## Combine 2010-2019 & 2020+ data ------------------

race_pop_final <- bind_rows(race_pop10) %>%
  bind_rows(race_pop20) %>% 
  mutate(county = sub(" County.*", "", county))

# Data Validation Checks ====================================

if (F) {
  
  # Check frequencies 
  table(race_pop_final$raceNameShort, race_pop_final$raic, race_pop_final$hispanic, useNA = "ifany")
  
  # Race, NH + H = Both
  check1 <- race_pop_final %>% 
    filter(!raceNameShort %in% c("Total", "Multi-Race", "Latino")) %>%  
    pivot_wider(names_from = hispanic, values_from = population) %>% 
    mutate(eq = H + NH == BOTH)
  
  all(check1$eq) # Should return TRUE
  
  # Total Population ~ 39M
  race_pop_final %>% 
    filter(raceNameShort == "Total", county == "CALIFORNIA", ageGroup == "Total") %>% 
    pivot_wider(names_from = sex, values_from = population)
  
  # sum(Race, NH) = Total Population
  check2 <- race_pop_final %>% 
    filter(raic %in% c(NA, "Alone"), hispanic %in% c(NA, "NH")) %>% 
    select(-raic, -hispanic) %>% 
    pivot_wider(names_from = raceNameShort, values_from = population) %>% 
    mutate(eq = `AI/AN` + Asian + Black + Latino + `Multi-Race` + `NH/PI` + White == Total)
  
  all(check2$eq) # Should return TRUE
  
  # Visual Checks
  
  # Race, NH
  race_pop_final %>% 
    filter(county == "CALIFORNIA", ageGroup == "Total", raic %in% c(NA, "Alone"), hispanic %in% c(NA, "NH")) %>% 
    ggplot(aes(x = year, y = population, color = sex)) +
    geom_line() +
    geom_point() +
    geom_vline(xintercept = 2020) +
    scale_y_continuous(labels = comma) +
    scale_x_continuous(minor_breaks = min(race_pop_final$year):max(race_pop_final$year), 
                       breaks = min(race_pop_final$year):max(race_pop_final$year),
                       labels = min(race_pop_final$year):max(race_pop_final$year),
                       ) +
    facet_wrap(~raceNameShort, scales = "free") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
  
  
  
  # Age Group
  race_pop_final %>% 
    filter(county == "CALIFORNIA", ageGroup != "Total", raceNameShort == "Total") %>% 
    mutate(ageGroup = factor(ageGroup, levels = c("0 - 4", "5 - 14", "15 - 24", "25 - 34", "35 - 44", 
                                                  "45 - 54", "55 - 64", "65 - 74", "75 - 84", "85+"))) %>% 
    ggplot(aes(x = year, y = population, color = sex)) +
    geom_line() +
    geom_point() +
    geom_vline(xintercept = 2020) +
    scale_y_continuous(labels = comma) +
    scale_x_continuous(minor_breaks = min(race_pop_final$year):max(race_pop_final$year), 
                       breaks = min(race_pop_final$year):max(race_pop_final$year),
                       labels = min(race_pop_final$year):max(race_pop_final$year),
    ) +
    facet_wrap(~ageGroup, scales = "free") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
  
}

# Save Data ============================================

race_pop_final2 <- race_pop_final %>% 
  mutate(county = str_to_title(county)) %>% 
  select(county_lhj = county, 
         year,
         sex,
         age_group = ageGroup, 
         race_eth = raceNameShort, 
         raic, 
         hispanic, 
         population)

write_csv(race_pop_final2, file = "data/processed/raic_population.csv")
saveRDS(race_pop_final2, file = "data/processed/raic_population.RDS")
