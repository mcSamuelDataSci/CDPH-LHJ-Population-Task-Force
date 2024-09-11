This README document explains each of the files in the SOGI directory of the CDPH Population Data Task Force GitHub

- AskCHISResults202408191747: machine readable Excel spreadsheet with results of AskCHIS query of sexual orientation by county, 
pooling 2015-2022 data. 

To reproduce the query, go to:  
https://healthpolicy.ucla.edu/our-work/askchis; 
   --> select "Visit the CHIS dashboard" 
      --> log in to your account (querying AskCHIS requires you to create an account) 
         --> under "Geographic Area", select "Search all of California"
         --> under "Topic", select "Demographic" then "Sexual Orientation and Gender Identity" then "Sexual Orientation
             (4 levels) - Self-Reported
         --> under "Years", select the years 2015 through 2022
         --> Click on "Get Data"
         --> Under "Compare Geography", select "Compare Across Counties"

- Sexual Orientation and Gender Identity Population Data Sources 8-2024.docx: resource document "Sources of Data on 
Sexual Orientation and Gender Identity (SOGI)" (as Word document)

- Sexual Orientation and Gender Identity Population Data Sources 8-2024.pdf:  resource document "Sources of Data on 
Sexual Orientation and Gender Identity (SOGI)" (as .pdf)

- Table 1.xslx:  Sexual Orientation for Adults by County (pooled 2014-2022 CHIS data); Table 1 in SOGI data source 
document

- Table 2.xslx:  Proportion of Gay Men by County, comparing three statistical models to estimate the proportion of 
gay men in each county; Table 2 in SOGI data source document

SAS Code
- sogi.sas: Annotated SAS 9.4 file for reading in CHIS data, cleaning and recoding the database, analyzing data, and 
producing tables in SOGI data source document

R Code
- 1_read_data.R:  Annotated R script for reading in CHIS data and designating the dataset as survey data; run this 
file first

- 2_analysis.R:  Annotated R script for CHIS data analysis in SOGI data source document; run this file second

- table.R:  Creates Table 1
- logit.R:  Estimates Model 1 in Table 2
- sae_randint.R:  Estimates Model 2 in Table 2
- sae_randyear:  Estimates Model 3 in Table 2

Four files with R functions for creating the tables used in the SOGI data source document; put these files in the 
working directory of the R project. 