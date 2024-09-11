---
editor_options: 
  markdown: 
    wrap: 72
---

Each of the files in this SOGI directory of the CDPH Population Data
Task Force GitHub is explained below:

### **AskCHISResults202408191747.xlsx**

The file is a machine readable Excel spreadsheet with results of AskCHIS
query of sexual orientation by county, pooling 2015-2022 data. To
reproduce the query:

1.  Go to <https://healthpolicy.ucla.edu/our-work/askchis>
2.  Select "Visit the CHIS dashboard"
3.  Log in to your account (querying AskCHIS requires you to create an
    account)
4.  Under "Geographic Area", select "Search all of California"
5.  Under "Topic", select "Demographic" then "Sexual Orientation and
    Gender Identity" then "Sexual Orientation (4 levels) - Self-Reported
6.  Under "Years", select the years 2015 through 2022
7.  Click on "Get Data"
8.  Under "Compare Geography", select "Compare Across Counties"

### **Sexual Orientation and Gender Identity Population Data Sources 8-2024**

This is a resource document on "Sources of Data on Sexual Orientation
and Gender Identity (SOGI)" (docx and .pdf)

### Tables

1.  **Table 1.xlsx**: Sexual Orientation for Adults by County (pooled
    2014-2022 CHIS data); Table 1 in SOGI data source document
2.  **Table 2.xlsx**: Proportion of Gay Men by County, comparing three
    statistical models to estimate the proportion of gay men in each
    county; Table 2 in SOGI data source document

### SAS Code

Location: Code/SAS/

-   **sogi.sas**: Annotated SAS 9.4 file for reading in CHIS data,
    cleaning and recoding the database, analyzing data, and producing
    tables in SOGI data source document

### R Code

Location: Code/R/

-   **1_read_data.R**: Annotated R script for reading in CHIS data and
    designating the dataset as survey data; run this file first
-   **2_analysis.R**: Annotated R script for CHIS data analysis in SOGI
    data source document; run this file second
-   Four files with R functions for creating the tables used in the SOGI
    data source document:
    -   **table.R**: Creates Table 1
    -   **logit.R**: Estimates Model 1 in Table 2
    -   **sae_randint.R**: Estimates Model 2 in Table 2
    -   **sae_randyear.R**: Estimates Model 3 in Table 2
