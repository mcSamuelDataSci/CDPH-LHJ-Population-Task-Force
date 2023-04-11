library(readr)
library(readxl)
library(dplyr)

dof_dat0 <- read_csv("data_in/P3_Complete.csv") 

dof_dat1 <- dof_dat0 %>%
             filter(year %in%  2020:2022) %>%
             mutate(ageGroup = cut(agerc, seq(0, 130, 10),include.lowest = TRUE)) %>%
             group_by(fips, year, sex, race7, ageGroup) %>%
             summarize(population = sum(perwt)) %>% ungroup()


countyLink <- read_excel("data_in/countyLink.xlsx") %>% select(countyName, FIPSCounty) %>% 
                   mutate(fips= as.numeric(paste0("6",FIPSCounty))) %>% select(-FIPSCounty)

raceLink <- read_excel("data_in/raceLink.xlsx") %>% select(raceNameShort,race7) 


dof_dat2 <- full_join(dof_dat1,countyLink, by="fips") %>% left_join(raceLink,by="race7") %>%
                select(countyName, year, sex, ageGroup, raceNameShort, population)


write.csv(dof_dat2, file = "data_out/DOF CA County Population.csv", row.names = FALSE)

