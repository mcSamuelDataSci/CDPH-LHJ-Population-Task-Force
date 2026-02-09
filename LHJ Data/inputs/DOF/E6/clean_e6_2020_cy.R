library(readr)
library(readxl)
library(dplyr)



df <- read_excel("inputs/DOF/E6/Raw/E-6_Report_July_2020-2025_Feb26_w.xlsx", sheet = 2, skip = 3) %>% 
  select(County = 1, Year = 2, population = 3) %>% 
  filter(!is.na(Year)) %>% 
  mutate(County = if_else(!is.na(County) & !is.na(lead(County)),
                          str_trim(paste(County, lead(County))), 
                          County
                          ), 
         County = ifelse(Year == "Apr-Jun 2020", NA_character_, County)
         ) %>% 
  fill(County, .direction = "down") %>% 
  filter(Year != "Census 2020") %>% 
  mutate(Year = ifelse(Year == "Apr-Jun 2020", "2020", Year), 
         Year = as.integer(Year))

# Validation
table(df$County, useNA = "ifany")
df %>% 
  group_by(County) %>% 
  mutate(avg = median(population)) %>% 
  ungroup() %>% 
  pivot_wider(names_from = Year, values_from = population) %>% 
  mutate(across(.cols = contains("20"), ~round(abs((.x-avg)/avg), 3))) %>% 
  View()

write_csv(df, "inputs/DOF/E6/temp.csv")
