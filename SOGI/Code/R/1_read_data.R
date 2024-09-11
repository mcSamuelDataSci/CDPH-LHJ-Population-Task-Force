#Filepath:  D:/Dropbox/sogi


#####################################################
###                                               ###
###    ########     #         ###         ###     ###
###    #       #    #         #  #       #  #     ###
###    #       #    #         #   #     #   #     ###
###    ########     #         #    #   #    #     ###
###    #       #    #         #     # #     #     ###
###    #       #    #         #      #      #     ###
###    ########     #######   #             #     ###
###                                               ###
#####################################################

library(haven)   #import SAS files
library(dplyr)
library(data.table)
library(tidyverse)
library(lubridate)

#TO DO
#label categories for sex, sexual_orientation, trans



#### Read In Data ####
#CHIS dummy data from: 

### Set paths
#Get list of SAS data files
file_path <- "D:/Dropbox/sogi/data"
file_list <- list.files(file_path) %>% .[grep("sas7bdat", .)]


#Define path for saving data
save_path <- "D:/Dropbox/sogi"

#Create Variable Names for Weights
f <- function(i) {
  paste0("RAKEDW", i)
  }
raked <- sapply(0:80, f)


#Variables to be read in from files
varlist1 <- c("AD46","SRSEX","FIPS_CNT","BESTZIP", c(raked))               #2014-2016
varlist2 <- c("TRANSGEND2","AD46B","SRSEX","FIPS_CNT","BESTZIP", c(raked))              #2017-2021
varlist3 <- c("TRANSGEND2","AD46C","AD46C_P1", "SRSEX","FIPS_CNT","BESTZIP", c(raked))  #2022

#Define function for reading files

#Diagnosis
#fname <- file_list[9]
#x <- read_sas(paste0(file_path, "/", fname))

require(haven)
readfiles <- function(fname) {
  if (substr(fname, 12, 13) == 14 | substr(fname, 12, 13) == 16) {
    x <- read_sas(paste0(file_path, "/", fname), col_select = c(all_of(varlist1)))  
    x$year <- paste0("20",substr(fname, 12, 13))
    return(x)
  } else {
  ifelse(substr(fname, 12, 13) == 15 | (substr(fname, 12, 13) > 16 & substr(fname, 12, 13) < 21), 
    x <- read_sas(paste0(file_path, "/", fname), col_select = c(all_of(varlist2))),
    x <- read_sas(paste0(file_path, "/", fname), col_select = c(all_of(varlist3))))
    x$year <- paste0("20",substr(fname, 12, 13))
    return(x)  
  }
} 

###Read and combine files
df <- rbindlist(lapply(file_list, readfiles), fill=TRUE)
  

#Merge w/ County data
df <- read.csv(paste0(file_path, "/", "county_key.csv"), header=TRUE) %>%
  left_join(df, county, by = c("fips" = "FIPS_CNT"))


#Recode Variables
#Recoded Values
#sex: 0=Female; 1=Male
#trans:  0=Cis; 1=Trans
#sexual_orientation: 0=Straight, 1=Gay/Lesbian, 2=Bisexual, 3=Asexual/Celibate/Other"
#gay: 0=Straight; 1=Gay/Lesbian;

#Recode Data
`%notin%` <- Negate(`%in%`)
df2 <- df %>% mutate(sex = recode(SRSEX, "1" = 1, "2" = 0)) %>% 
  mutate(trans = as.factor(recode(TRANSGEND2, "1" =  0, "2" = 1, "-2" = NA_real_))) %>%
  mutate(sexual_orientation = as.factor(case_when(
    AD46 %in% 1 | AD46B %in% 1 | AD46C %in% 1 ~ 0,
    AD46 %in% 2 | AD46B %in% 2 | AD46C %in% 2 ~ 1,
    AD46 %in% 3 | AD46B %in% 3 | AD46C %in% 3 ~ 2,
    AD46 %in% 4 | AD46 %in% 5 | AD46 %in% 6 | AD46B %in% 4 | AD46B %in% 5 | 
       AD46C %in% 4 | AD46C %in% 5 | AD46C %in% 6 ~ 3,
    ((is.na(AD46) | AD46 %in% c(-2,-1)) & (is.na(AD46B) | AD46B %in% c(-2,-1)) & 
        (is.na(AD46C) | AD46C %in% c(-2,-1))) ~ NA_real_))) %>%
  mutate(gay = as.factor(case_when(
    AD46 %in% c(-2,-1) | AD46B %in% c(-2,-1) | AD46C %in% c(-2,-1) ~ NA_real_,
    sexual_orientation %in% 2 & sex %in% 1 ~ 1,
    sexual_orientation %notin% 2 | sex %notin% 1 ~ 0))) %>%
  rename("zip" = "BESTZIP")


#Create Replication Weights
years <- unique(df$year)
n <- length(years)

df_ <- df2
df_$WGT = df_$RAKEDW0/n;

start <- Sys.time()
for (j in 1:n) {
  for (k in 1:80) {
    old <- paste0("RAKEDW",k)
    ifelse(df_$year == years[j], old, 
           df_[ , paste0("FNWGT", k+((j-1)*80))] <- df_[ , old]/n)
           #df_[ , paste0("FNWGT", k+((j-1)*80))] <- df_[ , ..old]/n)  #Two dots (..) before "old" are for data.table; 
  }                                                                 #eliminate if using data.frame
}
end <- Sys.time()
end - start

#Save Data
start <- Sys.time()
write.csv(df_, paste0(save_path, "/data/df_sogi.csv"))
end <- Sys.time()
end - start

saveRDS(df_, paste0(save_path, "/data/df_sogi.RDS"))


#Remove df_
rm(df_)

#Run 2_analysis