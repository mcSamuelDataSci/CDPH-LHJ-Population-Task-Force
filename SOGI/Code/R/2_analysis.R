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


#install.packages("survey")
#install.packages("gtsummary")

library(dplyr)
library(data.table)
library(tidyverse)
library(survey)
library(gtsummary)
library(lme4)

file_path <- "D:/Dropbox/sogi/data"

#Source Functions
source(paste0(getwd(), "/functions/table.R"))
source(paste0(getwd(), "/functions/logit.R"))
source(paste0(getwd(), "/functions/sae_randint.R"))
source(paste0(getwd(), "/functions/sae_randyear.R"))


#Read In Data
#df <- readRDS(paste0(file_path, "/df_sogi.RDS"))
df <- readRDS(paste0(file_path, "/df_sogi.RDS")) %>% as.data.frame()

#Get raw counts
table(df$county, df$sexual_orientation)

#Create "survey" design object
`%notin%` <- Negate(`%in%`)

df_so <- df %>% select(sexual_orientation, county, gay, WGT, starts_with("FNWGT")) %>%
  filter_all(all_vars(!is.na(.))) %>% filter(county %notin% c("Alpine", "Sierra"))
  

#df_svy <- svrepdesign(data = df, 
df_svy <- svrepdesign(data = df_so,
                      weights = ~ WGT,
                      repweights = "FNWGT[1-720]",
                      type = "other", 
                      scale = 1,
                      rscales = 1, 
                      mse = TRUE)


#### Appendix B: Contingency Table with "Survey" Package ####
get_table(df_svy)


#### Appendix C: Direct Estimates with "svyglm" ####
get_logit(df_svy)


#### Appendix C: SAE with Random Intercepts ####
get_randint(df_so)


#### Appendix C:  SAE with "year" as predictor ####
get_randyear(df_so)

