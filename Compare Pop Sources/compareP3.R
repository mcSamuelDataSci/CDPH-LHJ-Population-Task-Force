server <- TRUE
if (server) source("/mnt/projects/FusionData/0.CCB/myCCB/Standards/FusionStandards.R")

p3 <- read_csv(paste0(fusionPlace, "Population Data/P3_Complete.csv")) %>% 
  mutate(type = "P3", 
         race7 = as.character(race7))
p3_interim <- read_csv(paste0(fusionPlace, "Population Data/P3_Complete_Interim.csv")) %>% 
  mutate(type = "Interim", 
         race7 = as.character(race7))
p3_vax <- read_csv(paste0(fusionPlace, "Population Data/P3_rwgt.csv")) %>% 
  mutate(type = "Vaccine", 
         race7 = sub(" NH", "", race7),
         raceNameShort =case_when(race7 == "Hispanic" ~ "Latino", 
                                  race7 == "MR" ~ "Multi-Race", 
                                  race7 == "AIAN" ~ "AI/AN", 
                                  race7 == "NHPI" ~ "NH/PI", 
                                  TRUE ~ race7)) %>% 
  select(-race7)


processData <- function(myData, raceJoin = T) {
  
  if (raceJoin) {
    tRaceLink <- raceLink %>% 
      select(raceNameShort, race7) %>% 
      filter(!is.na(race7)) %>% 
      mutate(race7 = as.character(race7))
    
    myData <- myData %>% 
      left_join(tRaceLink, by = "race7") 
  }
  
  
  myData %>% 
    group_by(year, type, raceNameShort) %>% 
    summarise(population = sum(perwt)) %>% 
    ungroup() 
    
}

processData(p3) %>% 
  bind_rows(processData(p3_interim)) %>% 
  # bind_rows(processData(p3_vax, raceJoin = F)) %>% 
  ggplot(aes(x = year, y = population, color = type)) +
  geom_line(size = 1.5) +
  facet_wrap(facets = vars(raceNameShort), scales = "free")

# +
#   scale_y_continuous(limits = c(0, NA))


p3 %>% 
  bind_rows(p3_interim) %>% 
  bind_rows(p3_vax) %>% 
  group_by(year, type) %>% 
  summarise(population = sum(perwt)) %>% 
  ungroup() %>% 
  ggplot(aes(x = year, y = population, color = type)) +
  geom_line(size = 1.5) +
  scale_color_manual(values = c("red", "blue", "")
